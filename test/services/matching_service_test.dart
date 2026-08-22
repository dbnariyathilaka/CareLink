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
  String educationalQualification = 'Degree or higher',
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
    'educationalQualification': educationalQualification,
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
    'educationalQualification': 'Secondary',
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

  group('Stage 1 — eligibility (advanced-match flow only)', () {
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
    test('a professional caregiver is never flagged, even with missing experience', () {
      final caregiver = _professionalCaregiver()..['yearsExperience'] = null;
      final absent = MatchingService.structurallyAbsentCriteria(caregiver);
      expect(absent, isEmpty);
    });

    test('an informal caregiver with experience on file is not flagged for it', () {
      final caregiver = _informalCaregiverMissingEverything()..['yearsExperience'] = 3;
      final absent = MatchingService.structurallyAbsentCriteria(caregiver);
      expect(absent, isNot(contains(MatchCriterion.experience)));
      // Certification is definitionally tied to isProfessional() — see the
      // doc comment on MatchingService.isProfessional — so it's still
      // flagged for an informal caregiver even when other fields are filled.
      expect(absent, contains(MatchCriterion.certification));
    });

    test('an informal caregiver with no experience on file is flagged for both', () {
      final caregiver = _informalCaregiverMissingEverything();
      final absent = MatchingService.structurallyAbsentCriteria(caregiver);
      expect(
        absent,
        containsAll(<MatchCriterion>[MatchCriterion.experience, MatchCriterion.certification]),
      );
    });
  });

  group('MatchProfile.onboardingPreview (dashboard)', () {
    test('scores only the 4 onboarding-sourced criteria, equally weighted', () {
      final caregiver = _professionalCaregiver(city: 'Negombo', careTypes: const ['Full-time']);
      final ctx = MatchContext(
        patientProfile: {
          'city': 'Negombo',
          'careType': 'Elder care',
          'careLevel': 'Full-time',
          'preferredCaregiverGender': 'Female',
        },
      );
      final result = MatchingService.score(
        caregiver: caregiver,
        context: ctx,
        profile: MatchProfile.onboardingPreview,
      );

      expect(result.breakdown.length, 4);
      expect(
        result.breakdown.map((r) => r.criterion).toSet(),
        {
          MatchCriterion.skillMatch,
          MatchCriterion.genderMatch,
          MatchCriterion.proximity,
          MatchCriterion.availability,
        },
      );
      // Every criterion should be a perfect match by construction (same
      // city, matching gender, Full-time caregiver covering a Full-time
      // request, skills covering 'Elder care' in full).
      expect(result.matchPercent, closeTo(100, 0.01));
    });

    test('has no eligibility gate — a wrong-gender caregiver still gets scored, just lower', () {
      final caregiver = _professionalCaregiver(gender: 'Male');
      final ctx = MatchContext(
        patientProfile: {'city': 'Negombo', 'preferredCaregiverGender': 'Female'},
      );
      final result = MatchingService.score(
        caregiver: caregiver,
        context: ctx,
        profile: MatchProfile.onboardingPreview,
      );
      final genderRow =
          result.breakdown.firstWhere((r) => r.criterion == MatchCriterion.genderMatch);
      expect(genderRow.rawValue, 0.0);
      expect(result.matchPercent, lessThan(100));
    });
  });

  group('MatchProfile.advanced — S1 weight redistribution', () {
    test('weights sum to 1.0 when nothing is absent', () {
      final caregiver = _professionalCaregiver();
      final ctx = MatchContext(requestArgs: {'location': 'Negombo', 'careType': 'Elder care'});
      final result = MatchingService.score(
        caregiver: caregiver,
        context: ctx,
        profile: MatchProfile.advanced,
      );
      final presentWeights = result.breakdown
          .where((row) => !row.structurallyAbsent)
          .map((row) => row.weight)
          .fold(0.0, (a, b) => a + b);
      expect(presentWeights, closeTo(1.0, 1e-9));
      expect(result.breakdown.every((row) => !row.structurallyAbsent), isTrue);
      expect(result.breakdown.length, MatchProfile.advanced.criteria.length);
    });

    test('remaining weights rescale to 1.0 as absent criteria increase', () {
      final ctx = MatchContext(requestArgs: {'location': 'Negombo', 'careType': 'Elder care'});

      for (final caregiver in [
        _informalCaregiverMissingEverything()..['yearsExperience'] = 3,
        _informalCaregiverMissingEverything(),
      ]) {
        final result = MatchingService.score(
          caregiver: caregiver,
          context: ctx,
          profile: MatchProfile.advanced,
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
        profile: MatchProfile.advanced,
      );
      final certRow =
          result.breakdown.firstWhere((row) => row.criterion == MatchCriterion.certification);
      expect(certRow.structurallyAbsent, isTrue);
      expect(certRow.rawValue, isNull);
      expect(certRow.contributionPoints, 0);
    });

    test('matchPercent matches a hand-computed value for a fully-scored caregiver', () {
      // All 8 advanced-profile criteria forced to 1.0 by construction:
      // same district (proximity), Full-time caregiver covering a
      // Full-time request (availability), skills covering 'Elder care' in
      // full (skillMatch), matching gender (genderMatch), matching
      // language (languageMatch), 'Degree or higher' education (1.0),
      // certified (certification=1.0) — except experience, capped at 10
      // years -> 6/10 = 0.6.
      final caregiver = _professionalCaregiver(
        city: 'Negombo',
        careTypes: const ['Full-time'],
        yearsExperience: 6,
        languagesSpoken: const ['Sinhala'],
      );
      final ctx = MatchContext(
        patientProfile: {'preferredCaregiverGender': 'Female'},
        requestArgs: {
          'location': 'Negombo',
          'careType': 'Elder care',
          'schedule': 'Full-time',
          'languages': ['Sinhala'],
        },
      );
      final result = MatchingService.score(
        caregiver: caregiver,
        context: ctx,
        profile: MatchProfile.advanced,
      );

      const n = 8; // MatchProfile.advanced.criteria.length
      const expected = (1.0 + 1.0 + 1.0 + 1.0 + 1.0 + 1.0 + 0.6 + 1.0) / n;
      // skillMatch + genderMatch + proximity + availability + education
      // + certification + experience(0.6) + languageMatch, in some order.
      expect(result.matchPercent, closeTo(expected * 100, 0.01));
    });
  });

  group('rankCaregivers', () {
    test('sorts descending and applies no eligibility gate of its own', () {
      final strong = _professionalCaregiver(city: 'Negombo');
      final weak = _informalCaregiverMissingEverything(city: 'Negombo')
        ..['gender'] = 'Male';

      final ctx = MatchContext(
        patientProfile: {'preferredCaregiverGender': 'Female', 'city': 'Negombo'},
        requestArgs: {'careType': 'Elder care', 'schedule': 'Full-time'},
      );

      final ranked = MatchingService.rankCaregivers(
        caregivers: [weak, strong],
        context: ctx,
        profile: MatchProfile.advanced,
      );

      // Both caregivers are present — rankCaregivers itself never filters;
      // that's the caller's job via isEligible (see advanced_match_results_screen.dart).
      expect(ranked.length, 2);
      expect(ranked.first.caregiver['uid'], 'pro-1');
      expect(ranked.first.matchPercent, greaterThanOrEqualTo(ranked.last.matchPercent));
    });

    test('isEligible + rankCaregivers together exclude an ineligible caregiver', () {
      final eligible = _professionalCaregiver(city: 'Negombo');
      final ineligible = _professionalCaregiver(gender: 'Male')..['uid'] = 'wrong-gender';

      final ctx = MatchContext(
        patientProfile: {'preferredCaregiverGender': 'Female', 'city': 'Negombo'},
        requestArgs: {'careType': 'Elder care', 'schedule': 'Full-time'},
      );

      final pool = [eligible, ineligible];
      final filtered = pool.where((c) => MatchingService.isEligible(c, ctx)).toList();
      final ranked = MatchingService.rankCaregivers(
        caregivers: filtered,
        context: ctx,
        profile: MatchProfile.advanced,
      );

      expect(ranked.map((r) => r.caregiver['uid']), isNot(contains('wrong-gender')));
      expect(ranked.length, 1);
    });
  });
}
