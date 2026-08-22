import '../data/care_type_skill_map.dart';
import '../data/sri_lankan_cities.dart';

// ─────────────────────────────────────────────────────────────────────────
//  MatchingService — the 7-criterion weighted-sum caregiver/patient scoring
//  algorithm (knowledge-based eligibility filtering + content-based
//  matching + weight-redistribution scoring, "S1 + W2" in the research
//  behind this feature).
//
//  Pure logic only: every function here takes plain `Map<String, dynamic>`
//  caregiver/patient data (the same shape Firestore hands back elsewhere in
//  this app) and a MatchContext, and returns typed results — no Firestore
//  or Flutter imports, so this is fully unit-testable without a device or
//  emulator. Callers (e.g. advanced_match_results_screen.dart) own fetching
//  the caregiver list, the patient profile, and per-caregiver review
//  ratings, and pass the results in.
// ─────────────────────────────────────────────────────────────────────────

enum MatchCriterion {
  // Stage 2 — patient-conditional (recomputed per request, never absent)
  skillMatch,
  availability,
  proximity,
  // Stage 4 — credential (caregiver-intrinsic, can be structurally absent)
  feedback,
  references,
  experience,
  certification,
}

/// Fixed weight vector, empirically derived from a stakeholder-importance
/// survey. These are declared constants, not computed at runtime — do not
/// "rebalance" them without re-deriving the underlying survey shares.
class MatchWeights {
  MatchWeights._();

  static const Map<MatchCriterion, double> base = {
    MatchCriterion.skillMatch: 0.1667,
    MatchCriterion.availability: 0.1667,
    MatchCriterion.proximity: 0.1667,
    MatchCriterion.feedback: 0.1685,
    MatchCriterion.references: 0.1629,
    MatchCriterion.experience: 0.1461,
    MatchCriterion.certification: 0.0225,
  };

  /// Only credential criteria are eligible for structural-absence exclusion
  /// (Stage 3) — the three patient-conditional criteria always have a value
  /// for every eligible caregiver.
  static const credentialCriteria = {
    MatchCriterion.feedback,
    MatchCriterion.references,
    MatchCriterion.experience,
    MatchCriterion.certification,
  };

  /// Years of experience above this cap score the same as exactly this many
  /// years — a declared normalisation parameter, not a derived one.
  static const int experienceCapYears = 10;
}

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
/// request rather than their standing profile.
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

  List<String> get requiredLanguages =>
      (requestArgs['languages'] as List?)?.cast<String>() ?? const [];

  /// From the qualifications quiz's "Have you received formal caregiving
  /// training?" question — the closest available signal to the thesis's
  /// "patient indicated certification is mandatory" eligibility rule.
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
/// "why this match" UI. [rawValue] and [contributionPoints] are null/0 when
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
  final List<CriterionScore> breakdown; // always 7 entries
  final double? distanceKm;
}

class MatchingService {
  MatchingService._();

  static const Map<MatchCriterion, String> labels = {
    MatchCriterion.skillMatch: 'Skill match',
    MatchCriterion.availability: 'Availability',
    MatchCriterion.proximity: 'Proximity',
    MatchCriterion.feedback: 'Feedback',
    MatchCriterion.references: 'References',
    MatchCriterion.experience: 'Experience',
    MatchCriterion.certification: 'Certification',
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
  // that being the same fact twice. The hybrid rule (§3.2.3 of the source
  // research) stays meaningful for experience/references/feedback, whose
  // presence is genuinely independent of this signal; for certification
  // specifically it degenerates to "always absent when informal, never
  // otherwise". An explicit self-declared category field, independent of
  // formalTraining/certificateUrls, would remove this degeneracy if it
  // becomes a problem in practice.
  static bool isProfessional(Map<String, dynamic> caregiver) {
    return caregiver['formalTraining'] == true ||
        ((caregiver['certificateUrls'] as List?)?.isNotEmpty ?? false);
  }

  // ── Stage 1 — eligibility (hard filter, applied before scoring) ───────

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

  // ── Stage 2 — patient-conditional criteria (normalised 0..1) ──────────

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

  // ── Stage 3 — structural absence detection (hybrid rule) ──────────────
  //
  // An attribute is flagged only when the caregiver is informal (not
  // professional, see isProfessional above) AND the data is actually
  // missing from the record — category membership alone is not enough,
  // since some informal caregivers do have references/feedback/experience
  // on file.
  static Set<MatchCriterion> structurallyAbsentCriteria(
    Map<String, dynamic> caregiver, {
    required int reviewCount,
  }) {
    if (isProfessional(caregiver)) return const {};

    final absent = <MatchCriterion>{};
    if (caregiver['yearsExperience'] == null) {
      absent.add(MatchCriterion.experience);
    }
    final referencePhone = (caregiver['referencePhone'] as String?)?.trim();
    if (referencePhone == null || referencePhone.isEmpty) {
      absent.add(MatchCriterion.references);
    }
    if (reviewCount == 0) {
      absent.add(MatchCriterion.feedback);
    }
    // isProfessional's own definition is "has a certification signal", so
    // "informal and certification missing" is always true together here —
    // see the isProfessional doc comment above.
    absent.add(MatchCriterion.certification);
    return absent;
  }

  // ── Stage 4 — scoring (S1: weight redistribution) ──────────────────────
  //
  // For each caregiver individually: drop the base weight of any criterion
  // flagged structurally absent for THAT caregiver, then compute the
  // weighted sum over the remaining criteria using
  // weightedRawSum / weightSum — algebraically identical to rescaling the
  // remaining weights to sum to 1 first. Nothing is imputed; an absent
  // criterion contributes neither a value nor a weight.
  static MatchResult score({
    required Map<String, dynamic> caregiver,
    required MatchContext context,
    required double avgRating,
    required int reviewCount,
  }) {
    final absent =
        structurallyAbsentCriteria(caregiver, reviewCount: reviewCount);

    final referencePhone = (caregiver['referencePhone'] as String?)?.trim();
    final normalized = <MatchCriterion, double>{
      MatchCriterion.skillMatch: _skillMatch(caregiver, context),
      MatchCriterion.availability: _availability(caregiver, context),
      MatchCriterion.proximity: _proximity(caregiver, context),
      MatchCriterion.feedback:
          reviewCount > 0 ? (avgRating / 5.0).clamp(0.0, 1.0) : 0.0,
      MatchCriterion.references:
          (referencePhone != null && referencePhone.isNotEmpty) ? 1.0 : 0.0,
      MatchCriterion.experience: (((caregiver['yearsExperience'] as num?)
                      ?.toDouble() ??
                  0) /
              MatchWeights.experienceCapYears)
          .clamp(0.0, 1.0),
      MatchCriterion.certification: isProfessional(caregiver) ? 1.0 : 0.0,
    };

    double weightSum = 0;
    double weightedRawSum = 0;
    for (final c in MatchCriterion.values) {
      if (absent.contains(c)) continue;
      final w = MatchWeights.base[c]!;
      weightSum += w;
      weightedRawSum += w * normalized[c]!;
    }

    final breakdown = <CriterionScore>[
      for (final c in MatchCriterion.values)
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
            rawValue: normalized[c],
            weight: weightSum == 0 ? 0 : MatchWeights.base[c]! / weightSum,
            structurallyAbsent: false,
            contributionPoints: weightSum == 0
                ? 0
                : (MatchWeights.base[c]! / weightSum) * normalized[c]! * 100,
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

  /// Filters [caregivers] to those passing Stage 1, scores each with Stage
  /// 2–4, and returns them sorted by descending match percentage.
  /// [ratings] should hold each eligible caregiver's uid mapped to their
  /// (avg, count) from ReviewService.fetchRatingsFor — fetched by the
  /// caller so this function stays synchronous and Firestore-free.
  static List<MatchResult> rankCaregivers({
    required List<Map<String, dynamic>> caregivers,
    required MatchContext context,
    required Map<String, ({double avg, int count})> ratings,
  }) {
    final eligible = caregivers.where((c) => isEligible(c, context)).toList();
    final scored = eligible.map((c) {
      final uid = c['uid'] as String? ?? '';
      final r = ratings[uid];
      return score(
        caregiver: c,
        context: context,
        avgRating: r?.avg ?? 0,
        reviewCount: r?.count ?? 0,
      );
    }).toList();
    scored.sort((a, b) => b.matchPercent.compareTo(a.matchPercent));
    return scored;
  }
}
