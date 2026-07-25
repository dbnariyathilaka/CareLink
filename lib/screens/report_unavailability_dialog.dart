import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'patient_notified_dialog.dart';

// ─────────────────────────────────────────────────────────────
//  "Report unavailability" dialog
//  Figma node: 498-7682 · shown when a caregiver taps "Can't
//  attend" on an on-duty / confirmed shift in the Schedule screen.
// ─────────────────────────────────────────────────────────────
Future<void> showReportUnavailabilityDialog(
  BuildContext context, {
  required String patientName,
  required String bookingDetail,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => ReportUnavailabilityDialog(
      patientName: patientName,
      bookingDetail: bookingDetail,
    ),
  );
}

class ReportUnavailabilityDialog extends StatefulWidget {
  final String patientName;
  final String bookingDetail;

  const ReportUnavailabilityDialog({
    super.key,
    required this.patientName,
    required this.bookingDetail,
  });

  @override
  State<ReportUnavailabilityDialog> createState() => _ReportUnavailabilityDialogState();
}

class _ReportUnavailabilityDialogState extends State<ReportUnavailabilityDialog> {
  static const Color _indigo = Color(0xFF6366F1);
  static const Color _indigoLight = Color(0xFF818CF8);
  static const Color _geyser = Color(0xFFCBD5E1);

  static const List<String> _reasons = [
    'Personal emergency',
    'Illness',
    'Transport issue',
    'Family emergency',
    'Double booked',
    'Other',
  ];
  String _reason = _reasons.first;

  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _showReasonPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _reasons.map((r) {
            final selected = r == _reason;
            return ListTile(
              title: Text(
                r,
                style: TextStyle(
                  color: selected ? _indigo : AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              trailing: selected ? const Icon(Icons.check_rounded, color: _indigo) : null,
              onTap: () {
                setState(() => _reason = r);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _notifyPatient() {
    Navigator.pop(context);
    showPatientNotifiedDialog(
      context,
      patientName: widget.patientName,
      bookingDetail: widget.bookingDetail,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 25),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.all(23),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: AppTheme.textPrimary, size: 24),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Report unavailability',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                border: Border.all(color: AppTheme.borderColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.patientName,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.bookingDetail,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _showReasonPicker,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _reason,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w400),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Note to patient (optional)',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                border: Border.all(color: AppTheme.borderColor),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _noteController,
                maxLines: 3,
                minLines: 3,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w400),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 17, vertical: 15),
                  hintText: "Let them know briefly what's happening...",
                  hintStyle: TextStyle(color: Color(0xFF757575), fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(
                color: _indigo.withValues(alpha: 0.1),
                border: Border.all(color: _indigo.withValues(alpha: 0.35)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_rounded, color: _indigoLight, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The patient and CareLink support will be notified immediately '
                      'so a replacement caregiver can be arranged.',
                      style: TextStyle(color: _geyser, fontSize: 11, fontWeight: FontWeight.w500, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.borderColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: _geyser, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Material(
                    color: _indigo,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _notifyPatient,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 13),
                        child: Text(
                          'Notify patient',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
