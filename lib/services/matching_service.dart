import '../data/care_type_skill_map.dart';
import '../data/sri_lankan_cities.dart';

// ─────────────────────────────────────────────────────────────────────────
//  MatchingService — a weighted-sum caregiver/patient scoring algorithm used
//  in two different occasions with two different parameter sets:
//
//  - MatchProfile.onboardingPreview: shown on the patient dashboard right
//    after onboarding, before any match request exists. Uses only what
//    onboarding collected (city, preferred caregiver gender, skill/care
//    type, work nature) scored against every caregiver in the pool — no
//    eligibility filtering, since this is a passive "how would you rank"
//    preview, not a committed request.
//  - MatchProfile.advanced: the full advanced-match wizard. Adds precision
//    (exact location instead of city, detailed work schedule instead of
//    work nature) and additional criteria only the wizard collects
//    (education, experience, training, languages), on top of the same
//    onboarding-sourced gender/skill preferences. Still gated by Stage-1
//    hard eligibility filtering (isEligible) exactly as before.
//
//  Both profiles share one scoring mechanism: each caregiver is scored
//  against only the criteria in the active profile, equally weighted
//  within that profile (no survey data exists to derive relative weights
//  for this exact criterion set, and the thesis behind this feature found
//  uniform weighting performs on par with derived weights — see Chapter 4
//  §4.8.3), with weight redistribution (S1) for criteria a specific
//  caregiver has no data for.
//
//  Pure logic only: every function here takes plain `Map<String, dynamic>`
//  caregiver/patient data (the same shape Firestore hands back elsewhere in
//  this app) and a MatchContext, and returns typed results — no Firestore
//  or Flutter imports, so this is fully unit-testable without a device or
//  emulator.
// ─────────────────────────────────────────────────────────────────────────

enum MatchCriterion {
  skillMatch,
  availability, // work nature (dashboard) / work schedule (advanced)
  proximity, // city (dashboard) / exact location (advanced)
  genderMatch,
  languageMatch, // advanced only — dashboard has no language signal to use
  education, // advanced only
  experience, // advanced only
  certification, // advanced only — "training"
}

/// A named, equally-weighted subset of criteria for one matching occasion.
class MatchProfile {
  const MatchProfile(this.name, this.criteria);

  final String name;
  final Set<MatchCriterion> criteria;

  /// Dashboard preview, right after onboarding: only what onboarding
  /// collects — care type/skill, preferred gender, city, work nature —
  /// scored against every caregiver, with no eligibility gate.
  static const onboardingPreview = MatchProfile('onboarding preview', {
    MatchCriterion.skillMatch,
    MatchCriterion.genderMatch,
    MatchCriterion.proximity,
    MatchCriterion.availability,
  });

  /// The advanced-match wizard: everything the onboarding profile uses,
  /// made more precise (exact location, detailed schedule), plus
  /// education/experience/training/languages the wizard collects. Applied
  /// only to caregivers that already passed Stage-1 eligibility.
  static const advanced = MatchProfile('advanced match', {
    MatchCriterion.skillMatch,
    MatchCriterion.genderMatch,
    MatchCriterion.proximity,
    MatchCriterion.availability,
    MatchCriterion.education,
    MatchCriterion.experience,
    MatchCriterion.certification,
    MatchCriterion.languageMatch,
  });
}

class MatchWeights {
  MatchWeights._();

  /// Only credential criteria are eligible for structural-absence
  /// exclusion (Stage 3) — the rest always have a value for every
  /// caregiver.
  static const credentialCriteria = {
    MatchCriterion.experience,
    MatchCriterion.certification,
  };

  /// Years of experience above this cap score the same as exactly this
  /// many years — a declared normalisation parameter, not a derived one.
  static const int experienceCapYears = 10;
}

/// Ordinal caregiver education levels, normalised to 0..1. Not matched
/// against anything patient-specified (no such field exists anywhere in
/// this app) — it's an intrinsic caregiver-quality signal, same role as
/// experience.
const Map<String, double> _educationLevel = {
  'Primary': 0.25,
  'Secondary': 0.5,
  'Diploma': 0.75,
  'Degree or higher': 1.0,
};

/// Coverage tiers used by the availability criterion: a caregiver whose
/// declared work arrangement ranks at or above the patient's requested
/// schedule can cover it (e.g. a Live-in caregiver can cover a Part-time
/// request; a Part-time caregiver cannot reliably cover a Live-in request).
/// 'Flexible' is treated as the least demanding request (rank 1) and, on
/// the caregiver side, as full coverage of every tier — both are judgment
/// calls about what a caregiver/patient self-declaring "Flexible" means,
/// since the source screens don't define it further.
const Map<String, int> _scheduleRank = {
  'Part-time': 1,
  'Flexible': 1,
  'Full-time': 2,
  'Live-in': 3,
};

/// Per-request context: the patient's persisted profile (may be null/
/// partial) plus the current match-request's navigation-args map (schedule,
/// qualifications quiz answers, location). requestArgs values win when both
/// are present, since they reflect what the patient asked for on *this*
/// request rather than their standing profile. For the dashboard preview,
/// requestArgs is empty — every getter here then falls back to whatever
/// onboarding already saved to patientProfile.
class MatchContext {
  const MatchContext({this.patientProfile, this.requestArgs = const {}});

  final Map<String, dynamic>? patientProfile;
  final Map<String, dynamic> requestArgs;

  String get careType =>
      (requestArgs['careType'] as String?) ??
      (patientProfile?['careType'] as String?) ??
      '';

  String get requestedSchedule =>
      (requestArgs['schedule'] as String?) ??
      (patientProfile?['careLevel'] as String?) ??
      'Flexible';

  /// Only ever populated by the wizard's qualifications quiz — onboarding
  /// collects no language requirement, so this is empty for the dashboard
  /// preview (languageMatch is correspondingly excluded from that profile).
  List<String> get requiredLanguages =>
      (requestArgs['languages'] as List?)?.cast<String>() ?? const [];

  /// From the qualifications quiz's "Have you received formal caregiving
  /// training?" question — the closest available signal to "patient
  /// indicated certification is mandatory".
  bool get certificationMandatory => requestArgs['training'] == 'Yes';

  String get preferredGender =>
      (patientProfile?['preferredCaregiverGender'] as String?) ??
      'No preference';

  double? get requestLat => (requestArgs['lat'] as num?)?.toDouble();
  double? get requestLng => (requestArgs['lng'] as num?)?.toDouble();

  String get locationCityName =>
      (requestArgs['location'] as String?) ??
      (patientProfile?['city'] as String?) ??
      '';
}

/// One row of a caregiver's score breakdown — the data backing the
/// "why this match" UI. Only contains rows for criteria in the active
/// MatchProfile. [rawValue] and [contributionPoints] are null/0 when
/// [structurallyAbsent] is true: the criterion was excluded from this
/// caregiver's score, not scored as zero.
class CriterionScore {
  const CriterionScore({
    required this.criterion,
    required this.rawValue,
    required this.weight,
    required this.structurallyAbsent,
    required this.contributionPoints,
  });

  final MatchCriterion criterion;
  final double? rawValue; // normalised 0..1, null if structurally absent
  final double weight; // rescaled weight actually applied (0 if absent)
  final bool structurallyAbsent;
  final double contributionPoints; // rawValue * weight * 100
}

class MatchResult {
  const MatchResult({
    required this.caregiver,
    required this.matchPercent,
    required this.breakdown,
    required this.distanceKm,
  });

  final Map<String, dynamic> caregiver;
  final double matchPercent; // 0..100
  final List<CriterionScore> breakdown; // one entry per profile criterion
  final double? distanceKm;
}

class MatchingService {
  MatchingService._();

  static const Map<MatchCriterion, String> labels = {
    MatchCriterion.skillMatch: 'Skill match',
    MatchCriterion.availability: 'Availability',
    MatchCriterion.proximity: 'Proximity',
    MatchCriterion.genderMatch: 'Gender preference',
    MatchCriterion.languageMatch: 'Languages',
    MatchCriterion.education: 'Education',
    MatchCriterion.experience: 'Experience',
    MatchCriterion.certification: 'Training',
  };

  // ── Caregiver category (Stage 3 prerequisite) ─────────────────────────
  //
  // The schema has no explicit informal/professional field, so category is
  // derived from the same two credential-document signals used elsewhere:
  // formal training on file, or an uploaded certificate. This is a stated
  // heuristic, not collected data — flagged prominently because it has one
  // structural consequence: since "professional" is defined as "has a
  // certification signal", the certification criterion can never be both
  // "caregiver is informal" and "certification data is missing" without
  // that being the same fact twice. The hybrid rule stays meaningful for
  // experience, whose presence is genuinely independent of this signal;
  // for certification specifically it degenerates to "always absent when
  // informal, never otherwise".
  static bool isProfessional(Map<String, dynamic> caregiver) {
    return caregiver['formalTraining'] == true ||
        ((caregiver['certificateUrls'] as List?)?.isNotEmpty ?? false);
  }

  // ── Stage 1 — eligibility (hard filter, applied before scoring) ───────
  //
  // Used only by the advanced-match flow — the dashboard preview scores
  // every caregiver with no gate, since it's a passive "how would you
  // rank" view rather than a committed request.
  static bool isEligible(Map<String, dynamic> caregiver, MatchContext ctx) {
    return _languageEligible(caregiver, ctx) &&
        _genderEligible(caregiver, ctx) &&
        _certificationEligible(caregiver, ctx) &&
        _travelEligible(caregiver, ctx);
  }

  static bool _languageEligible(
      Map<String, dynamic> caregiver, MatchContext ctx) {
    if (ctx.requiredLanguages.isEmpty) return true;
    final spoken =
        (caregiver['languagesSpoken'] as List?)?.cast<String>() ?? const [];
    return ctx.requiredLanguages.any(spoken.contains);
  }

  static bool _genderEligible(
      Map<String, dynamic> caregiver, MatchContext ctx) {
    final pref = ctx.preferredGender;
    if (pref.isEmpty || pref == 'No preference') return true;
    return caregiver['gender'] == pref;
  }

  static bool _certificationEligible(
      Map<String, dynamic> caregiver, MatchContext ctx) {
    if (!ctx.certificationMandatory) return true;
    return isProfessional(caregiver);
  }

  /// Fail-open when distance can't be resolved (unrecognised city name, no
  /// coordinates on the request) — mirrors the existing tolerance in
  /// advanced_match_results_screen.dart's original distance helper, which
  /// already treats an unresolved city as "don't know, don't exclude"
  /// rather than as a hard failure.
  static bool _travelEligible(
      Map<String, dynamic> caregiver, MatchContext ctx) {
    if (_sameDistrict(caregiver, ctx)) return true;
    final distanceKm = _distanceKm(caregiver, ctx);
    if (distanceKm == null) return true;
    final willingKm = (caregiver['serviceRadiusKm'] as int?) ?? 0;
    return distanceKm <= willingKm;
  }

  // ── Shared geo helpers ─────────────────────────────────────────────────

  static bool _sameDistrict(Map<String, dynamic> caregiver, MatchContext ctx) {
    final patientCity =
        cityCoords(ctx.locationCityName.split(',').first.trim());
    final caregiverCity = cityCoords((caregiver['city'] as String?) ?? '');
    return patientCity != null &&
        caregiverCity != null &&
        patientCity['district'] == caregiverCity['district'];
  }

  static double? _distanceKm(Map<String, dynamic> caregiver, MatchContext ctx) {
    final caregiverCity = cityCoords((caregiver['city'] as String?) ?? '');
    if (caregiverCity == null) return null;
    final caregiverLat = double.parse(caregiverCity['lat']!);
    final caregiverLng = double.parse(caregiverCity['lng']!);

    if (ctx.requestLat != null && ctx.requestLng != null) {
      return haversineKm(
          ctx.requestLat!, ctx.requestLng!, caregiverLat, caregiverLng);
    }
    final patientCity =
        cityCoords(ctx.locationCityName.split(',').first.trim());
    if (patientCity == null) return null;
    return haversineKm(
      double.parse(patientCity['lat']!),
      double.parse(patientCity['lng']!),
      caregiverLat,
      caregiverLng,
    );
  }

  // ── Criterion scorers, each normalised to 0..1 ─────────────────────────

  static double _skillMatch(Map<String, dynamic> caregiver, MatchContext ctx) {
    final required = careTypeSkillMap[ctx.careType] ?? const <String>{};
    if (required.isEmpty) return 1.0; // no specific requirement to fail
    final has =
        (caregiver['skills'] as List?)?.cast<String>().toSet() ?? const {};
    return required.intersection(has).length / required.length;
  }

  static double _availability(
      Map<String, dynamic> caregiver, MatchContext ctx) {
    final requestedRank = _scheduleRank[ctx.requestedSchedule] ?? 1;
    final caregiverTypes =
        (caregiver['careTypes'] as List?)?.cast<String>() ?? const [];
    if (caregiverTypes.contains('Flexible')) return 1.0;
    var caregiverMaxRank = 0;
    for (final t in caregiverTypes) {
      final r = _scheduleRank[t] ?? 0;
      if (r > caregiverMaxRank) caregiverMaxRank = r;
    }
    if (caregiverMaxRank == 0) return 0.0;
    return (caregiverMaxRank / requestedRank).clamp(0.0, 1.0);
  }

  static double _proximity(Map<String, dynamic> caregiver, MatchContext ctx) {
    if (_sameDistrict(caregiver, ctx)) return 1.0;
    final distanceKm = _distanceKm(caregiver, ctx);
    final willingKm = (caregiver['serviceRadiusKm'] as int?) ?? 0;
    if (distanceKm == null || willingKm <= 0) return 0.5; // neutral fallback
    return (1 - distanceKm / willingKm).clamp(0.0, 1.0);
  }

  static double _genderMatch(Map<String, dynamic> caregiver, MatchContext ctx) {
    final pref = ctx.preferredGender;
    if (pref.isEmpty || pref == 'No preference') return 1.0;
    return caregiver['gender'] == pref ? 1.0 : 0.0;
  }

  static double _languageMatch(
      Map<String, dynamic> caregiver, MatchContext ctx) {
    final required = ctx.requiredLanguages;
    if (required.isEmpty) return 1.0; // no requirement stated to fail
    final spoken =
        (caregiver['languagesSpoken'] as List?)?.cast<String>().toSet() ??
            const <String>{};
    final matched = required.where(spoken.contains).length;
    return matched / required.length;
  }

  static double _education(Map<String, dynamic> caregiver) {
    final level = caregiver['educationalQualification'] as String?;
    return _educationLevel[level] ?? 0.0;
  }

  static double _experience(Map<String, dynamic> caregiver) {
    final years = (caregiver['yearsExperience'] as num?)?.toDouble() ?? 0;
    return (years / MatchWeights.experienceCapYears).clamp(0.0, 1.0);
  }

  static double _certification(Map<String, dynamic> caregiver) {
    return isProfessional(caregiver) ? 1.0 : 0.0;
  }

  // ── Stage 3 — structural absence detection (hybrid rule) ──────────────
  //
  // An attribute is flagged only when the caregiver is informal (not
  // professional, see isProfessional above) AND the data is actually
  // missing from the record — category membership alone is not enough,
  // since some informal caregivers do have experience/certification on
  // file. Only applies to criteria in MatchWeights.credentialCriteria.
  static Set<MatchCriterion> structurallyAbsentCriteria(
    Map<String, dynamic> caregiver,
  ) {
    if (isProfessional(caregiver)) return const {};

    final absent = <MatchCriterion>{};
    if (caregiver['yearsExperience'] == null) {
      absent.add(MatchCriterion.experience);
    }
    // isProfessional's own definition is "has a certification signal", so
    // "informal and certification missing" is always true together here —
    // see the isProfessional doc comment above.
    absent.add(MatchCriterion.certification);
    return absent;
  }

  // ── Scoring (S1: weight redistribution, within one MatchProfile) ──────
  //
  // Only criteria in [profile] are scored. Each caregiver starts from an
  // equal share of the profile's criteria; the share of any criterion
  // flagged structurally absent for THAT caregiver is dropped and the rest
  // rescaled — computed as weightedRawSum / weightSum, algebraically
  // identical to rescaling remaining weights to sum to 1 first. Nothing is
  // imputed; an absent criterion contributes neither a value nor a weight.
  static MatchResult score({
    required Map<String, dynamic> caregiver,
    required MatchContext context,
    required MatchProfile profile,
  }) {
    final absent = structurallyAbsentCriteria(caregiver)
        .intersection(profile.criteria);
    final baseWeight = 1.0 / profile.criteria.length;

    double raw(MatchCriterion c) => switch (c) {
          MatchCriterion.skillMatch => _skillMatch(caregiver, context),
          MatchCriterion.availability => _availability(caregiver, context),
          MatchCriterion.proximity => _proximity(caregiver, context),
          MatchCriterion.genderMatch => _genderMatch(caregiver, context),
          MatchCriterion.languageMatch => _languageMatch(caregiver, context),
          MatchCriterion.education => _education(caregiver),
          MatchCriterion.experience => _experience(caregiver),
          MatchCriterion.certification => _certification(caregiver),
        };

    double weightSum = 0;
    double weightedRawSum = 0;
    for (final c in profile.criteria) {
      if (absent.contains(c)) continue;
      weightSum += baseWeight;
      weightedRawSum += baseWeight * raw(c);
    }

    final breakdown = <CriterionScore>[
      for (final c in profile.criteria)
        if (absent.contains(c))
          CriterionScore(
            criterion: c,
            rawValue: null,
            weight: 0,
            structurallyAbsent: true,
            contributionPoints: 0,
          )
        else
          CriterionScore(
            criterion: c,
            rawValue: raw(c),
            weight: weightSum == 0 ? 0 : baseWeight / weightSum,
            structurallyAbsent: false,
            contributionPoints:
                weightSum == 0 ? 0 : (baseWeight / weightSum) * raw(c) * 100,
          ),
    ];

    final matchPercent =
        weightSum == 0 ? 0.0 : ((weightedRawSum / weightSum) * 100).clamp(0.0, 100.0);

    return MatchResult(
      caregiver: caregiver,
      matchPercent: matchPercent,
      breakdown: breakdown,
      distanceKm: _distanceKm(caregiver, context),
    );
  }

  // ── Full pipeline ───────────────────────────────────────────────────────

  /// Scores every caregiver in [caregivers] against [profile] and returns
  /// them sorted by descending match percentage. Does NOT apply Stage-1
  /// eligibility filtering — callers that need it (the advanced-match flow)
  /// should filter with [isEligible] first; the dashboard preview
  /// deliberately passes every caregiver through unfiltered.
  static List<MatchResult> rankCaregivers({
    required List<Map<String, dynamic>> caregivers,
    required MatchContext context,
    required MatchProfile profile,
  }) {
    final scored = caregivers
        .map((c) => score(caregiver: c, context: context, profile: profile))
        .toList();
    scored.sort((a, b) => b.matchPercent.compareTo(a.matchPercent));
    return scored;
  }
}
