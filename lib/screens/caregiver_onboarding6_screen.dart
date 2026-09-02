import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data/sri_lanka_banks.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver Onboarding — Step 6 of 7
//  Figma node: 786-1535 · "Where should we send your earnings?"
//  Bank list + real branch codes: lib/data/sri_lanka_banks.dart (verified
//  against multiple independent sources — see that file's header comment
//  for what's cross-verified vs. single-sourced vs. deliberately excluded).
// ─────────────────────────────────────────────────────────────
class CaregiverOnboarding6Screen extends StatefulWidget {
  const CaregiverOnboarding6Screen({super.key});

  @override
  State<CaregiverOnboarding6Screen> createState() =>
      _CaregiverOnboarding6ScreenState();
}

class _CaregiverOnboarding6ScreenState
    extends State<CaregiverOnboarding6Screen> {
  static const Color bg = Color(0xFFF1F8E1);
  static const Color titleDark = Color(0xFF112541);
  static const Color stepLabel = Color(0xFF94A3B8);
  static const Color progressActive = Color(0xFF345058);
  static const Color progressInactive = Color.fromRGBO(137, 171, 199, 0.37);
  static const Color fieldLabel = Color(0xFF44331C);
  static const Color fieldBg = Color.fromRGBO(193, 179, 157, 0.18);
  static const Color fieldBorder = Color.fromRGBO(68, 51, 28, 0.34);
  static const Color fieldText = Color(0xFF2E2A1F);
  static const Color hintText = Color(0xFF64748B);
  static const Color noteBg = Color(0xFFDCF4E3);
  static const Color noteBorder = Color(0xFF8BC9A0);
  static const Color noteText = Color(0xFF1B5E2C);
  static const Color continueBg = Color(0xFF223A5C);
  static const Color skipBorder = Color(0xFFC56322);
  static const Color skipText = Color(0xFF8B5C27);

  SriLankanBank? _selectedBank;
  BankBranch? _selectedBranch;
  final TextEditingController _manualBranchController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _accountHolderController = TextEditingController();

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
    final draft = AppState.caregiverOnboardingDraft;
    if (draft.bankName.isNotEmpty) {
      _selectedBank = sriLankanBanks.where((b) => b.name == draft.bankName).firstOrNull;
    }
    if (_selectedBank != null && draft.branchName.isNotEmpty) {
      _selectedBranch = _selectedBank!.branches
          .where((b) => b.name == draft.branchName && b.code == draft.branchCode)
          .firstOrNull;
      if (_selectedBranch == null) _manualBranchController.text = draft.branchName;
    } else {
      _manualBranchController.text = draft.branchName;
    }
    _accountNumberController.text = draft.accountNumber;
    _accountHolderController.text = draft.accountHolderName;
  }

  @override
  void dispose() {
    _manualBranchController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  String _initialsFor(String name) {
    final cleaned = name.replaceAll(RegExp(r'[^A-Za-z ]'), ' ');
    final parts = cleaned.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  void _pickBank() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.75,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sriLankanBanks.length,
            itemBuilder: (_, i) {
              final bank = sriLankanBanks[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: continueBg,
                  child: Text(
                    _initialsFor(bank.name),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                title: Text(bank.name, style: const TextStyle(fontFamily: 'Open Sans', color: titleDark, fontSize: 14)),
                trailing: bank == _selectedBank ? const Icon(Icons.check_rounded, color: continueBg) : null,
                onTap: () {
                  setState(() {
                    _selectedBank = bank;
                    _selectedBranch = null;
                    _manualBranchController.clear();
                  });
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _pickBranch() {
    final bank = _selectedBank;
    if (bank == null || bank.branches.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.7,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: bank.branches.length,
            itemBuilder: (_, i) {
              final branch = bank.branches[i];
              return ListTile(
                title: Text('${branch.name} — ${branch.city}', style: const TextStyle(fontFamily: 'Open Sans', color: titleDark, fontSize: 14)),
                subtitle: Text('Branch code ${branch.code}', style: const TextStyle(fontFamily: 'Inter', color: hintText, fontSize: 11)),
                trailing: branch == _selectedBranch ? const Icon(Icons.check_rounded, color: continueBg) : null,
                onTap: () {
                  setState(() => _selectedBranch = branch);
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  String _maskAccountNumber(String number) {
    if (number.length <= 4) return number;
    final last4 = number.substring(number.length - 4);
    final maskedLength = number.length - 4;
    final groups = <String>[];
    for (var i = 0; i < maskedLength; i += 4) {
      final end = (i + 4 <= maskedLength) ? i + 4 : maskedLength;
      groups.add('•' * (end - i));
    }
    return '${groups.join(' ')} $last4';
  }

  void _saveAndContinue() {
    final bankName = _selectedBank?.name ?? '';
    final branchName = _selectedBranch?.name ?? _manualBranchController.text.trim();
    final accountNumber = _accountNumberController.text.trim();
    final accountHolder = _accountHolderController.text.trim();

    if (bankName.isEmpty || accountNumber.isEmpty || accountHolder.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fill in your bank details to save them, or tap "Skip for now" instead.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    _showPayoutAddedPopup(
      bankName: bankName,
      branchName: branchName,
      accountNumber: accountNumber,
      accountHolder: accountHolder,
    );
  }

  // Figma node 786:1743 — confirms what was just entered (masking the
  // account number down to its last 4 digits) before it's actually saved.
  // "Edit bank details" just dismisses this and returns to the form;
  // "Continue" is what actually commits the draft and advances the wizard.
  void _showPayoutAddedPopup({
    required String bankName,
    required String branchName,
    required String accountNumber,
    required String accountHolder,
  }) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (dialogCtx) => Dialog(
        backgroundColor: bg,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(color: fieldBorder, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Icon(Icons.account_balance_rounded, color: skipText, size: 34),
              ),
              const SizedBox(height: 16),
              const Text(
                'Payout account added',
                style: TextStyle(fontFamily: 'Open Sans', color: titleDark, fontSize: 19, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                "We'll verify the account with a small test deposit within one working day.",
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Open Sans', color: stepLabel, fontSize: 12, fontWeight: FontWeight.w500, height: 1.4),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(color: continueBg, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    _buildSummaryRow('Bank name', bankName),
                    if (branchName.isNotEmpty) _buildSummaryRow('Branch', branchName),
                    _buildSummaryRow('Account number', _maskAccountNumber(accountNumber)),
                    _buildSummaryRow('Account holder', accountHolder, isLast: true),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: fieldBg, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.schedule_rounded, color: skipText, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Verification pending — your first payout will be released once the test deposit is confirmed.',
                        style: TextStyle(fontFamily: 'Inter', color: skipText, fontSize: 11, fontWeight: FontWeight.w500, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: titleDark,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      Navigator.pop(dialogCtx);
                      _commitAndContinue();
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      child: Text(
                        'Continue',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'Inter', color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: continueBg, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'Edit bank details',
                    style: TextStyle(fontFamily: 'Inter', color: titleDark, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0x22FFFFFF))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Open Sans', color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFFFBBC05), fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _commitAndContinue() {
    final draft = AppState.caregiverOnboardingDraft;
    draft.bankName = _selectedBank?.name ?? '';
    draft.bankCode = _selectedBank?.code ?? '';
    draft.branchName = _selectedBranch?.name ?? _manualBranchController.text.trim();
    draft.branchCode = _selectedBranch?.code ?? '';
    draft.accountNumber = _accountNumberController.text.trim();
    draft.accountHolderName = _accountHolderController.text.trim();
    Navigator.pushNamed(context, '/caregiver-onboarding-7');
  }

  void _skip() {
    Navigator.pushNamed(context, '/caregiver-onboarding-7');
  }

  @override
  Widget build(BuildContext context) {
    final hasCuratedBranches = (_selectedBank?.branches.isNotEmpty) ?? false;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: titleDark, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                  const Text(
                    'Step 6 of 7',
                    style: TextStyle(fontFamily: 'Open Sans', color: stepLabel, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildProgressBar(currentStep: 6, totalSteps: 7),
              const SizedBox(height: 24),
              const Text(
                'Where should we send your earnings?',
                style: TextStyle(fontFamily: 'Open Sans', color: titleDark, fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 7),
              const Text(
                'Payouts run every Friday to this account.',
                style: TextStyle(fontFamily: 'Open Sans', color: stepLabel, fontSize: 13, fontWeight: FontWeight.w400, height: 1.5),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildFieldLabel('Bank name'),
                      const SizedBox(height: 6),
                      _buildDropdownField(
                        value: _selectedBank?.name,
                        hint: 'Select your bank',
                        onTap: _pickBank,
                      ),
                      const SizedBox(height: 16),
                      _buildFieldLabel('Branch'),
                      const SizedBox(height: 6),
                      if (hasCuratedBranches)
                        _buildDropdownField(
                          value: _selectedBranch != null ? '${_selectedBranch!.name} — ${_selectedBranch!.city} (${_selectedBranch!.code})' : null,
                          hint: 'Select your branch',
                          onTap: _pickBranch,
                          enabled: _selectedBank != null,
                        )
                      else
                        _buildTextField(
                          controller: _manualBranchController,
                          hint: _selectedBank == null ? 'Select a bank first' : 'e.g. Colombo Main Branch',
                          enabled: _selectedBank != null,
                        ),
                      if (_selectedBank != null && !hasCuratedBranches) ...[
                        const SizedBox(height: 4),
                        const Text(
                          "We don't have a verified branch list for this bank yet — enter it manually.",
                          style: TextStyle(fontFamily: 'Inter', color: hintText, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _buildFieldLabel('Account number'),
                      const SizedBox(height: 6),
                      _buildTextField(
                        controller: _accountNumberController,
                        hint: '8842 1170 4471',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Numbers only, no spaces or dashes',
                        style: TextStyle(fontFamily: 'Inter', color: hintText, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 16),
                      _buildFieldLabel("Account holder's name"),
                      const SizedBox(height: 6),
                      _buildTextField(
                        controller: _accountHolderController,
                        hint: 'A. M. Fernando',
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: noteBg,
                          border: Border.all(color: noteBorder),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.lock_outline_rounded, color: noteText, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Your bank details are encrypted and never shared with patients or families.',
                                style: TextStyle(fontFamily: 'Inter', color: noteText, fontSize: 11, fontWeight: FontWeight.w500, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Material(
                        color: continueBg,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: _saveAndContinue,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 15),
                            child: Text(
                              'Save & finish setup',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontFamily: 'Inter', color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _skip,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: skipBorder, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text(
                          'Skip for now',
                          style: TextStyle(fontFamily: 'Inter', color: skipText, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontFamily: 'Open Sans', color: fieldLabel, fontSize: 12, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String hint,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: fieldBg,
          border: Border.all(color: fieldBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? hint,
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: value != null ? fieldText : hintText,
                  fontSize: 13,
                  fontWeight: value != null ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: enabled ? fieldText : hintText, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: TextStyle(
        fontFamily: 'Open Sans',
        color: enabled ? fieldText : hintText,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'Open Sans',
          color: hintText,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: fieldBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: fieldBorder, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: fieldBorder.withValues(alpha: 0.5)),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: fieldBorder),
        ),
      ),
    );
  }

  /// Progress bar with segmented steps
  Widget _buildProgressBar({required int currentStep, required int totalSteps}) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isActive = index < currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < totalSteps - 1 ? 6 : 0),
            height: 5,
            decoration: BoxDecoration(
              color: isActive ? progressActive : progressInactive,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}
