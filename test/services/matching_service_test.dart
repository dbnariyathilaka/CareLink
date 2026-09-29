import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/data/care_type_skill_map.dart';
import 'package:flutter_application_1/services/matching_service.dart';

Map<String, dynamic> _caregiver({
  String uid = 'pro-1',
  String name = 'Priya Professional',
  String city = 'Negombo',
  List<String> skills = const ['Mobility assistance', 'Medication management'],
  List<String> careTypes = const ['Full-time'],
  String gender = 'Female',
  List<String> languagesSpoken = const ['Sinhala', 'English'],
  num? yearsExperience = 7, // clear of the 4-6yr boundary -> level 4/4
  int? nvqLevel = 6, // Higher National Diploma -> position 4/4 -> 1.0
  bool formalTraining = true,
  List<String> certificateUrls = const ['https://example.com/cert.pdf'],
  bool currentlyBusy = false,
  double? adjustedRating = 4.5,
  int reviewCount = 10, // >0 so rating is present by default
  bool nicVerified = true,
}) {
  return {
    'uid': uid,
    'name': name,
    'city': city,
    'skills': skills,
    'careTypes': careTypes,
    'gender': gender,
    'nicVerified': nicVerified,
    'languagesSpoken': languagesSpoken,
    'yearsExperience': yearsExperience,
    'nvqLevel': nvqLevel,
    'formalTraining': formalTraining,
    'certificateUrls': certificateUrls,
    'currentlyBusy': currentlyBusy,
    'adjustedRating': adjustedRating,
    'reviewCount': reviewCount,
  };
}

/// An informal caregiver with real experience but no NVQ certificate — the
/// thesis's S2 proxy case: education is never structurally absent, it just
/// falls back to a discounted proxy of the experience score (see
/// MatchingService._education).
Map<String, dynamic> _uncertifiedExperiencedCaregiver({
  String uid = 'informal-1',
  String city = 'Negombo',
  List<String> skills = const ['Mobility assistance', 'Medication management'],
  List<String> careTypes = const ['Full-time'],
  String gender = 'Female',
  List<String> languagesSpoken = const ['Sinhala', 'English'],
}) {
  return _caregiver(
    uid: uid,
    name: 'Ishara Informal',
    city: city,
    skills: skills,
    careTypes: careTypes,
    gender: gender,
    languagesSpoken: languagesSpoken,
    yearsExperience: 7,
    nvqLevel: null,
    formalTraining: false,
    certificateUrls: const [],
  );
}

// Base advanced-match context: same district as the default caregiver's
// city (Negombo), an exact schedule match, and a care type whose required
// skills the default caregiver covers in full — so a test overriding a
// single field via [extraRequestArgs] (or [gender]) exercises only the one
// hard filter or ranking criterion it's naming, not several at once.
MatchContext _ctx({
  String gender = 'No preference',
  Map<String, dynamic> extraRequestArgs = const {},
}) {
  return MatchContext(
    patientProfile: {'preferredCaregiverGender': gender},
    requestArgs: {
      'careType': 'Elder care',
      'schedule': 'Full-time',
      'location': 'Negombo',
      ...extraRequestArgs,
    },
  );
}

void main() {
  group('careTypeSkillMap', () {
    const patientCareTypes = [
      'Elder care',
      'Pediatric',
      'Post-surgery',
      'Physical disability',
      'Mental health',
      'Dementia',
      'Mobility assistance',
      'Medication management',
      'Wound care',
      'Rehabilitation',
      'Physiotherapy',
      'Child care', // alias used by edit_care_requirements_screen.dart
    ];

    for (final type in patientCareTypes) {
      test('"$type" resolves to a non-empty skill set', () {
        expect(careTypeSkillMap[type], isNotNull, reason: '$type has no map entry');
        expect(careTypeSkillMap[type], isNotEmpty, reason: '$type maps to an empty set');
      });
    }
  });

  group('Stage 1 — hard filters', () {
    test('excludes a caregiver whose NIC has not been automatically verified', () {
      final caregiver = _caregiver(nicVerified: false);
      expect(MatchingService.isEligible(caregiver, _ctx()), isFalse);
    });

    test('excludes a caregiver with none of the required skills', () {
      final caregiver = _caregiver(skills: ['Bathing assistance']);
      expect(MatchingService.isEligible(caregiver, _ctx()), isFalse);
    });

    test('passes when the caregiver covers at least one required skill', () {
      final caregiver = _caregiver(skills: ['Medication management']);
      expect(MatchingService.isEligible(caregiver, _ctx()), isTrue);
    });

    test('excludes a caregiver already mid-shift on another booking', () {
      final caregiver = _caregiver(currentlyBusy: true);
      expect(MatchingService.isEligible(caregiver, _ctx()), isFalse);
    });

    test('excludes a caregiver of the wrong gender when a preference is stated', () {
      final caregiver = _caregiver(gender: 'Male');
      expect(MatchingService.isEligible(caregiver, _ctx(gender: 'Female')), isFalse);
    });

    test('"No preference" gender does not exclude anyone', () {
      final caregiver = _caregiver(gender: 'Male');
      expect(MatchingService.isEligible(caregiver, _ctx(gender: 'No preference')), isTrue);
    });

    test('excludes a caregiver whose schedule does not exactly match', () {
      final caregiver = _caregiver(careTypes: const ['Part-time']);
      expect(MatchingService.isEligible(caregiver, _ctx()), isFalse);
    });

    test('"Flexible" is not a wildcard on the caregiver side', () {
      final caregiver = _caregiver(careTypes: const ['Flexible']);
      final ctx = _ctx(extraRequestArgs: {'schedule': 'Part-time'});
      expect(MatchingService.isEligible(caregiver, ctx), isFalse);
    });

    test('"Flexible" is not a wildcard on the patient side', () {
      final caregiver = _caregiver(careTypes: const ['Full-time']);
      final ctx = _ctx(extraRequestArgs: {'schedule': 'Flexible'});
      expect(MatchingService.isEligible(caregiver, ctx), isFalse);
    });

    test('excludes a caregiver missing the required language', () {
      final caregiver = _caregiver(languagesSpoken: const ['Tamil']);
      final ctx = _ctx(extraRequestArgs: {'languages': ['Sinhala']});
      expect(MatchingService.isEligible(caregiver, ctx), isFalse);
    });

    test('passes when no language requirement is stated', () {
      final caregiver = _caregiver(languagesSpoken: const ['Tamil']);
      expect(MatchingService.isEligible(caregiver, _ctx()), isTrue);
    });

    test('a caregiver more than 30km away is still eligible — distance is not a hard filter', () {
      final caregiver = _caregiver(city: 'Kandy');
      expect(MatchingService.isEligible(caregiver, _ctx()), isTrue);
    });

    test('fails open when the caregiver or patient city cannot be resolved', () {
      final caregiver = _caregiver(city: 'Not A Real City');
      expect(MatchingService.isEligible(caregiver, _ctx()), isTrue);
    });
  });

  group('education — S2 proxy', () {
    test('a certified caregiver scores by NVQ ordinal position', () {
      // NVQ 3 (Basic) is the 1st of 4 levels -> 1/4.
      final caregiver = _caregiver(nvqLevel: 3);
      final result = MatchingService.score(caregiver: caregiver, context: _ctx());
      final eduRow =
          result.breakdown.firstWhere((row) => row.criterion == MatchCriterion.education);
      expect(eduRow.structurallyAbsent, isFalse);
      expect(eduRow.rawValue, closeTo(0.25, 1e-9));
    });

    test('an uncertified caregiver is never excluded — scores 0.5x their experience instead', () {
      final caregiver = _uncertifiedExperiencedCaregiver(); // 7 yrs -> experience 1.0
      final result = MatchingService.score(caregiver: caregiver, context: _ctx());
      final eduRow =
          result.breakdown.firstWhere((row) => row.criterion == MatchCriterion.education);
      expect(eduRow.structurallyAbsent, isFalse);
      expect(eduRow.rawValue, closeTo(0.5, 1e-9));
    });
  });

  group('Stage 3 — structural absence', () {
    test('rating is absent when the caregiver has zero reviews', () {
      final caregiver = _caregiver(reviewCount: 0);
      final absent = MatchingService.structurallyAbsentCriteria(caregiver);
      expect(absent, contains(MatchCriterion.rating));
    });

    test('rating is present once the caregiver has at least one review', () {
      final caregiver = _caregiver(reviewCount: 1);
      final absent = MatchingService.structurallyAbsentCriteria(caregiver);
      expect(absent, isNot(contains(MatchCriterion.rating)));
    });

    test('proximity, experience and education are never structurally absent', () {
      final caregiver = _uncertifiedExperiencedCaregiver()..['reviewCount'] = 0;
      final absent = MatchingService.structurallyAbsentCriteria(caregiver);
      expect(absent, {MatchCriterion.rating});
    });
  });

  group('score — survey-weight redistribution', () {
    test('weights sum to 1.0 and follow survey averages when nothing is absent', () {
      final caregiver = _caregiver();
      final result = MatchingService.score(caregiver: caregiver, context: _ctx());

      expect(result.breakdown.length, 4);
      expect(result.breakdown.every((row) => !row.structurallyAbsent), isTrue);
      final weightSum = result.breakdown.fold(0.0, (a, row) => a + row.weight);
      expect(weightSum, closeTo(1.0, 1e-9));

      final presentSum = MatchWeights.surveyAverages.values.reduce((a, b) => a + b);
      for (final row in result.breakdown) {
        expect(row.weight, closeTo(MatchWeights.surveyAverages[row.criterion]! / presentSum, 1e-9));
      }
    });

    test('remaining weights rescale to 1.0 when rating is absent (cold start)', () {
      final caregiver = _caregiver(reviewCount: 0);
      final result = MatchingService.score(caregiver: caregiver, context: _ctx());

      final absentRows = result.breakdown.where((row) => row.structurallyAbsent);
      expect(absentRows.map((r) => r.criterion), [MatchCriterion.rating]);

      final presentWeights = result.breakdown
          .where((row) => !row.structurallyAbsent)
          .fold(0.0, (a, row) => a + row.weight);
      expect(presentWeights, closeTo(1.0, 1e-9));

      final presentSum = MatchWeights.surveyAverages.entries
          .where((e) => e.key != MatchCriterion.rating)
          .fold(0.0, (a, e) => a + e.value);
      for (final row in result.breakdown.where((row) => !row.structurallyAbsent)) {
        expect(row.weight, closeTo(MatchWeights.surveyAverages[row.criterion]! / presentSum, 1e-9));
      }
    });

    test('an absent criterion contributes zero points, not a zero-scored penalty', () {
      final caregiver = _caregiver(reviewCount: 0);
      final result = MatchingService.score(caregiver: caregiver, context: _ctx());

      final ratingRow =
          result.breakdown.firstWhere((row) => row.criterion == MatchCriterion.rating);
      expect(ratingRow.structurallyAbsent, isTrue);
      expect(ratingRow.rawValue, isNull);
      expect(ratingRow.contributionPoints, 0);
    });

    test('falls back to a neutral 0.5 proximity score when distance cannot be resolved', () {
      final caregiver = _caregiver(city: 'Not A Real City');
      final result = MatchingService.score(caregiver: caregiver, context: _ctx());
      final proximityRow =
          result.breakdown.firstWhere((row) => row.criterion == MatchCriterion.proximity);
      expect(proximityRow.rawValue, 0.5);
    });

    test('a far-away caregiver scores low on proximity but is not excluded', () {
      final caregiver = _caregiver(city: 'Kandy');
      final result = MatchingService.score(caregiver: caregiver, context: _ctx());
      final proximityRow =
          result.breakdown.firstWhere((row) => row.criterion == MatchCriterion.proximity);
      expect(proximityRow.rawValue, lessThan(0.5));
    });

    test('matchPercent matches a hand-computed value for a fully-scored caregiver', () {
      // Same city as the request -> proximity 1.0; 7 years experience ->
      // level 4/4 -> 1.0; NVQ 6 (Higher National Diploma) -> position 4/4 ->
      // 1.0; adjustedRating 4.5/5 -> 0.9.
      final caregiver = _caregiver();
      final result = MatchingService.score(caregiver: caregiver, context: _ctx());

      final presentSum = MatchWeights.surveyAverages.values.reduce((a, b) => a + b);
      final expected = (MatchWeights.surveyAverages[MatchCriterion.proximity]! * 1.0 +
              MatchWeights.surveyAverages[MatchCriterion.experience]! * 1.0 +
              MatchWeights.surveyAverages[MatchCriterion.education]! * 1.0 +
              MatchWeights.surveyAverages[MatchCriterion.rating]! * 0.9) /
          presentSum;
      expect(result.matchPercent, closeTo(expected * 100, 0.01));
    });
  });

  group('rankCaregivers', () {
    test('sorts descending and applies no eligibility gate of its own', () {
      final strong = _caregiver();
      final weak = _uncertifiedExperiencedCaregiver()
        ..['gender'] = 'Male'
        ..['reviewCount'] = 0
        ..['adjustedRating'] = null;

      final ranked = MatchingService.rankCaregivers(
        caregivers: [weak, strong],
        context: _ctx(),
      );

      // Both caregivers are present — rankCaregivers itself never filters;
      // that's the caller's job via isEligible (see advanced_match_results_screen.dart).
      expect(ranked.length, 2);
      expect(ranked.first.caregiver['uid'], 'pro-1');
      expect(ranked.first.matchPercent, greaterThanOrEqualTo(ranked.last.matchPercent));
    });

    test('isEligible + rankCaregivers together exclude an ineligible caregiver', () {
      final eligible = _caregiver();
      final ineligible = _caregiver(gender: 'Male')..['uid'] = 'wrong-gender';

      final ctx = _ctx(gender: 'Female');
      final pool = [eligible, ineligible];
      final filtered = pool.where((c) => MatchingService.isEligible(c, ctx)).toList();
      final ranked = MatchingService.rankCaregivers(caregivers: filtered, context: ctx);

      expect(ranked.map((r) => r.caregiver['uid']), isNot(contains('wrong-gender')));
      expect(ranked.length, 1);
    });
  });
}
