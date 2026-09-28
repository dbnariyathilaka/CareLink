import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/services/nic_verification_service.dart';

void main() {
  final currentYear = DateTime.now().year;

  // Fixed reference birth year (1995), day-of-year 74 (15 March, non-leap).
  // Age is derived from `currentYear` rather than hardcoded so this test
  // doesn't rot as calendar years pass.
  const birthYear = 1995;
  const dayOfYear = '074'; // male
  const dayOfYearFemale = '574'; // 074 + 500
  final age = currentYear - birthYear;

  final oldMale = '95${dayOfYear}1234V';
  final oldFemale = '95${dayOfYearFemale}1234V';
  final newMale = '1995${dayOfYear}12345';
  final newFemale = '1995${dayOfYearFemale}12345';

  group('format recognition', () {
    test('rejects an unrecognized format', () {
      final result = NicVerificationService.check(nic: '12345', gender: 'Male', age: age);
      expect(result.isValid, isFalse);
      expect(result.reason, 'Unrecognized NIC format');
    });

    test('rejects an out-of-range day-of-year code', () {
      // 999 is neither 1-366 (male) nor 501-866 (female).
      final result = NicVerificationService.check(nic: '959991234V', gender: 'Male', age: age);
      expect(result.isValid, isFalse);
      expect(result.reason, 'Invalid NIC number');
    });
  });

  group('old format (9 digits + V/X)', () {
    test('verifies a matching male NIC', () {
      final result = NicVerificationService.check(nic: oldMale, gender: 'Male', age: age);
      expect(result.isValid, isTrue);
      expect(result.extractedGender, 'Male');
    });

    test('verifies a matching female NIC', () {
      final result = NicVerificationService.check(nic: oldFemale, gender: 'Female', age: age);
      expect(result.isValid, isTrue);
      expect(result.extractedGender, 'Female');
    });

    test('accepts lowercase v', () {
      final lower = oldMale.substring(0, 9) + oldMale.substring(9).toLowerCase();
      final result = NicVerificationService.check(nic: lower, gender: 'Male', age: age);
      expect(result.isValid, isTrue);
    });

    test('fails when gender does not match the NIC-encoded gender', () {
      final result = NicVerificationService.check(nic: oldMale, gender: 'Female', age: age);
      expect(result.isValid, isFalse);
      expect(result.reason, 'Gender does not match NIC');
    });

    test('fails when the claimed age implies a different birth year', () {
      final result = NicVerificationService.check(nic: oldMale, gender: 'Male', age: age + 10);
      expect(result.isValid, isFalse);
      expect(result.reason, 'Birth year does not match NIC');
    });

    test('tolerates a 1-year age discrepancy (birthday not yet occurred this year)', () {
      final result = NicVerificationService.check(nic: oldMale, gender: 'Male', age: age + 1);
      expect(result.isValid, isTrue);
    });

    test('century is not guessed — only the last two digits are compared', () {
      // Same last-two-digits (95) but a claimed age 100 years off from the
      // literal 1995 assumption still matches, since the old format only
      // ever stores 2 digits and there is no way to know the century.
      final result = NicVerificationService.check(nic: oldMale, gender: 'Male', age: age - 100);
      expect(result.isValid, isTrue);
    });
  });

  group('new format (12 digits)', () {
    test('verifies a matching male NIC', () {
      final result = NicVerificationService.check(nic: newMale, gender: 'Male', age: age);
      expect(result.isValid, isTrue);
      expect(result.extractedBirthYear, birthYear);
    });

    test('verifies a matching female NIC', () {
      final result = NicVerificationService.check(nic: newFemale, gender: 'Female', age: age);
      expect(result.isValid, isTrue);
      expect(result.extractedBirthYear, birthYear);
    });

    test('fails when the full birth year does not match', () {
      final result = NicVerificationService.check(nic: newMale, gender: 'Male', age: age + 10);
      expect(result.isValid, isFalse);
      expect(result.reason, 'Birth year does not match NIC');
    });
  });

  group('"Other" gender', () {
    test('skips the gender check (NIC cannot represent it) but still checks birth year', () {
      final result = NicVerificationService.check(nic: newMale, gender: 'Other', age: age);
      expect(result.isValid, isTrue);
    });

    test('still fails on a birth-year mismatch', () {
      final result = NicVerificationService.check(nic: newMale, gender: 'Other', age: age + 10);
      expect(result.isValid, isFalse);
    });
  });

  group('legacy backfill (age unknown)', () {
    test('verifies on format + gender alone when age is not supplied', () {
      final result = NicVerificationService.check(nic: newMale, gender: 'Male');
      expect(result.isValid, isTrue);
    });

    test('still fails a gender mismatch with no age supplied', () {
      final result = NicVerificationService.check(nic: newMale, gender: 'Female');
      expect(result.isValid, isFalse);
      expect(result.reason, 'Gender does not match NIC');
    });
  });
}
