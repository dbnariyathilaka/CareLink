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
  String? educationalQualification = 'Degree or higher',
  bool formalTraining = true,
  List<String> certificateUrls = const ['https://example.com/cert.pdf'],
  int? referenceCount,
  bool referenceVerified = false,
  bool currentlyBusy = false,
  double? adjustedRating = 4.5,
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
    'educationalQualification': educationalQualification,
    'formalTraining': formalTraining,
    'certificateUrls': certificateUrls,
    'referenceCount': referenceCount,
    if (referenceVerified)
      'documentReviews': {
        'reference': {'status': 'approved', 'count': referenceCount},
      },
    'currentlyBusy': currentlyBusy,
    'adjustedRating': adjustedRating,
  };
}

Map<String, dynamic> _informalCaregiverMissingEverything({
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
    yearsExperience: null,
    educationalQualification: 'Secondary',
    formalTraining: false,
    certificateUrls: const [],
    referenceCount: null,
    referenceVerified: false,
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

    test('excludes a caregiver more than 30km away', () {
      final caregiver = _caregiver(city: 'Kandy');
      expect(MatchingService.isEligible(caregiver, _ctx()), isFalse);
    });

    test('a caregiver within the 30km radius is eligible', () {
      final caregiver = _caregiver(city: 'Ja-Ela');
      expect(MatchingService.isEligible(caregiver, _ctx()), isTrue);
    });

    test('fails open when the caregiver or patient city cannot be resolved', () {
      final caregiver = _caregiver(city: 'Not A Real City');
      expect(MatchingService.isEligible(caregiver, _ctx()), isTrue);
    });

    test('certification is never a hard filter, even when the patient asked for one', () {
      final caregiver = _informalCaregiverMissingEverything();
      final ctx = _ctx(extraRequestArgs: {'training': 'Yes'});
      expect(MatchingService.isEligible(caregiver, ctx), isTrue);
    });
  });

  group('Stage 3 — structural / conditional absence', () {
    test('references are absent without an admin-verified count', () {
      final caregiver = _caregiver(referenceCount: null, referenceVerified: false);
      final absent = MatchingService.structurallyAbsentCriteria(caregiver, _ctx());
      expect(absent, contains(MatchCriterion.references));
    });

    test('references are present once admin-verified', () {
      final caregiver = _caregiver(referenceCount: 6, referenceVerified: true);
      final absent = MatchingService.structurallyAbsentCriteria(caregiver, _ctx());
      expect(absent, isNot(contains(MatchCriterion.references)));
    });

    test('certification is absent (skipped) when the patient never asked for one, '
        'even for a certified caregiver', () {
      final caregiver = _caregiver(formalTraining: true);
      final absent = MatchingService.structurallyAbsentCriteria(caregiver, _ctx());
      expect(absent, contains(MatchCriterion.certification));
    });

    test('certification is present when requested and the caregiver is certified', () {
      final caregiver = _caregiver(formalTraining: true);
      final ctx = _ctx(extraRequestArgs: {'training': 'Yes'});
      final absent = MatchingService.structurallyAbsentCriteria(caregiver, ctx);
      expect(absent, isNot(contains(MatchCriterion.certification)));
    });

    test('certification is absent when requested but the caregiver has none on file', () {
      final caregiver = _informalCaregiverMissingEverything();
      final ctx = _ctx(extraRequestArgs: {'training': 'Yes'});
      final absent = MatchingService.structurallyAbsentCriteria(caregiver, ctx);
      expect(absent, contains(MatchCriterion.certification));
    });
  });

  group('score — S1 weight redistribution', () {
    test('weights sum to 1.0 across all 6 criteria when nothing is absent', () {
      final caregiver = _caregiver(referenceCount: 6, referenceVerified: true);
      final ctx = _ctx(extraRequestArgs: {'training': 'Yes'});
      final result = MatchingService.score(caregiver: caregiver, context: ctx);

      expect(result.breakdown.length, 6);
      expect(result.breakdown.every((row) => !row.structurallyAbsent), isTrue);
      final weightSum = result.breakdown.fold(0.0, (a, row) => a + row.weight);
      expect(weightSum, closeTo(1.0, 1e-9));
      for (final row in result.breakdown) {
        expect(row.weight, closeTo(1 / 6, 1e-9));
      }
    });

    test('remaining weights rescale to 1.0 when only references are absent', () {
      final caregiver = _caregiver(referenceCount: null, referenceVerified: false);
      final ctx = _ctx(extraRequestArgs: {'training': 'Yes'}); // certified caregiver -> present
      final result = MatchingService.score(caregiver: caregiver, context: ctx);

      final absentRows = result.breakdown.where((row) => row.structurallyAbsent);
      expect(absentRows.map((r) => r.criterion), [MatchCriterion.references]);
      final presentWeights = result.breakdown
          .where((row) => !row.structurallyAbsent)
          .fold(0.0, (a, row) => a + row.weight);
      expect(presentWeights, closeTo(1.0, 1e-9));
    });

    test('remaining weights rescale to 1.0 when both references and certification are absent', () {
      final caregiver = _informalCaregiverMissingEverything();
      final result = MatchingService.score(caregiver: caregiver, context: _ctx());

      final absent = result.breakdown.where((row) => row.structurallyAbsent).map((r) => r.criterion);
      expect(absent, containsAll(<MatchCriterion>[MatchCriterion.references, MatchCriterion.certification]));
      final presentWeights = result.breakdown
          .where((row) => !row.structurallyAbsent)
          .fold(0.0, (a, row) => a + row.weight);
      expect(presentWeights, closeTo(1.0, 1e-9));
      for (final row in result.breakdown.where((row) => !row.structurallyAbsent)) {
        expect(row.weight, closeTo(1 / 4, 1e-9));
      }
    });

    test('an absent criterion contributes zero points, not a zero-scored penalty', () {
      final caregiver = _informalCaregiverMissingEverything();
      final result = MatchingService.score(caregiver: caregiver, context: _ctx());

      final certRow =
          result.breakdown.firstWhere((row) => row.criterion == MatchCriterion.certification);
      expect(certRow.structurallyAbsent, isTrue);
      expect(certRow.rawValue, isNull);
      expect(certRow.contributionPoints, 0);
    });

    test('falls back to a neutral 0.5 proximity score when distance cannot be resolved', () {
      final caregiver = _caregiver(city: 'Not A Real City');
      final result = MatchingService.score(caregiver: caregiver, context: _ctx());
      final proximityRow =
          result.breakdown.firstWhere((row) => row.criterion == MatchCriterion.proximity);
      expect(proximityRow.rawValue, 0.5);
    });

    test('matchPercent matches a hand-computed value for a fully-scored caregiver', () {
      // Same city as the request -> proximity 1.0; adjustedRating 4.5/5 ->
      // 0.9; 7 years experience -> level 4/4 -> 1.0; 'Degree or higher' ->
      // 1.0; 6 verified references -> level 3/4 -> 0.75; certified and
      // requested -> 1.0.
      final caregiver = _caregiver(referenceCount: 6, referenceVerified: true);
      final ctx = _ctx(extraRequestArgs: {'training': 'Yes'});
      final result = MatchingService.score(caregiver: caregiver, context: ctx);

      const expected = (0.9 + 1.0 + 0.75 + 1.0 + 1.0 + 1.0) / 6;
      expect(result.matchPercent, closeTo(expected * 100, 0.01));
    });
  });

  group('rankCaregivers', () {
    test('sorts descending and applies no eligibility gate of its own', () {
      final strong = _caregiver(referenceCount: 10, referenceVerified: true);
      final weak = _informalCaregiverMissingEverything()..['gender'] = 'Male';

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
