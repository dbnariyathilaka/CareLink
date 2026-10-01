import '../data/sri_lankan_cities.dart';

// ─────────────────────────────────────────────────────────────────────────
//  OnboardingMatchingService — the algorithm behind the "top match" preview
//  shown right after onboarding, before any specific booking request
//  exists. Implements the thesis's "Normal Matching" mode (Chapter 4.4).
//  Deliberately kept SEPARATE from MatchingService (the advanced-match
//  wizard's algorithm) — different filters, different ranking criteria,
//  different weighting. Do not merge these two services.
//
//  Stage 1 — hard filters (exclude only, never scored):
//    - Care category: the caregiver's own declared `careCategory` (see
//      ../data/care_categories.dart) must exactly equal the patient's
//      requested care type — same reasoning as MatchingService.
//    - Required skills: the caregiver must have EVERY skill the patient
//      asked for in their own `skills` list, not just an overlap.
//    - Gender: only filters when the patient states Male/Female; ignored
//      entirely on "No preference".
//    - Work schedule: the caregiver must offer the patient's exact
//      preferred schedule — no "Flexible" wildcard exception either way.
//
//  Distance is deliberately NOT a hard filter — the thesis's must-have-rule
//  tables never list it as one. `distanceCapKm` is kept purely as the
//  proximity formula's normalization ceiling.
//
//  Stage 2 — ranking, two criteria — proximity and rating — weighted by
//  real average importance ratings from the same 103-family survey
//  MatchingService uses (proximity and feedback happen to average almost
//  identically, so this lands close to 50/50). Rating's weight
//  redistributes entirely to proximity when the caregiver has zero
//  reviews.
//
//  Pure logic only: takes plain `Map<String, dynamic>` caregiver data (the
//  same shape Firestore hands back elsewhere) plus a small context record —
//  no Firestore access here. Callers must pre-fetch and stamp
//  `adjustedRating`/`reviewCount` onto each caregiver map first
//  (ReviewService.stampAdjustedRatings), the same way the advanced-match
//  flow already does for its own Rating criterion.
// ─────────────────────────────────────────────────────────────────────────

enum OnboardingMatchCriterion { rating, proximity }

class OnboardingMatchWeights {
  OnboardingMatchWeights._();

  static const double distanceCapKm = 30;

  static const List<OnboardingMatchCriterion> all = OnboardingMatchCriterion.values;

  /// Same source survey MatchingService.surveyAverages draws from —
  /// duplicated rather than shared, on purpose, so the two services stay
  /// decoupled (matches distanceCapKm's existing precedent below).
  static const Map<OnboardingMatchCriterion, double> surveyAverages = {
    OnboardingMatchCriterion.proximity: 3.43,
    OnboardingMatchCriterion.rating: 3.44,
  };

  /// Rating is the only criterion that can be genuinely absent — a
  /// caregiver with zero reviews has nothing to average. Proximity is
  /// always resolvable (or neutral-fallback scored, never excluded).
  static const structurallyAbsentEligible = {OnboardingMatchCriterion.rating};
}

/// Minimal patient-side inputs this algorithm needs — deliberately smaller
/// than MatchingService's MatchContext, since the onboarding preview has no
/// per-request args, only what onboarding itself collected.
class OnboardingMatchContext {
  const OnboardingMatchContext({
    required this.careType,
    required this.preferredSchedule,
    required this.preferredGender,
    required this.cityName,
    this.requiredSkills = const [],
  });

  final String careType;
  final String preferredSchedule;
  final String preferredGender; // 'No preference' | 'Male' | 'Female'
  final String cityName;
  // The specific skills the patient ticked on onboarding step 2 — see
  // ../data/care_categories.dart. A caregiver must have every one of these
  // to be eligible (see OnboardingMatchingService._requiredSkillsEligible).
  final List<String> requiredSkills;
}

class OnboardingCriterionScore {
  const OnboardingCriterionScore({
    required this.criterion,
    required this.rawValue,
    required this.weight,
    required this.structurallyAbsent,
    required this.contributionPoints,
  });

  final OnboardingMatchCriterion criterion;
  final double? rawValue; // normalised 0..1, null if structurally absent
  final double weight; // rescaled weight actually applied (0 if absent)
  final bool structurallyAbsent;
  final double contributionPoints; // rawValue * weight * 100
}

class OnboardingMatchResult {
  const OnboardingMatchResult({
    required this.caregiver,
    required this.matchPercent,
    required this.breakdown,
    required this.distanceKm,
  });

  final Map<String, dynamic> caregiver;
  final double matchPercent; // 0..100
  final List<OnboardingCriterionScore> breakdown;
  final double? distanceKm;
}

class OnboardingMatchingService {
  OnboardingMatchingService._();

  static const Map<OnboardingMatchCriterion, String> labels = {
    OnboardingMatchCriterion.rating: 'Rating',
    OnboardingMatchCriterion.proximity: 'Proximity',
  };

  // ── Stage 1 — hard filters ──────────────────────────────────────────

  static bool isEligible(Map<String, dynamic> caregiver, OnboardingMatchContext ctx) {
    return _nicVerifiedEligible(caregiver) &&
        _careCategoryEligible(caregiver, ctx) &&
        _requiredSkillsEligible(caregiver, ctx) &&
        _genderEligible(caregiver, ctx) &&
        _scheduleEligible(caregiver, ctx);
  }

  /// A caregiver whose NIC hasn't passed automatic verification
  /// (NicVerificationService) is excluded outright — never scored, never
  /// shown as a "top match". Belt-and-suspenders alongside
  /// CaregiverService.searchCaregivers' own filter, for any caller that
  /// hands this service a caregiver list from elsewhere.
  static bool _nicVerifiedEligible(Map<String, dynamic> caregiver) {
    return caregiver['nicVerified'] == true;
  }

  /// Exact match against the caregiver's own declared care category — no
  /// requirement to fail when the patient's care type is empty.
  static bool _careCategoryEligible(Map<String, dynamic> caregiver, OnboardingMatchContext ctx) {
    if (ctx.careType.isEmpty) return true;
    return caregiver['careCategory'] == ctx.careType;
  }

  /// The caregiver must have every skill the patient asked for — not just
  /// an overlap.
  static bool _requiredSkillsEligible(Map<String, dynamic> caregiver, OnboardingMatchContext ctx) {
    if (ctx.requiredSkills.isEmpty) return true;
    final has = (caregiver['skills'] as List?)?.cast<String>().toSet() ?? const {};
    return ctx.requiredSkills.every(has.contains);
  }

  static bool _genderEligible(Map<String, dynamic> caregiver, OnboardingMatchContext ctx) {
    if (ctx.preferredGender.isEmpty || ctx.preferredGender == 'No preference') return true;
    return caregiver['gender'] == ctx.preferredGender;
  }

  static bool _scheduleEligible(Map<String, dynamic> caregiver, OnboardingMatchContext ctx) {
    final caregiverTypes = (caregiver['careTypes'] as List?)?.cast<String>() ?? const [];
    return caregiverTypes.contains(ctx.preferredSchedule);
  }

  static double? _distanceKm(Map<String, dynamic> caregiver, OnboardingMatchContext ctx) {
    // Prefer the caregiver's own exact coordinates (onboarding map picker)
    // over the coarser city-name lookup, same as the advanced-match flow.
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
    final patientCity = cityCoords(ctx.cityName.split(',').first.trim());
    if (patientCity == null) return null;
    return haversineKm(
      double.parse(patientCity['lat']!),
      double.parse(patientCity['lng']!),
      caregiverLat,
      caregiverLng,
    );
  }

  // ── Stage 2 — ranking criteria, each normalised to 0..1 ────────────

  /// Bayesian-adjusted rating (ReviewService.adjustedRating), pre-computed
  /// by the caller and stamped as `adjustedRating` — see the class comment.
  static double _ratingScore(Map<String, dynamic> caregiver) {
    final adjusted = (caregiver['adjustedRating'] as num?)?.toDouble();
    if (adjusted == null) return 0.5; // caller didn't stamp one — neutral
    return (adjusted / 5.0).clamp(0.0, 1.0);
  }

  static double _proximityScore(Map<String, dynamic> caregiver, OnboardingMatchContext ctx) {
    final distanceKm = _distanceKm(caregiver, ctx);
    if (distanceKm == null) return 0.5; // neutral fallback, can't resolve
    return (1 - distanceKm / OnboardingMatchWeights.distanceCapKm).clamp(0.0, 1.0);
  }

  // ── Stage 3 — structural absence ────────────────────────────────────
  //
  // Rating: absent whenever the caregiver has zero reviews (see
  // ReviewService.stampAdjustedRatings, which stamps `reviewCount`
  // alongside `adjustedRating`).
  static Set<OnboardingMatchCriterion> structurallyAbsentCriteria(
    Map<String, dynamic> caregiver,
  ) {
    final absent = <OnboardingMatchCriterion>{};
    final reviewCount = (caregiver['reviewCount'] as num?)?.toInt() ?? 0;
    if (reviewCount == 0) absent.add(OnboardingMatchCriterion.rating);
    return absent;
  }

  // ── Scoring — survey-weighted, with redistribution ──────────────────
  static OnboardingMatchResult score({
    required Map<String, dynamic> caregiver,
    required OnboardingMatchContext context,
  }) {
    final absent = structurallyAbsentCriteria(caregiver)
        .intersection(OnboardingMatchWeights.structurallyAbsentEligible);

    double raw(OnboardingMatchCriterion c) => switch (c) {
          OnboardingMatchCriterion.rating => _ratingScore(caregiver),
          OnboardingMatchCriterion.proximity => _proximityScore(caregiver, context),
        };

    final presentSum = OnboardingMatchWeights.all
        .where((c) => !absent.contains(c))
        .fold(0.0, (sum, c) => sum + OnboardingMatchWeights.surveyAverages[c]!);

    double weightFor(OnboardingMatchCriterion c) =>
        presentSum == 0 ? 0 : OnboardingMatchWeights.surveyAverages[c]! / presentSum;

    double weightedRawSum = 0;
    for (final c in OnboardingMatchWeights.all) {
      if (absent.contains(c)) continue;
      weightedRawSum += weightFor(c) * raw(c);
    }

    final breakdown = <OnboardingCriterionScore>[
      for (final c in OnboardingMatchWeights.all)
        if (absent.contains(c))
          OnboardingCriterionScore(
            criterion: c,
            rawValue: null,
            weight: 0,
            structurallyAbsent: true,
            contributionPoints: 0,
          )
        else
          OnboardingCriterionScore(
            criterion: c,
            rawValue: raw(c),
            weight: weightFor(c),
            structurallyAbsent: false,
            contributionPoints: weightFor(c) * raw(c) * 100,
          ),
    ];

    final matchPercent = (weightedRawSum * 100).clamp(0.0, 100.0);

    return OnboardingMatchResult(
      caregiver: caregiver,
      matchPercent: matchPercent,
      breakdown: breakdown,
      distanceKm: _distanceKm(caregiver, context),
    );
  }

  // ── Full pipeline ───────────────────────────────────────────────────

  /// Scores every caregiver in [caregivers] and returns them sorted by
  /// descending match percentage. Does NOT apply Stage-1 eligibility —
  /// callers should filter with [isEligible] first.
  static List<OnboardingMatchResult> rankCaregivers({
    required List<Map<String, dynamic>> caregivers,
    required OnboardingMatchContext context,
  }) {
    final scored = caregivers
        .map((c) => score(caregiver: c, context: context))
        .toList();
    scored.sort((a, b) => b.matchPercent.compareTo(a.matchPercent));
    return scored;
  }
}
