import '../data/care_type_skill_map.dart';
import '../data/sri_lankan_cities.dart';

// ─────────────────────────────────────────────────────────────────────────
//  MatchingService — implements the thesis matching algorithm exactly:
//    Stage 1: hard/conditional/mixed eligibility filtering
//    Stage 2: seven ranking criteria, each normalised to 0..1, weighted by
//             the W2 stakeholder-derived vector
//    Stage 3: structural-absence handling (S1 weight redistribution) for
//             References and Certification, the two criteria a caregiver
//             may genuinely have no data for
//    Stage 4: weighted sum → match percentage
//
//  One unified model, used identically for the dashboard "top match"
//  preview and the advanced-match wizard — a criterion whose patient-side
//  input hasn't been stated yet (e.g. no language requirement given) just
//  contributes no penalty rather than needing a separate reduced profile.
//
//  Gender and Language are filters only (Stage 1) — they carry no ranking
//  weight in the source W2 vector, unlike the app's previous algorithm
//  which also scored them.
//
//  Pure logic only: every function here takes plain `Map<String, dynamic>`
//  caregiver/patient data (the same shape Firestore hands back elsewhere in
//  this app) and a MatchContext, and returns typed results — no Firestore
//  or Flutter imports. Criteria that need data this service can't fetch
//  itself (a caregiver's Bayesian-adjusted rating, whether they're
//  currently on an active booking) must be pre-computed by the caller and
//  stamped onto each caregiver map before calling in — see `adjustedRating`
//  and `currentlyBusy` below.
// ─────────────────────────────────────────────────────────────────────────

enum MatchCriterion {
  skillMatch,
  availability,
  proximity,
  feedback,
  references,
  experience,
  certification,
}

/// W2 — the stakeholder-derived weighting configuration. Skill match,
/// availability and proximity are patient-conditional eligibility inputs
/// with no survey "importance" item, so they split the unrated share
/// (λ=0.50) evenly. The other four are weighted by their real share of
/// survey respondents (out of the four credential criteria the survey
/// asked about) — see the algorithm write-up for the derivation.
class MatchWeights {
  MatchWeights._();

  static const double skillMatch = 0.1667;
  static const double availability = 0.1667;
  static const double proximity = 0.1667;
  static const double feedback = 0.1685;
  static const double references = 0.1629;
  static const double experience = 0.1461;
  static const double certification = 0.0225;

  static const Map<MatchCriterion, double> raw = {
    MatchCriterion.skillMatch: skillMatch,
    MatchCriterion.availability: availability,
    MatchCriterion.proximity: proximity,
    MatchCriterion.feedback: feedback,
    MatchCriterion.references: references,
    MatchCriterion.experience: experience,
    MatchCriterion.certification: certification,
  };

  /// The two criteria a caregiver can genuinely have no data for —
  /// References (an optional attachment) and Certification (only
  /// meaningful for a caregiver with a formal-training/certificate signal
  /// on file). Everything else always has a value.
  static const structurallyAbsentEligible = {
    MatchCriterion.references,
    MatchCriterion.certification,
    MatchCriterion.experience,
  };

  /// System-wide hard distance cap (km) — administrator-set, hardcoded
  /// rather than a live setting since there's no admin-settings screen for
  /// it yet.
  static const double systemDistanceCapKm = 30;
}

/// Caregiver-declared years of experience, bucketed into the same 1–4
/// ordinal levels the (now-removed) patient qualifications quiz used to
/// offer as options, so the boundaries stay consistent with what this app
/// has already asked users to reason about.
int experienceLevel(num years) {
  if (years < 1) return 1;
  if (years <= 3) return 2;
  if (years <= 6) return 3;
  return 4;
}

/// Coverage tiers used only to resolve historical `careType` strings that
/// might still be Flexible/etc. Exact-equality is the real matching rule
/// now (see _scheduleEligible) — this only backs the schedule label set.
const _scheduleValues = {'Part-time', 'Full-time', 'Live-in', 'Flexible'};

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
  /// preview.
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

  /// The patient's own optional tighter distance limit, collected at
  /// onboarding (`patientProfiles/{uid}.maxDistanceKm`). Null means "no
  /// limit given" — only the system 30km cap applies.
  double? get maxDistanceKm =>
      (requestArgs['maxDistanceKm'] as num?)?.toDouble() ??
      (patientProfile?['maxDistanceKm'] as num?)?.toDouble();

  /// True only for a request explicitly flagged emergency/urgent — gates
  /// the "caregiver must not currently be on another booking" filter.
  bool get isEmergency => requestArgs['isEmergency'] == true;
}

/// One row of a caregiver's score breakdown — the data backing the
/// "why this match" UI. [rawValue] and [contributionPoints] are null/0
/// when [structurallyAbsent] is true: the criterion was excluded from this
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
  final List<CriterionScore> breakdown; // one entry per criterion
  final double? distanceKm;
}

class MatchingService {
  MatchingService._();

  static const Map<MatchCriterion, String> labels = {
    MatchCriterion.skillMatch: 'Skill match',
    MatchCriterion.availability: 'Availability',
    MatchCriterion.proximity: 'Proximity',
    MatchCriterion.feedback: 'Feedback / ratings',
    MatchCriterion.references: 'References',
    MatchCriterion.experience: 'Experience',
    MatchCriterion.certification: 'Certification / training',
  };

  // ── Caregiver category (Stage 3 prerequisite) ─────────────────────────
  //
  // The schema has no explicit informal/professional field, so category is
  // derived from the same two credential-document signals used elsewhere:
  // formal training on file, or an uploaded certificate.
  static bool isProfessional(Map<String, dynamic> caregiver) {
    return caregiver['formalTraining'] == true ||
        ((caregiver['certificateUrls'] as List?)?.isNotEmpty ?? false);
  }

  static bool hasReference(Map<String, dynamic> caregiver) {
    final url = (caregiver['referenceUrl'] as String?)?.trim();
    return url != null && url.isNotEmpty;
  }

  // ── Stage 1 — eligibility (hard/conditional/mixed filters) ────────────
  //
  // Applied to every caregiver, for both the dashboard preview and the
  // advanced-match wizard — a caregiver who genuinely can't take the job
  // (wrong language, wrong schedule, too far, no matching skill at all)
  // shouldn't appear as a "top match" either.
  static bool isEligible(Map<String, dynamic> caregiver, MatchContext ctx) {
    return _languageEligible(caregiver, ctx) &&
        _skillEligible(caregiver, ctx) &&
        _scheduleEligible(caregiver, ctx) &&
        _genderEligible(caregiver, ctx) &&
        _certificationEligible(caregiver, ctx) &&
        _travelEligible(caregiver, ctx) &&
        _emergencyEligible(caregiver, ctx);
  }

  // Language — HARD FILTER. No shared language makes care delivery
  // impossible; skipped only when the request states no requirement.
  static bool _languageEligible(
      Map<String, dynamic> caregiver, MatchContext ctx) {
    if (ctx.requiredLanguages.isEmpty) return true;
    final spoken =
        (caregiver['languagesSpoken'] as List?)?.cast<String>() ?? const [];
    return ctx.requiredLanguages.any(spoken.contains);
  }

  // Care type / skills — HARD FILTER. A caregiver with zero overlap with
  // the skills the requested care type needs cannot deliver it at all;
  // partial overlap still passes (and is what the skillMatch ranking
  // criterion then scores).
  static bool _skillEligible(
      Map<String, dynamic> caregiver, MatchContext ctx) {
    final required = careTypeSkillMap[ctx.careType] ?? const <String>{};
    if (required.isEmpty) return true; // no specific requirement to fail
    final has =
        (caregiver['skills'] as List?)?.cast<String>().toSet() ?? const {};
    return required.intersection(has).isNotEmpty;
  }

  // Work schedule — HARD FILTER. Schedules must be exactly equal; Flexible
  // on either side matches anything. A part-time caregiver cannot cover a
  // full-time/live-in requirement, and vice versa.
  static bool _scheduleEligible(
      Map<String, dynamic> caregiver, MatchContext ctx) {
    final patientSchedule = ctx.requestedSchedule;
    final caregiverTypes =
        (caregiver['careTypes'] as List?)?.cast<String>() ?? const [];
    if (caregiverTypes.isEmpty) return false;
    return caregiverTypes.any((cg) =>
        cg == patientSchedule || cg == 'Flexible' || patientSchedule == 'Flexible');
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

  /// Distance — MIXED: the 30km system cap always applies; the patient's
  /// own tighter limit (if given) applies on top of it. Fail-open when
  /// distance can't be resolved at all (unrecognised city, no coordinates
  /// anywhere) rather than excluding on missing data.
  static bool _travelEligible(
      Map<String, dynamic> caregiver, MatchContext ctx) {
    final distanceKm = _distanceKm(caregiver, ctx);
    if (distanceKm == null) return true;
    if (distanceKm > MatchWeights.systemDistanceCapKm) return false;
    if (ctx.maxDistanceKm != null && distanceKm > ctx.maxDistanceKm!) {
      return false;
    }
    return true;
  }

  /// Emergency requests only: a caregiver already on an active booking
  /// right now can't also respond to an urgent one. `currentlyBusy` is
  /// pre-computed by the caller (this service has no Firestore access) —
  /// missing/absent is treated as "not busy" so this never wrongly
  /// excludes a caregiver the caller didn't check.
  static bool _emergencyEligible(
      Map<String, dynamic> caregiver, MatchContext ctx) {
    if (!ctx.isEmergency) return true;
    return caregiver['currentlyBusy'] != true;
  }

  // ── Shared geo helpers ─────────────────────────────────────────────────

  static double? _distanceKm(Map<String, dynamic> caregiver, MatchContext ctx) {
    // Prefer the caregiver's own exact coordinates (set via the onboarding
    // map picker) over the coarser city-name lookup — falls back for
    // caregivers who onboarded before that field existed.
    final exactLat = (caregiver['locationLat'] as num?)?.toDouble();
    final exactLng = (caregiver['locationLng'] as num?)?.toDouble();
    double caregiverLat, caregiverLng;
    if (exactLat != null && exactLng != null) {
      caregiverLat = exactLat;
      caregiverLng = exactLng;
    } else {
      final caregiverCity = cityCoords((caregiver['city'] as String?) ?? '');
      if (caregiverCity == null) return null;
      caregiverLat = double.parse(caregiverCity['lat']!);
      caregiverLng = double.parse(caregiverCity['lng']!);
    }

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

  /// 1.00 when the caregiver's declared schedule literally equals what the
  /// patient asked for (including both being Flexible) — a genuine
  /// preference match. 0.00 when the pair only passed the Stage-1 filter
  /// because one side is Flexible acting as a wildcard, not because their
  /// actual preferences line up.
  static double _availability(
      Map<String, dynamic> caregiver, MatchContext ctx) {
    final patientSchedule = ctx.requestedSchedule;
    final caregiverTypes =
        (caregiver['careTypes'] as List?)?.cast<String>() ?? const [];
    return caregiverTypes.contains(patientSchedule) ? 1.0 : 0.0;
  }

  static double _proximity(Map<String, dynamic> caregiver, MatchContext ctx) {
    final distanceKm = _distanceKm(caregiver, ctx);
    if (distanceKm == null) return 0.5; // neutral fallback, can't resolve
    return (1 - distanceKm / MatchWeights.systemDistanceCapKm).clamp(0.0, 1.0);
  }

  /// Feedback/ratings — always uses the Bayesian-adjusted rating (see
  /// ReviewService.adjustedRating), pre-computed by the caller and stamped
  /// onto the caregiver map as `adjustedRating`. That formula already
  /// resolves a brand-new caregiver to exactly the platform average, so no
  /// separate cold-start override is needed here.
  static double _feedback(Map<String, dynamic> caregiver) {
    final adjusted = (caregiver['adjustedRating'] as num?)?.toDouble();
    if (adjusted == null) return 0.5; // caller didn't stamp one — neutral
    return (adjusted / 5.0).clamp(0.0, 1.0);
  }

  static double _experience(Map<String, dynamic> caregiver) {
    final years = (caregiver['yearsExperience'] as num?);
    if (years == null) return 0.0; // structurally absent handles exclusion
    return experienceLevel(years) / 4.0;
  }

  static double _certification(Map<String, dynamic> caregiver) {
    return isProfessional(caregiver) ? 1.0 : 0.0;
  }

  static double _references(Map<String, dynamic> caregiver) {
    return hasReference(caregiver) ? 1.0 : 0.0;
  }

  // ── Stage 3 — structural absence detection (S1) ────────────────────────
  //
  // References: absent whenever no reference document is attached — it's
  // explicitly optional for every caregiver, formal or informal.
  // Certification: absent only for an informal caregiver with no
  // certification signal on file (a formal caregiver always has one, by
  // definition of isProfessional).
  // Experience: absent only if the field is genuinely missing (onboarding
  // always asks, so this mainly guards old/incomplete records).
  static Set<MatchCriterion> structurallyAbsentCriteria(
    Map<String, dynamic> caregiver,
  ) {
    final absent = <MatchCriterion>{};
    if (!hasReference(caregiver)) absent.add(MatchCriterion.references);
    if (!isProfessional(caregiver)) absent.add(MatchCriterion.certification);
    if (caregiver['yearsExperience'] == null) {
      absent.add(MatchCriterion.experience);
    }
    return absent;
  }

  // ── Scoring (S1: weight redistribution) ────────────────────────────────
  //
  // Every criterion in MatchWeights.raw is scored for every caregiver
  // except the ones flagged structurally absent for that specific
  // caregiver — their raw W2 weight is removed and every remaining
  // criterion's weight is rescaled so the total still sums to 1. Nothing
  // is imputed; an absent criterion contributes neither a value nor a
  // weight.
  static MatchResult score({
    required Map<String, dynamic> caregiver,
    required MatchContext context,
  }) {
    final absent = structurallyAbsentCriteria(caregiver)
        .intersection(MatchWeights.structurallyAbsentEligible);

    double raw(MatchCriterion c) => switch (c) {
          MatchCriterion.skillMatch => _skillMatch(caregiver, context),
          MatchCriterion.availability => _availability(caregiver, context),
          MatchCriterion.proximity => _proximity(caregiver, context),
          MatchCriterion.feedback => _feedback(caregiver),
          MatchCriterion.references => _references(caregiver),
          MatchCriterion.experience => _experience(caregiver),
          MatchCriterion.certification => _certification(caregiver),
        };

    double weightSum = 0;
    double weightedRawSum = 0;
    for (final entry in MatchWeights.raw.entries) {
      if (absent.contains(entry.key)) continue;
      weightSum += entry.value;
      weightedRawSum += entry.value * raw(entry.key);
    }

    final breakdown = <CriterionScore>[
      for (final entry in MatchWeights.raw.entries)
        if (absent.contains(entry.key))
          CriterionScore(
            criterion: entry.key,
            rawValue: null,
            weight: 0,
            structurallyAbsent: true,
            contributionPoints: 0,
          )
        else
          CriterionScore(
            criterion: entry.key,
            rawValue: raw(entry.key),
            weight: weightSum == 0 ? 0 : entry.value / weightSum,
            structurallyAbsent: false,
            contributionPoints: weightSum == 0
                ? 0
                : (entry.value / weightSum) * raw(entry.key) * 100,
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

  /// Scores every caregiver in [caregivers] and returns them sorted by
  /// descending match percentage. Does NOT apply Stage-1 eligibility
  /// filtering — callers should filter with [isEligible] first.
  static List<MatchResult> rankCaregivers({
    required List<Map<String, dynamic>> caregivers,
    required MatchContext context,
  }) {
    final scored = caregivers
        .map((c) => score(caregiver: c, context: context))
        .toList();
    scored.sort((a, b) => b.matchPercent.compareTo(a.matchPercent));
    return scored;
  }
}
