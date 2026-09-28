// ─────────────────────────────────────────────────────────────────────────
//  NicVerificationService — automatic Sri Lankan NIC verification. A NIC
//  number encodes birth year and a day-of-year code (offset by 500 for
//  female) directly in its digits, so a caregiver's claimed age and gender
//  can be checked against their own NIC with pure arithmetic — no admin,
//  no external registry lookup.
//
//  Supports both formats:
//    - Old: 9 digits + V/X  (e.g. 972345678V) — 2-digit birth year.
//    - New: 12 digits       (e.g. 199723456789) — 4-digit birth year.
//
//  Pure logic only, same convention as matching_service.dart — no Firestore
//  or Flutter imports, so it's trivially unit-testable and reusable from
//  onboarding, edit-profile, and the admin backfill migration alike.
// ─────────────────────────────────────────────────────────────────────────

class NicCheckResult {
  const NicCheckResult({
    required this.isValid,
    this.reason,
    this.extractedBirthYear,
    this.extractedGender,
  });

  final bool isValid;

  /// Human-readable, caregiver-facing reason the check failed. Null when
  /// [isValid] is true.
  final String? reason;

  /// Full birth year read off the NIC — only known for the 12-digit format;
  /// the 9-digit format only stores 2 digits, so the century is ambiguous
  /// and this is left null rather than guessed.
  final int? extractedBirthYear;

  /// 'Male' or 'Female' — always known once the NIC matches a recognised
  /// format, since both formats encode it in the day-of-year field.
  final String? extractedGender;

  const NicCheckResult.unrecognizedFormat()
      : isValid = false,
        reason = 'Unrecognized NIC format',
        extractedBirthYear = null,
        extractedGender = null;
}

class NicVerificationService {
  NicVerificationService._();

  static final RegExp _oldFormat = RegExp(r'^(\d{2})(\d{3})\d{4}[VX]$');
  static final RegExp _newFormat = RegExp(r'^(\d{4})(\d{3})\d{5}$');

  /// Checks [nic] against [gender] ('Male' | 'Female' | 'Other') and,
  /// optionally, [age] in whole years as of today.
  ///
  /// [age] is nullable to support the one-time backfill over caregivers who
  /// onboarded before this app collected an age — for them, only NIC
  /// format + gender can be honestly cross-checked (there's no age on file
  /// to compare a birth year against), so the birth-year check is skipped
  /// rather than fabricating an age to compare against.
  static NicCheckResult check({
    required String nic,
    required String gender,
    int? age,
  }) {
    final trimmed = nic.trim().toUpperCase();
    final oldMatch = _oldFormat.firstMatch(trimmed);
    final newMatch = _newFormat.firstMatch(trimmed);
    final match = oldMatch ?? newMatch;
    if (match == null) {
      return const NicCheckResult.unrecognizedFormat();
    }
    final isOldFormat = oldMatch != null;

    final yearPart = int.parse(match.group(1)!); // 2-digit or 4-digit
    final dayCode = int.parse(match.group(2)!);

    // Day-of-year code: 1-366 male, 501-866 female (866 = 500+366, leap-year
    // safe). Anything outside both ranges means the digits don't form a
    // real NIC, regardless of the regex having matched the digit pattern.
    final isFemaleCode = dayCode >= 501 && dayCode <= 866;
    final isMaleCode = dayCode >= 1 && dayCode <= 366;
    if (!isFemaleCode && !isMaleCode) {
      return const NicCheckResult(isValid: false, reason: 'Invalid NIC number');
    }
    final extractedGender = isFemaleCode ? 'Female' : 'Male';

    // NIC only ever encodes male/female. A caregiver who selected "Other"
    // has nothing in the NIC to compare against for this half of the check,
    // so it's skipped for them rather than auto-failing on an
    // unrepresentable case.
    if ((gender == 'Male' || gender == 'Female') && gender != extractedGender) {
      return NicCheckResult(
        isValid: false,
        reason: 'Gender does not match NIC',
        extractedGender: extractedGender,
      );
    }

    if (age == null) {
      return NicCheckResult(isValid: true, extractedGender: extractedGender);
    }

    final expectedBirthYear = DateTime.now().year - age;
    if (isOldFormat) {
      // Only 2 digits of the year are stored — compare the last two digits
      // of the expected birth year instead of guessing a century. ±1 year
      // slack covers a birthday that hasn't happened yet this calendar
      // year, since "age" alone carries no birth-month precision.
      final matches = [-1, 0, 1].any((delta) => (expectedBirthYear + delta) % 100 == yearPart);
      if (!matches) {
        return NicCheckResult(
          isValid: false,
          reason: 'Birth year does not match NIC',
          extractedGender: extractedGender,
        );
      }
      return NicCheckResult(isValid: true, extractedGender: extractedGender);
    }

    if ((yearPart - expectedBirthYear).abs() > 1) {
      return NicCheckResult(
        isValid: false,
        reason: 'Birth year does not match NIC',
        extractedBirthYear: yearPart,
        extractedGender: extractedGender,
      );
    }
    return NicCheckResult(
      isValid: true,
      extractedBirthYear: yearPart,
      extractedGender: extractedGender,
    );
  }
}
