import '../data/sri_lankan_cities.dart';

// ─────────────────────────────────────────────────────────────────────────
//  MatchingService — the advanced-match wizard's algorithm, implementing
//  Chapter 4.4 of the thesis this app is built from. Deliberately separate
//  from OnboardingMatchingService (the dashboard "top match" preview) —
//  different filters, different ranking criteria, different weighting. Do
//  not merge these two services.
//
//  Stage 1 — hard filters (exclude only, never scored):
//    - Care category: the caregiver's own declared `careCategory` (see
//      ../data/care_categories.dart) must exactly equal the patient's
//      requested care type — a direct field comparison now that caregivers
//      declare this themselves at onboarding, not a skill-overlap proxy.
//    - Required skills: the caregiver must have EVERY skill the patient
//      asked for in their own `skills` list, not just an overlap — a
//      stricter all-must-match constraint, independent of care category.
//    - Availability: the caregiver must not already be mid-shift on another
//      confirmed booking right now (`currentlyBusy`, pre-computed by the
//      caller — this service has no Firestore access).
//    - Gender: only filters when the patient states Male/Female; ignored
//      on "No preference".
//    - Work schedule: the caregiver must offer the patient's exact
//      requested schedule — no "Flexible" wildcard exception either way.
//    - Spoken language: the caregiver must speak at least one of the
//      patient's required languages; skipped when none were stated.
//
//  Distance is deliberately NOT a hard filter — the thesis's must-have-rule
//  tables never list it as one, only as a ranking formula input. A far-away
//  caregiver still appears in results, just scored low on proximity.
//  `systemDistanceCapKm` is kept purely as that formula's normalization
//  ceiling.
//
//  Stage 2 — ranking, four criteria — rating, proximity, experience,
//  education — weighted by real average importance ratings from a survey
//  of 103 Sri Lankan patients/family members (surveyAverages below), not
//  equal shares. Weights redistribute when rating is structurally absent
//  (a caregiver with zero reviews); proximity/experience/education are
//  never absent — education in particular always has a value via the S2
//  proxy (see _education), which is the thesis's whole point in Step 4.
//
//  Pure logic only: every function here takes plain `Map<String, dynamic>`
//  caregiver/patient data and a MatchContext, and returns typed results —
//  no Firestore or Flutter imports. Criteria that need data this service
//  can't fetch itself (a caregiver's Bayesian-adjusted rating and review
//  count, whether they're currently on an active booking) must be
//  pre-computed by the caller and stamped onto each caregiver map before
//  calling in — see `adjustedRating`/`reviewCount` (ReviewService.
//  stampAdjustedRatings) and `currentlyBusy` below.
// ─────────────────────────────────────────────────────────────────────────

enum MatchCriterion { rating, proximity, experience, education }

/// NVQ certificate levels this app collects (3–6, Sri Lanka's vocational
/// framework runs 1–7; only the levels relevant to caregiving are offered
/// here), and the caregiver-facing label for each — shown wherever a
/// caregiver picks or displays their certification.
const Map<int, String> nvqLabels = {
  3: 'Basic certificate (NVQ 3)',
  4: 'Advanced certificate (NVQ 4)',
  5: 'Diploma (NVQ 5)',
  6: 'Higher National Diploma (NVQ 6)',
};

class MatchWeights {
  MatchWeights._();

  static const List<MatchCriterion> all = MatchCriterion.values;

  /// Real average importance ratings (1–4 scale) from the thesis's survey
  /// of 103 families — NOT equal shares. A criterion's weight is its own
  /// average divided by the sum of every *currently present* criterion's
  /// average (see MatchingService.score's weightFor), which reproduces
  /// both the thesis's full-criteria weights (0.29/0.29/0.13/0.29) and its
  /// cold-start weights (0.405/0.413/0.182 when rating is absent) from
  /// this one source table, instead of needing a second hardcoded set of
  /// numbers for the redistributed case.
  static const Map<MatchCriterion, double> surveyAverages = {
    MatchCriterion.proximity: 3.43,
    MatchCriterion.experience: 3.50,
    MatchCriterion.education: 1.54,
    MatchCriterion.rating: 3.44,
  };

  /// Rating is the only criterion that can be genuinely absent — a
  /// caregiver with zero reviews has nothing to average, which is
  /// different from a real rating that happens to be low. Experience is a
  /// required onboarding field, always present. Education is never absent
  /// either: an uncertified caregiver gets the S2 proxy score instead of
  /// exclusion (see _education).
  static const structurallyAbsentEligible = {MatchCriterion.rating};

  /// Normalization ceiling for the proximity score only — not a hard
  /// filter (see class doc comment above).
  static const double systemDistanceCapKm = 30;

  /// S2 proxy discount (δ) — an uncertified caregiver's education score is
  /// this fraction of their experience score, since experience is weaker
  /// evidence of competence than a certificate but not nothing. From the
  /// thesis's own worked example (δ = 0.5).
  static const double trainingProxyDiscount = 0.5;
}

/// Caregiver-declared years of experience, bucketed 1–4 — the same
/// boundaries used elsewhere in this app (<1yr=1, 1–3=2, 4–6=3, 6+=4).
int experienceLevel(num years) {
  if (years < 1) return 1;
  if (years <= 3) return 2;
  if (years <= 6) return 3;
  return 4;
}

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

  /// Only ever populated by the wizard's qualifications quiz.
  List<String> get requiredLanguages =>
      (requestArgs['languages'] as List?)?.cast<String>() ?? const [];

  /// The specific skills the patient ticked on onboarding step 2 ("What
  /// kind of skills needed?") — see ../data/care_categories.dart. A
  /// caregiver must have every one of these to be eligible, not just an
  /// overlap (see MatchingService._requiredSkillsEligible).
  List<String> get requiredSkills =>
      (requestArgs['requiredSkills'] as List?)?.cast<String>() ??
      (patientProfile?['requiredSkills'] as List?)?.cast<String>() ??
      const [];

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
    MatchCriterion.rating: 'Rating',
    MatchCriterion.proximity: 'Proximity',
    MatchCriterion.experience: 'Experience',
    MatchCriterion.education: 'Education',
  };

  // ── Stage 1 — hard filters ──────────────────────────────────────────
  static bool isEligible(Map<String, dynamic> caregiver, MatchContext ctx) {
    return _nicVerifiedEligible(caregiver) &&
        _careCategoryEligible(caregiver, ctx) &&
        _requiredSkillsEligible(caregiver, ctx) &&
        _availabilityEligible(caregiver) &&
        _genderEligible(caregiver, ctx) &&
        _scheduleEligible(caregiver, ctx) &&
        _languageEligible(caregiver, ctx);
  }

  /// A caregiver whose NIC hasn't passed automatic verification
  /// (NicVerificationService, checked at onboarding/edit-profile time) is
  /// excluded outright — never scored, never shown as a match. Belt-and-
  /// suspenders alongside CaregiverService.searchCaregivers' own filter,
  /// for any caller that hands this service a caregiver list from
  /// elsewhere.
  static bool _nicVerifiedEligible(Map<String, dynamic> caregiver) {
    return caregiver['nicVerified'] == true;
  }

  /// Exact match against the caregiver's own declared care category — no
  /// requirement to fail when the patient's care type is empty.
  static bool _careCategoryEligible(Map<String, dynamic> caregiver, MatchContext ctx) {
    if (ctx.careType.isEmpty) return true;
    return caregiver['careCategory'] == ctx.careType;
  }

  /// The caregiver must have every skill the patient asked for — not just
  /// an overlap.
  static bool _requiredSkillsEligible(Map<String, dynamic> caregiver, MatchContext ctx) {
    if (ctx.requiredSkills.isEmpty) return true;
    final has = (caregiver['skills'] as List?)?.cast<String>().toSet() ?? const {};
    return ctx.requiredSkills.every(has.contains);
  }

  /// `currentlyBusy` is pre-computed by the caller (BookingService.
  /// currentlyBusyCaregiverIds) — missing/absent is treated as "not busy"
  /// so this never wrongly excludes a caregiver the caller didn't check.
  static bool _availabilityEligible(Map<String, dynamic> caregiver) {
    return caregiver['currentlyBusy'] != true;
  }

  static bool _genderEligible(Map<String, dynamic> caregiver, MatchContext ctx) {
    final pref = ctx.preferredGender;
    if (pref.isEmpty || pref == 'No preference') return true;
    return caregiver['gender'] == pref;
  }

  /// Schedules must be exactly equal — no "Flexible" wildcard on either
  /// side. A part-time caregiver cannot cover a full-time/live-in request,
  /// and a caregiver who only listed "Flexible" doesn't automatically
  /// cover a patient asking specifically for "Part-time", or vice versa.
  static bool _scheduleEligible(Map<String, dynamic> caregiver, MatchContext ctx) {
    final caregiverTypes = (caregiver['careTypes'] as List?)?.cast<String>() ?? const [];
    return caregiverTypes.contains(ctx.requestedSchedule);
  }

  static bool _languageEligible(Map<String, dynamic> caregiver, MatchContext ctx) {
    if (ctx.requiredLanguages.isEmpty) return true;
    final spoken = (caregiver['languagesSpoken'] as List?)?.cast<String>() ?? const [];
    return ctx.requiredLanguages.any(spoken.contains);
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
      return haversineKm(ctx.requestLat!, ctx.requestLng!, caregiverLat, caregiverLng);
    }
    final patientCity = cityCoords(ctx.locationCityName.split(',').first.trim());
    if (patientCity == null) return null;
    return haversineKm(
      double.parse(patientCity['lat']!),
      double.parse(patientCity['lng']!),
      caregiverLat,
      caregiverLng,
    );
  }

  // ── Criterion scorers, each normalised to 0..1 ─────────────────────────

  /// Bayesian-adjusted rating (ReviewService.adjustedRating), pre-computed
  /// by the caller and stamped onto the caregiver map as `adjustedRating`.
  static double _rating(Map<String, dynamic> caregiver) {
    final adjusted = (caregiver['adjustedRating'] as num?)?.toDouble();
    if (adjusted == null) return 0.5; // caller didn't stamp one — neutral
    return (adjusted / 5.0).clamp(0.0, 1.0);
  }

  static double _proximity(Map<String, dynamic> caregiver, MatchContext ctx) {
    final distanceKm = _distanceKm(caregiver, ctx);
    if (distanceKm == null) return 0.5; // neutral fallback, can't resolve
    return (1 - distanceKm / MatchWeights.systemDistanceCapKm).clamp(0.0, 1.0);
  }

  static double _experience(Map<String, dynamic> caregiver) {
    final years = (caregiver['yearsExperience'] as num?);
    if (years == null) return 0.0;
    return experienceLevel(years) / 4.0;
  }

  /// The thesis's S2 strategy (Step 4): a caregiver's real NVQ certificate
  /// scores by its ordinal position among the 4 levels this app offers
  /// (Basic = 1st .. Higher National Diploma = 4th, i.e. position/4 — the
  /// same shape the old Primary/Secondary/Diploma/Degree scale used). An
  /// uncertified caregiver — `nvqLevel` absent — is NOT scored 0 and is
  /// NOT excluded from this criterion; they get a discounted proxy of
  /// their experience score instead, since the certificate structurally
  /// cannot exist for many informal caregivers and zero-filling it would
  /// unfairly bury them (the thesis's own S0 comparison, which it improves
  /// on).
  static double _education(Map<String, dynamic> caregiver) {
    final level = (caregiver['nvqLevel'] as num?)?.toInt();
    if (level != null) {
      final position = (level - 2).clamp(1, 4);
      return position / 4.0;
    }
    return MatchWeights.trainingProxyDiscount * _experience(caregiver);
  }

  // ── Stage 3 — structural absence ─────────────────────────────────────
  //
  // Rating: absent whenever the caregiver has zero reviews (see
  // ReviewService.stampAdjustedRatings, which stamps `reviewCount`
  // alongside `adjustedRating`) — a real Bayesian-smoothed value still
  // exists on the map even then, but the thesis's cold-start handling
  // excludes the criterion entirely rather than trusting a value backed by
  // no actual feedback.
  static Set<MatchCriterion> structurallyAbsentCriteria(
    Map<String, dynamic> caregiver,
  ) {
    final absent = <MatchCriterion>{};
    final reviewCount = (caregiver['reviewCount'] as num?)?.toInt() ?? 0;
    if (reviewCount == 0) absent.add(MatchCriterion.rating);
    return absent;
  }

  // ── Scoring — survey-weighted, with redistribution ─────────────────────
  static MatchResult score({
    required Map<String, dynamic> caregiver,
    required MatchContext context,
  }) {
    final absent = structurallyAbsentCriteria(caregiver)
        .intersection(MatchWeights.structurallyAbsentEligible);

    double raw(MatchCriterion c) => switch (c) {
          MatchCriterion.rating => _rating(caregiver),
          MatchCriterion.proximity => _proximity(caregiver, context),
          MatchCriterion.experience => _experience(caregiver),
          MatchCriterion.education => _education(caregiver),
        };

    // Each present criterion's weight is its own survey average divided by
    // the sum of every *present* criterion's average — the thesis's own
    // "weight = average ÷ sum of averages" rule (Step 3), generalised to
    // whichever subset of criteria actually has data this time.
    final presentSum = MatchWeights.all
        .where((c) => !absent.contains(c))
        .fold(0.0, (sum, c) => sum + MatchWeights.surveyAverages[c]!);

    double weightFor(MatchCriterion c) =>
        presentSum == 0 ? 0 : MatchWeights.surveyAverages[c]! / presentSum;

    double weightedRawSum = 0;
    for (final c in MatchWeights.all) {
      if (absent.contains(c)) continue;
      weightedRawSum += weightFor(c) * raw(c);
    }

    final breakdown = <CriterionScore>[
      for (final c in MatchWeights.all)
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
            weight: weightFor(c),
            structurallyAbsent: false,
            contributionPoints: weightFor(c) * raw(c) * 100,
          ),
    ];

    final matchPercent = (weightedRawSum * 100).clamp(0.0, 100.0);

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
