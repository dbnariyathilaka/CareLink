import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/services/onboarding_matching_service.dart';

Map<String, dynamic> _caregiver({
  String uid = 'pro-1',
  String city = 'Negombo',
  List<String> skills = const ['Mobility assistance', 'Medication management'],
  List<String> careTypes = const ['Full-time'],
  String gender = 'Female',
  double? adjustedRating = 4.5,
  int reviewCount = 10, // >0 so rating is present by default
  bool nicVerified = true,
}) {
  return {
    'uid': uid,
    'city': city,
    'skills': skills,
    'careTypes': careTypes,
    'gender': gender,
    'nicVerified': nicVerified,
    'adjustedRating': adjustedRating,
    'reviewCount': reviewCount,
  };
}

// Same city as the caregiver's default (Negombo), an exact schedule match,
// and a care type whose required skills the default caregiver covers.
OnboardingMatchContext _ctx({
  String preferredGender = 'No preference',
  String preferredSchedule = 'Full-time',
  String careType = 'Elder care',
  String cityName = 'Negombo',
}) {
  return OnboardingMatchContext(
    careType: careType,
    preferredSchedule: preferredSchedule,
    preferredGender: preferredGender,
    cityName: cityName,
  );
}

void main() {
  group('Stage 1 — hard filters', () {
    test('excludes a caregiver whose NIC has not been automatically verified', () {
      final caregiver = _caregiver(nicVerified: false);
      expect(OnboardingMatchingService.isEligible(caregiver, _ctx()), isFalse);
    });

    test('excludes a caregiver with none of the required skills', () {
      final caregiver = _caregiver(skills: ['Bathing assistance']);
      expect(OnboardingMatchingService.isEligible(caregiver, _ctx()), isFalse);
    });

    test('excludes a caregiver of the wrong gender when a preference is stated', () {
      final caregiver = _caregiver(gender: 'Male');
      expect(
        OnboardingMatchingService.isEligible(caregiver, _ctx(preferredGender: 'Female')),
        isFalse,
      );
    });

    test('"No preference" gender does not exclude anyone', () {
      final caregiver = _caregiver(gender: 'Male');
      expect(
        OnboardingMatchingService.isEligible(caregiver, _ctx(preferredGender: 'No preference')),
        isTrue,
      );
    });

    test('excludes a caregiver whose schedule does not exactly match', () {
      final caregiver = _caregiver(careTypes: const ['Part-time']);
      expect(OnboardingMatchingService.isEligible(caregiver, _ctx()), isFalse);
    });

    test('a caregiver more than 30km away is still eligible — distance is not a hard filter', () {
      final caregiver = _caregiver(city: 'Kandy');
      expect(OnboardingMatchingService.isEligible(caregiver, _ctx()), isTrue);
    });
  });

  group('Stage 3 — structural absence', () {
    test('rating is absent when the caregiver has zero reviews', () {
      final caregiver = _caregiver(reviewCount: 0);
      final absent = OnboardingMatchingService.structurallyAbsentCriteria(caregiver);
      expect(absent, {OnboardingMatchCriterion.rating});
    });

    test('rating is present once the caregiver has at least one review', () {
      final caregiver = _caregiver(reviewCount: 1);
      final absent = OnboardingMatchingService.structurallyAbsentCriteria(caregiver);
      expect(absent, isEmpty);
    });
  });

  group('score — survey-weight redistribution', () {
    test('proximity and rating split ~50/50 when both are present', () {
      final caregiver = _caregiver();
      final result = OnboardingMatchingService.score(caregiver: caregiver, context: _ctx());

      expect(result.breakdown.length, 2);
      expect(result.breakdown.every((row) => !row.structurallyAbsent), isTrue);
      final weightSum = result.breakdown.fold(0.0, (a, row) => a + row.weight);
      expect(weightSum, closeTo(1.0, 1e-9));

      final presentSum = OnboardingMatchWeights.surveyAverages.values.reduce((a, b) => a + b);
      for (final row in result.breakdown) {
        expect(
          row.weight,
          closeTo(OnboardingMatchWeights.surveyAverages[row.criterion]! / presentSum, 1e-9),
        );
      }
    });

    test('proximity takes 100% of the weight when rating is absent (cold start)', () {
      final caregiver = _caregiver(reviewCount: 0);
      final result = OnboardingMatchingService.score(caregiver: caregiver, context: _ctx());

      final ratingRow = result.breakdown
          .firstWhere((row) => row.criterion == OnboardingMatchCriterion.rating);
      expect(ratingRow.structurallyAbsent, isTrue);
      expect(ratingRow.rawValue, isNull);
      expect(ratingRow.contributionPoints, 0);

      final proximityRow = result.breakdown
          .firstWhere((row) => row.criterion == OnboardingMatchCriterion.proximity);
      expect(proximityRow.weight, closeTo(1.0, 1e-9));
    });

    test('matchPercent matches a hand-computed value for a fully-scored caregiver', () {
      // Same city as the request -> proximity 1.0; adjustedRating 4.5/5 -> 0.9.
      final caregiver = _caregiver();
      final result = OnboardingMatchingService.score(caregiver: caregiver, context: _ctx());

      final presentSum = OnboardingMatchWeights.surveyAverages.values.reduce((a, b) => a + b);
      final expected = (OnboardingMatchWeights.surveyAverages[OnboardingMatchCriterion.proximity]! *
                  1.0 +
              OnboardingMatchWeights.surveyAverages[OnboardingMatchCriterion.rating]! * 0.9) /
          presentSum;
      expect(result.matchPercent, closeTo(expected * 100, 0.01));
    });

    test('a far-away caregiver scores low on proximity but is not excluded', () {
      final caregiver = _caregiver(city: 'Kandy');
      final result = OnboardingMatchingService.score(caregiver: caregiver, context: _ctx());
      final proximityRow = result.breakdown
          .firstWhere((row) => row.criterion == OnboardingMatchCriterion.proximity);
      expect(proximityRow.rawValue, lessThan(0.5));
    });
  });

  group('rankCaregivers', () {
    test('sorts descending and applies no eligibility gate of its own', () {
      final strong = _caregiver();
      final weak = _caregiver(uid: 'weak-1', reviewCount: 0, adjustedRating: null)
        ..['city'] = 'Kandy';

      final ranked = OnboardingMatchingService.rankCaregivers(
        caregivers: [weak, strong],
        context: _ctx(),
      );

      expect(ranked.length, 2);
      expect(ranked.first.caregiver['uid'], 'pro-1');
      expect(ranked.first.matchPercent, greaterThanOrEqualTo(ranked.last.matchPercent));
    });
  });
}
