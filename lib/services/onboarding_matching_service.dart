import '../data/care_type_skill_map.dart';
import '../data/sri_lankan_cities.dart';

// ─────────────────────────────────────────────────────────────────────────
//  OnboardingMatchingService — the algorithm behind the "top match" preview
//  shown right after onboarding, before any specific booking request
//  exists. Deliberately kept SEPARATE from MatchingService (the advanced-
//  match wizard's algorithm) — different filters, different ranking
//  criteria, different weighting — so a change to one can never silently
//  change the other. Do not merge these two services.
//
//  Stage 1 — hard filters (exclude only, never scored):
//    - Skill match: the caregiver must offer at least one of the skills the
//      patient's requested care type maps to (care_type_skill_map.dart) —
//      a patient names a care need, a caregiver can list many skills, and
//      it's a binary match(1)/no-match(0) with no partial credit.
//    - Gender: only filters when the patient states Male/Female; ignored
//      entirely on "No preference".
//    - Work schedule: the caregiver must offer the patient's exact
//      preferred schedule — no "Flexible" wildcard exception either way.
//    - Proximity: a hard 30km cap (same ceiling the advanced-match flow
//      also happens to use, independently defined here rather than
//      imported, so the two stay decoupled).
//
//  Stage 2 — ranking, five criteria, equally weighted (1/5 each), with
//  weight redistribution when a caregiver has no data for one:
//    rating (Bayesian-adjusted), proximity, references, experience,
//    education.
//
//  Pure logic only: takes plain `Map<String, dynamic>` caregiver data (the
//  same shape Firestore hands back elsewhere) plus a small context record —
//  no Firestore access here. Callers must pre-fetch and stamp
//  `adjustedRating` onto each caregiver map first (ReviewService.
//  stampAdjustedRatings), the same way the advanced-match flow already does
//  for its own Feedback/ratings criterion.
// ─────────────────────────────────────────────────────────────────────────

enum OnboardingMatchCriterion { rating, proximity, references, experience, education }

class OnboardingMatchWeights {
  OnboardingMatchWeights._();

  static const double distanceCapKm = 30;

  static const List<OnboardingMatchCriterion> all = OnboardingMatchCriterion.values;

  static double get equalShare => 1.0 / all.length;

  /// References is the only criterion that can be genuinely absent — a
  /// caregiver whose reference letter was never verified (or was rejected)
  /// has no count at all, which is different from a verified count of 0.
  /// Experience/education are required onboarding fields and always have a
  /// value in practice, so they're scored directly rather than excluded.
  static const structurallyAbsentEligible = {OnboardingMatchCriterion.references};
}

/// Caregiver-declared years of experience, bucketed 1–4 — the same
/// boundaries used elsewhere in this app (<1yr=1, 1–3=2, 4–6=3, 6+=4).
int _experienceLevel(num years) {
  if (years < 1) return 1;
  if (years <= 3) return 2;
  if (years <= 6) return 3;
  return 4;
}

/// Ordinal caregiver education levels, normalised to 0..1.
const Map<String, double> _educationLevel = {
  'Primary': 0.25,
  'Secondary': 0.5,
  'Diploma': 0.75,
  'Degree or higher': 1.0,
};

/// Admin-verified reference count, bucketed 1–4 per the declared scale:
/// 1–2 references → 1, 3–5 → 2, 6–10 → 3, 10+ → 4.
int _referenceLevel(int count) {
  if (count <= 2) return 1;
  if (count <= 5) return 2;
  if (count <= 10) return 3;
  return 4;
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
  });

  final String careType;
  final String preferredSchedule;
  final String preferredGender; // 'No preference' | 'Male' | 'Female'
  final String cityName;
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
    OnboardingMatchCriterion.references: 'References',
    OnboardingMatchCriterion.experience: 'Experience',
    OnboardingMatchCriterion.education: 'Education',
  };

  // ── Stage 1 — hard filters ──────────────────────────────────────────

  static bool isEligible(Map<String, dynamic> caregiver, OnboardingMatchContext ctx) {
    return _nicVerifiedEligible(caregiver) &&
        _skillEligible(caregiver, ctx) &&
        _genderEligible(caregiver, ctx) &&
        _scheduleEligible(caregiver, ctx) &&
        _proximityEligible(caregiver, ctx);
  }

  /// A caregiver whose NIC hasn't passed automatic verification
  /// (NicVerificationService) is excluded outright — never scored, never
  /// shown as a "top match". Belt-and-suspenders alongside
  /// CaregiverService.searchCaregivers' own filter, for any caller that
  /// hands this service a caregiver list from elsewhere.
  static bool _nicVerifiedEligible(Map<String, dynamic> caregiver) {
    return caregiver['nicVerified'] == true;
  }

  static bool _skillEligible(Map<String, dynamic> caregiver, OnboardingMatchContext ctx) {
    final required = careTypeSkillMap[ctx.careType] ?? const <String>{};
    if (required.isEmpty) return true; // no specific requirement to fail
    final has = (caregiver['skills'] as List?)?.cast<String>().toSet() ?? const {};
    return required.intersection(has).isNotEmpty;
  }

  static bool _genderEligible(Map<String, dynamic> caregiver, OnboardingMatchContext ctx) {
    if (ctx.preferredGender.isEmpty || ctx.preferredGender == 'No preference') return true;
    return caregiver['gender'] == ctx.preferredGender;
  }

  static bool _scheduleEligible(Map<String, dynamic> caregiver, OnboardingMatchContext ctx) {
    final caregiverTypes = (caregiver['careTypes'] as List?)?.cast<String>() ?? const [];
    return caregiverTypes.contains(ctx.preferredSchedule);
  }

  static bool _proximityEligible(Map<String, dynamic> caregiver, OnboardingMatchContext ctx) {
    final distanceKm = _distanceKm(caregiver, ctx);
    if (distanceKm == null) return true; // fail-open, can't resolve
    return distanceKm <= OnboardingMatchWeights.distanceCapKm;
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

  static double _referencesScore(Map<String, dynamic> caregiver) {
    final count = caregiver['referenceCount'] as int?;
    if (count == null) return 0.0; // structural absence handles exclusion
    return _referenceLevel(count) / 4.0;
  }

  static double _experienceScore(Map<String, dynamic> caregiver) {
    final years = (caregiver['yearsExperience'] as num?);
    if (years == null) return 0.0;
    return _experienceLevel(years) / 4.0;
  }

  static double _educationScore(Map<String, dynamic> caregiver) {
    final level = caregiver['educationalQualification'] as String?;
    return _educationLevel[level] ?? 0.0;
  }

  // ── Stage 3 — structural absence ────────────────────────────────────
  //
  // Only counts as verified when the reference document was actually
  // approved (with a count assigned) by an admin — see
  // CaregiverService.setReferenceCount and admin_verification_queue_screen.
  // Rejected, still-pending, or never-submitted all mean the same thing
  // here: "nothing at all", not a score of 0.
  static Set<OnboardingMatchCriterion> structurallyAbsentCriteria(
    Map<String, dynamic> caregiver,
  ) {
    final absent = <OnboardingMatchCriterion>{};
    final reviews = (caregiver['documentReviews'] as Map?)?.cast<String, dynamic>();
    final referenceReview = (reviews?['reference'] as Map?)?.cast<String, dynamic>();
    final verified =
        referenceReview?['status'] == 'approved' && caregiver['referenceCount'] != null;
    if (!verified) absent.add(OnboardingMatchCriterion.references);
    return absent;
  }

  // ── Scoring (S1: weight redistribution) ─────────────────────────────
  static OnboardingMatchResult score({
    required Map<String, dynamic> caregiver,
    required OnboardingMatchContext context,
  }) {
    final absent = structurallyAbsentCriteria(caregiver)
        .intersection(OnboardingMatchWeights.structurallyAbsentEligible);
    final baseWeight = OnboardingMatchWeights.equalShare;

    double raw(OnboardingMatchCriterion c) => switch (c) {
          OnboardingMatchCriterion.rating => _ratingScore(caregiver),
          OnboardingMatchCriterion.proximity => _proximityScore(caregiver, context),
          OnboardingMatchCriterion.references => _referencesScore(caregiver),
          OnboardingMatchCriterion.experience => _experienceScore(caregiver),
          OnboardingMatchCriterion.education => _educationScore(caregiver),
        };

    double weightSum = 0;
    double weightedRawSum = 0;
    for (final c in OnboardingMatchWeights.all) {
      if (absent.contains(c)) continue;
      weightSum += baseWeight;
      weightedRawSum += baseWeight * raw(c);
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
            weight: weightSum == 0 ? 0 : baseWeight / weightSum,
            structurallyAbsent: false,
            contributionPoints:
                weightSum == 0 ? 0 : (baseWeight / weightSum) * raw(c) * 100,
          ),
    ];

    final matchPercent =
        weightSum == 0 ? 0.0 : ((weightedRawSum / weightSum) * 100).clamp(0.0, 100.0);

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
