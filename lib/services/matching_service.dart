import '../data/care_type_skill_map.dart';
import '../data/sri_lankan_cities.dart';

// ─────────────────────────────────────────────────────────────────────────
//  MatchingService — the advanced-match wizard's algorithm. Deliberately
//  separate from OnboardingMatchingService (the dashboard "top match"
//  preview) — different filters, different ranking criteria, different
//  weighting. Do not merge these two services.
//
//  Stage 1 — hard filters (exclude only, never scored):
//    - Skill match: any overlap between the caregiver's skills and what the
//      requested care type needs (care_type_skill_map.dart) — binary,
//      match(1)/no-match(0), no partial credit.
//    - Availability: the caregiver must not already be mid-shift on another
//      confirmed booking right now (`currentlyBusy`, pre-computed by the
//      caller — this service has no Firestore access). Applies to every
//      advanced-match request, not just emergency ones.
//    - Gender: only filters when the patient states Male/Female; ignored
//      on "No preference".
//    - Work schedule: the caregiver must offer the patient's exact
//      requested schedule — no "Flexible" wildcard exception either way.
//    - Spoken language: the caregiver must speak at least one of the
//      patient's required languages; skipped when none were stated.
//    - Proximity: MIXED — a hard 30km cap filters first, then the same
//      distance also feeds the proximity ranking score below.
//
//  Stage 2 — ranking, six criteria, equally weighted (1/6 each — 1/5 when
//  certification is skipped, see below), with weight redistribution when a
//  caregiver has no data for one:
//    rating (Bayesian-adjusted), proximity, references, experience,
//    certification, education.
//
//  Certification/formal training is conditional, not structural: it's only
//  included in the weighted average at all when the patient's qualifications
//  quiz asked for a certified caregiver. When they didn't ask, it's skipped
//  entirely (weight redistributed among the rest) rather than penalising
//  every caregiver for a preference nobody stated.
//
//  Pure logic only: every function here takes plain `Map<String, dynamic>`
//  caregiver/patient data and a MatchContext, and returns typed results —
//  no Firestore or Flutter imports. Criteria that need data this service
//  can't fetch itself (a caregiver's Bayesian-adjusted rating, whether
//  they're currently on an active booking) must be pre-computed by the
//  caller and stamped onto each caregiver map before calling in — see
//  `adjustedRating` and `currentlyBusy` below.
// ─────────────────────────────────────────────────────────────────────────

enum MatchCriterion { rating, proximity, references, experience, certification, education }

class MatchWeights {
  MatchWeights._();

  static const List<MatchCriterion> all = MatchCriterion.values;

  static double get equalShare => 1.0 / all.length;

  /// References (admin-verified count) and certification (conditional on
  /// the patient actually asking for one) are the two criteria that can be
  /// excluded from a given caregiver's score entirely, rather than merely
  /// scored low. Experience/education are required onboarding fields and
  /// always have a value in practice, so they're scored directly.
  static const structurallyAbsentEligible = {
    MatchCriterion.references,
    MatchCriterion.certification,
  };

  /// Hard distance cap (km) for the mixed proximity filter — administrator-
  /// set, hardcoded rather than a live setting since there's no admin-
  /// settings screen for it yet. Independently defined from
  /// OnboardingMatchWeights.distanceCapKm (same value today, but the two
  /// services are kept decoupled on purpose).
  static const double systemDistanceCapKm = 30;
}

/// Caregiver-declared years of experience, bucketed 1–4 — the same
/// boundaries used elsewhere in this app (<1yr=1, 1–3=2, 4–6=3, 6+=4).
int experienceLevel(num years) {
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

/// Admin-verified reference count, bucketed 1–4: 1–2 references → 1,
/// 3–5 → 2, 6–10 → 3, 10+ → 4. Same scale onboarding matching uses — it's
/// the same underlying caregiver data, not a separately-collected number.
int _referenceLevel(int count) {
  if (count <= 2) return 1;
  if (count <= 5) return 2;
  if (count <= 10) return 3;
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

  /// From the qualifications quiz's "Have you received formal caregiving
  /// training?" question — whether the patient actually asked for a
  /// certified caregiver. Gates certification both as a ranking criterion
  /// (skipped entirely when false) — certification is never a hard filter.
  bool get certificationRequested => requestArgs['training'] == 'Yes';

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
    MatchCriterion.references: 'References',
    MatchCriterion.experience: 'Experience',
    MatchCriterion.certification: 'Certification / training',
    MatchCriterion.education: 'Education',
  };

  static bool isProfessional(Map<String, dynamic> caregiver) {
    return caregiver['formalTraining'] == true ||
        ((caregiver['certificateUrls'] as List?)?.isNotEmpty ?? false);
  }

  /// A reference count only counts once an admin has actually verified it
  /// (CaregiverService.setReferenceCount) — rejected, still-pending, or
  /// never-submitted all mean "nothing at all", not a count of 0.
  static bool _hasVerifiedReferenceCount(Map<String, dynamic> caregiver) {
    final reviews = (caregiver['documentReviews'] as Map?)?.cast<String, dynamic>();
    final referenceReview = (reviews?['reference'] as Map?)?.cast<String, dynamic>();
    return referenceReview?['status'] == 'approved' && caregiver['referenceCount'] != null;
  }

  // ── Stage 1 — hard filters ──────────────────────────────────────────
  static bool isEligible(Map<String, dynamic> caregiver, MatchContext ctx) {
    return _nicVerifiedEligible(caregiver) &&
        _skillEligible(caregiver, ctx) &&
        _availabilityEligible(caregiver) &&
        _genderEligible(caregiver, ctx) &&
        _scheduleEligible(caregiver, ctx) &&
        _languageEligible(caregiver, ctx) &&
        _travelEligible(caregiver, ctx);
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

  static bool _skillEligible(Map<String, dynamic> caregiver, MatchContext ctx) {
    final required = careTypeSkillMap[ctx.careType] ?? const <String>{};
    if (required.isEmpty) return true; // no specific requirement to fail
    final has = (caregiver['skills'] as List?)?.cast<String>().toSet() ?? const {};
    return required.intersection(has).isNotEmpty;
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

  /// Proximity — MIXED: a hard 30km cap filters here; the same distance
  /// also feeds the proximity ranking score below. Fail-open when distance
  /// can't be resolved at all (unrecognised city, no coordinates anywhere)
  /// rather than excluding on missing data.
  static bool _travelEligible(Map<String, dynamic> caregiver, MatchContext ctx) {
    final distanceKm = _distanceKm(caregiver, ctx);
    if (distanceKm == null) return true;
    return distanceKm <= MatchWeights.systemDistanceCapKm;
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
  /// That formula already resolves a brand-new caregiver to exactly the
  /// platform average, so no separate cold-start override is needed here.
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

  static double _references(Map<String, dynamic> caregiver) {
    final count = caregiver['referenceCount'] as int?;
    if (count == null) return 0.0; // structural absence handles exclusion
    return _referenceLevel(count) / 4.0;
  }

  static double _experience(Map<String, dynamic> caregiver) {
    final years = (caregiver['yearsExperience'] as num?);
    if (years == null) return 0.0;
    return experienceLevel(years) / 4.0;
  }

  static double _certification(Map<String, dynamic> caregiver) {
    return isProfessional(caregiver) ? 1.0 : 0.0;
  }

  static double _education(Map<String, dynamic> caregiver) {
    final level = caregiver['educationalQualification'] as String?;
    return _educationLevel[level] ?? 0.0;
  }

  // ── Stage 3 — structural / conditional absence ─────────────────────────
  //
  // References: absent whenever no admin-verified count exists.
  // Certification: absent either because the patient never asked for a
  // certified caregiver (skipped as a matter of relevance — [ctx] decides
  // this), or because they did ask and this particular caregiver has no
  // certification signal on file (data absence, same as before).
  static Set<MatchCriterion> structurallyAbsentCriteria(
    Map<String, dynamic> caregiver,
    MatchContext ctx,
  ) {
    final absent = <MatchCriterion>{};
    if (!_hasVerifiedReferenceCount(caregiver)) absent.add(MatchCriterion.references);
    if (!ctx.certificationRequested || !isProfessional(caregiver)) {
      absent.add(MatchCriterion.certification);
    }
    return absent;
  }

  // ── Scoring (S1: weight redistribution) ────────────────────────────────
  static MatchResult score({
    required Map<String, dynamic> caregiver,
    required MatchContext context,
  }) {
    final absent = structurallyAbsentCriteria(caregiver, context)
        .intersection(MatchWeights.structurallyAbsentEligible);
    final baseWeight = MatchWeights.equalShare;

    double raw(MatchCriterion c) => switch (c) {
          MatchCriterion.rating => _rating(caregiver),
          MatchCriterion.proximity => _proximity(caregiver, context),
          MatchCriterion.references => _references(caregiver),
          MatchCriterion.experience => _experience(caregiver),
          MatchCriterion.certification => _certification(caregiver),
          MatchCriterion.education => _education(caregiver),
        };

    double weightSum = 0;
    double weightedRawSum = 0;
    for (final c in MatchWeights.all) {
      if (absent.contains(c)) continue;
      weightSum += baseWeight;
      weightedRawSum += baseWeight * raw(c);
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
            weight: weightSum == 0 ? 0 : baseWeight / weightSum,
            structurallyAbsent: false,
            contributionPoints: weightSum == 0 ? 0 : (baseWeight / weightSum) * raw(c) * 100,
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
