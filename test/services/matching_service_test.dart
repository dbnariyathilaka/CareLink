import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/data/care_type_skill_map.dart';
import 'package:flutter_application_1/services/matching_service.dart';

Map<String, dynamic> _professionalCaregiver({
  String city = 'Negombo',
  int serviceRadiusKm = 15,
  List<String> skills = const ['Mobility assistance', 'Medication management'],
  List<String> careTypes = const ['Full-time'],
  String gender = 'Female',
  List<String> languagesSpoken = const ['Sinhala', 'English'],
  int yearsExperience = 6,
  String referencePhone = '+94771234567',
  bool formalTraining = true,
  List<String> certificateUrls = const ['https://example.com/cert.pdf'],
}) {
  return {
    'uid': 'pro-1',
    'name': 'Priya Professional',
    'city': city,
    'serviceRadiusKm': serviceRadiusKm,
    'skills': skills,
    'careTypes': careTypes,
    'gender': gender,
    'languagesSpoken': languagesSpoken,
    'yearsExperience': yearsExperience,
    'referencePhone': referencePhone,
    'formalTraining': formalTraining,
    'certificateUrls': certificateUrls,
  };
}

Map<String, dynamic> _informalCaregiverMissingEverything({
  String city = 'Negombo',
  int serviceRadiusKm = 15,
  List<String> skills = const ['Mobility assistance', 'Medication management'],
  List<String> careTypes = const ['Full-time'],
  String gender = 'Female',
  List<String> languagesSpoken = const ['Sinhala', 'English'],
}) {
  return {
    'uid': 'informal-1',
    'name': 'Ishara Informal',
    'city': city,
    'serviceRadiusKm': serviceRadiusKm,
    'skills': skills,
    'careTypes': careTypes,
    'gender': gender,
    'languagesSpoken': languagesSpoken,
    'yearsExperience': null,
    'referencePhone': '',
    'formalTraining': false,
    'certificateUrls': const <String>[],
  };
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

  group('Stage 1 — eligibility', () {
    test('excludes a caregiver missing the required language', () {
      final caregiver = _professionalCaregiver(languagesSpoken: ['Tamil']);
      final ctx = MatchContext(requestArgs: {
        'languages': ['Sinhala'],
        'location': 'Negombo',
      });
      expect(MatchingService.isEligible(caregiver, ctx), isFalse);
    });

    test('passes when no language requirement is stated', () {
      final caregiver = _professionalCaregiver(languagesSpoken: ['Tamil']);
      final ctx = MatchContext(requestArgs: {'location': 'Negombo'});
      expect(MatchingService.isEligible(caregiver, ctx), isTrue);
    });

    test('excludes a caregiver of the wrong gender when a preference is stated', () {
      final caregiver = _professionalCaregiver(gender: 'Male');
      final ctx = MatchContext(
        patientProfile: {'preferredCaregiverGender': 'Female', 'city': 'Negombo'},
      );
      expect(MatchingService.isEligible(caregiver, ctx), isFalse);
    });

    test('"No preference" gender does not exclude anyone', () {
      final caregiver = _professionalCaregiver(gender: 'Male');
      final ctx = MatchContext(
        patientProfile: {'preferredCaregiverGender': 'No preference', 'city': 'Negombo'},
      );
      expect(MatchingService.isEligible(caregiver, ctx), isTrue);
    });

    test('excludes an uncertified caregiver when certification is mandatory', () {
      final caregiver = _informalCaregiverMissingEverything();
      final ctx = MatchContext(requestArgs: {'training': 'Yes', 'location': 'Negombo'});
      expect(MatchingService.isEligible(caregiver, ctx), isFalse);
    });

    test('a certified caregiver passes the mandatory-certification rule', () {
      final caregiver = _professionalCaregiver();
      final ctx = MatchContext(requestArgs: {'training': 'Yes', 'location': 'Negombo'});
      expect(MatchingService.isEligible(caregiver, ctx), isTrue);
    });

    test('excludes a caregiver outside both district and travel radius', () {
      // Negombo and Kandy are in different districts and > 60km apart.
      final caregiver = _professionalCaregiver(city: 'Kandy', serviceRadiusKm: 10);
      final ctx = MatchContext(requestArgs: {'location': 'Negombo'});
      expect(MatchingService.isEligible(caregiver, ctx), isFalse);
    });

    test('same-district caregiver is eligible regardless of travel radius', () {
      // Negombo and Ja-Ela are both in Gampaha District.
      final caregiver = _professionalCaregiver(city: 'Ja-Ela', serviceRadiusKm: 0);
      final ctx = MatchContext(requestArgs: {'location': 'Negombo'});
      expect(MatchingService.isEligible(caregiver, ctx), isTrue);
    });

    test('fails open when the caregiver or patient city cannot be resolved', () {
      final caregiver = _professionalCaregiver(city: 'Not A Real City', serviceRadiusKm: 0);
      final ctx = MatchContext(requestArgs: {'location': 'Negombo'});
      expect(MatchingService.isEligible(caregiver, ctx), isTrue);
    });
  });

  group('Stage 3 — structural absence (hybrid rule)', () {
    test('a professional caregiver is never flagged, even with missing data', () {
      final caregiver = _professionalCaregiver()
        ..['referencePhone'] = ''
        ..['yearsExperience'] = null;
      final absent = MatchingService.structurallyAbsentCriteria(caregiver, reviewCount: 0);
      expect(absent, isEmpty);
    });

    test('an informal caregiver with data present is not flagged for that criterion', () {
      final caregiver = _informalCaregiverMissingEverything()
        ..['referencePhone'] = '+94770000000'
        ..['yearsExperience'] = 3;
      final absent = MatchingService.structurallyAbsentCriteria(caregiver, reviewCount: 2);
      expect(absent, isNot(contains(MatchCriterion.references)));
      expect(absent, isNot(contains(MatchCriterion.experience)));
      expect(absent, isNot(contains(MatchCriterion.feedback)));
      // Certification is definitionally tied to isProfessional() — see the
      // doc comment on MatchingService.isProfessional — so it's still
      // flagged for an informal caregiver even when other fields are filled.
      expect(absent, contains(MatchCriterion.certification));
    });

    test('an informal caregiver missing everything is flagged for all four', () {
      final caregiver = _informalCaregiverMissingEverything();
      final absent = MatchingService.structurallyAbsentCriteria(caregiver, reviewCount: 0);
      expect(
        absent,
        containsAll(<MatchCriterion>[
          MatchCriterion.experience,
          MatchCriterion.references,
          MatchCriterion.feedback,
          MatchCriterion.certification,
        ]),
      );
    });
  });

  group('Stage 4 — S1 weight redistribution', () {
    test('weights sum to 1.0 when nothing is absent', () {
      final caregiver = _professionalCaregiver();
      final ctx = MatchContext(requestArgs: {'location': 'Negombo', 'careType': 'Elder care'});
      final result = MatchingService.score(
        caregiver: caregiver,
        context: ctx,
        avgRating: 4.5,
        reviewCount: 10,
      );
      final presentWeights = result.breakdown
          .where((row) => !row.structurallyAbsent)
          .map((row) => row.weight)
          .fold(0.0, (a, b) => a + b);
      expect(presentWeights, closeTo(1.0, 1e-9));
      expect(result.breakdown.every((row) => !row.structurallyAbsent), isTrue);
    });

    test('remaining weights rescale to 1.0 as absent criteria increase', () {
      final ctx = MatchContext(requestArgs: {'location': 'Negombo', 'careType': 'Elder care'});

      for (final caregiver in [
        _informalCaregiverMissingEverything()..['referencePhone'] = '+94770000000',
        _informalCaregiverMissingEverything(),
      ]) {
        final result = MatchingService.score(
          caregiver: caregiver,
          context: ctx,
          avgRating: 0,
          reviewCount: 0,
        );
        final presentWeights = result.breakdown
            .where((row) => !row.structurallyAbsent)
            .map((row) => row.weight)
            .fold(0.0, (a, b) => a + b);
        expect(presentWeights, closeTo(1.0, 1e-9),
            reason: 'rescaled weights must still sum to 1.0 for uid ${caregiver['uid']}');
      }
    });

    test('an absent criterion contributes zero points, not a zero-scored penalty', () {
      final caregiver = _informalCaregiverMissingEverything();
      final ctx = MatchContext(requestArgs: {'location': 'Negombo', 'careType': 'Elder care'});
      final result = MatchingService.score(
        caregiver: caregiver,
        context: ctx,
        avgRating: 0,
        reviewCount: 0,
      );
      final certRow =
          result.breakdown.firstWhere((row) => row.criterion == MatchCriterion.certification);
      expect(certRow.structurallyAbsent, isTrue);
      expect(certRow.rawValue, isNull);
      expect(certRow.contributionPoints, 0);
    });

    test('matchPercent matches a hand-computed value for a fully-scored caregiver', () {
      // All patient-conditional criteria forced to 1.0 by construction:
      // same district (proximity=1.0), Full-time caregiver covering a
      // Full-time request (availability=1.0), skills covering 'Elder care'
      // in full (skillMatch=1.0). Credential criteria: experience capped at
      // 10 years -> 6/10 = 0.6; references present -> 1.0; certified -> 1.0;
      // feedback 4.0/5.0 = 0.8.
      final caregiver = _professionalCaregiver(
        city: 'Negombo',
        careTypes: const ['Full-time'],
        yearsExperience: 6,
      );
      final ctx = MatchContext(
        requestArgs: {
          'location': 'Negombo',
          'careType': 'Elder care',
          'schedule': 'Full-time',
        },
      );
      final result = MatchingService.score(
        caregiver: caregiver,
        context: ctx,
        avgRating: 4.0,
        reviewCount: 5,
      );

      const expected = 0.1667 * 1.0 + // skillMatch
          0.1667 * 1.0 + // availability
          0.1667 * 1.0 + // proximity
          0.1685 * 0.8 + // feedback
          0.1629 * 1.0 + // references
          0.1461 * 0.6 + // experience
          0.0225 * 1.0; // certification
      expect(result.matchPercent, closeTo(expected * 100, 0.01));
    });
  });

  group('rankCaregivers', () {
    test('excludes ineligible caregivers and sorts the rest descending', () {
      final eligibleStrong = _professionalCaregiver(city: 'Negombo');
      final eligibleWeak = _informalCaregiverMissingEverything(city: 'Negombo');
      final ineligible = _professionalCaregiver(gender: 'Male')..['uid'] = 'wrong-gender';

      final ctx = MatchContext(
        patientProfile: {'preferredCaregiverGender': 'Female', 'city': 'Negombo'},
        requestArgs: {'careType': 'Elder care', 'schedule': 'Full-time'},
      );

      final ranked = MatchingService.rankCaregivers(
        caregivers: [ineligible, eligibleWeak, eligibleStrong],
        context: ctx,
        ratings: {
          'pro-1': (avg: 4.5, count: 8),
          'informal-1': (avg: 0.0, count: 0),
        },
      );

      expect(ranked.map((r) => r.caregiver['uid']), isNot(contains('wrong-gender')));
      expect(ranked.length, 2);
      expect(ranked.first.caregiver['uid'], 'pro-1');
      expect(ranked.first.matchPercent, greaterThanOrEqualTo(ranked.last.matchPercent));
    });
  });
}
