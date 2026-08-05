import 'package:flutter/material.dart';
import '../services/booking_service.dart';
import 'patient_notified_dialog.dart';

// ─────────────────────────────────────────────────────────────
//  "Report unavailability" dialog  (Caregiver — "Can't attend")
//  Figma node: 355-2780 · shown from the caregiver's Upcoming
//  schedule when marking a confirmed/on-duty shift as one they
//  can't attend.
//
//  Figma's copy claims "The patient and CareLink support will be
//  notified immediately so a replacement caregiver can be
//  arranged" — there's no notification pipeline or support-ticket
//  system anywhere in this app, so that's rewritten below to
//  describe what actually happens: the reason/note are saved to
//  the booking (BookingService.reportCantAttend) and shown on the
//  caregiver's own schedule. Nothing is sent to the patient.
// ─────────────────────────────────────────────────────────────
const _reasons = [
  'Personal emergency',
  'Illness',
  'Family emergency',
  'Transportation issue',
  'Scheduling conflict',
  'Other',
];

Future<bool> showReportUnavailabilityDialog(
  BuildContext context, {
  required String bookingId,
  required String patientName,
  required String careType,
  required String schedule,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ReportUnavailabilityDialog(
      bookingId: bookingId,
      patientName: patientName,
      careType: careType,
      schedule: schedule,
    ),
  );
  return result ?? false;
}

class ReportUnavailabilityDialog extends StatefulWidget {
  const ReportUnavailabilityDialog({
    super.key,
    required this.bookingId,
    required this.patientName,
    required this.careType,
    required this.schedule,
  });

  final String bookingId;
  final String patientName;
  final String careType;
  final String schedule;

  @override
  State<ReportUnavailabilityDialog> createState() => _ReportUnavailabilityDialogState();
}

class _ReportUnavailabilityDialogState extends State<ReportUnavailabilityDialog> {
  static const Color _titleDark = Color(0xFF202833);
  static const Color _fieldBg = Color(0xFF4E4533);
  static const Color _fieldBorder = Color(0xFF334155);
  static const Color _fieldText = Color(0xFFF8FAFC);
  static const Color _fieldLabel = Color(0xFF94A3B8);
  static const Color _placeholder = Color(0xFFB6A480);
  static const Color _chevron = Color(0xFFC3BFB9);
  static const Color _infoBg = Color(0xFFCFD0CB);
  static const Color _infoIcon = Color(0xFF9C7400);
  static const Color _infoText = Color(0xFF444935);
  static const Color _accent = Color(0xFF904707);

  final TextEditingController _noteController = TextEditingController();
  String _reason = _reasons.first;
  bool _submitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _pickReason() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _reasons.map((reason) {
            final selected = reason == _reason;
            return ListTile(
              title: Text(
                reason,
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: selected ? _accent : _titleDark,
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              trailing: selected ? const Icon(Icons.check_rounded, color: _accent) : null,
              onTap: () {
                setState(() => _reason = reason);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await BookingService.reportCantAttend(
        widget.bookingId,
        reason: _reason,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      showPatientNotifiedDialog(
        context,
        patientName: widget.patientName,
        schedule: widget.schedule,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit report: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 25),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 20)),
          ],
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report unavailability',
              style: TextStyle(fontFamily: 'Open Sans', color: _titleDark, fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _fieldBg, border: Border.all(color: _fieldBorder), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.patientName, style: const TextStyle(fontFamily: 'Open Sans', color: _fieldText, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(
                    '${widget.careType} · ${widget.schedule}',
                    style: const TextStyle(fontFamily: 'Open Sans', color: _fieldLabel, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _pickReason,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
                decoration: BoxDecoration(color: _fieldBg, border: Border.all(color: _fieldBorder), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(_reason, style: const TextStyle(fontFamily: 'Open Sans', color: _fieldText, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    const Icon(Icons.expand_more_rounded, color: _chevron, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Note to patient (optional)',
              style: TextStyle(fontFamily: 'Open Sans', color: _fieldLabel, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
              decoration: BoxDecoration(color: _fieldBg, border: Border.all(color: _fieldBorder), borderRadius: BorderRadius.circular(10)),
              child: TextField(
                controller: _noteController,
                maxLines: null,
                expands: true,
                style: const TextStyle(fontFamily: 'Open Sans', color: _fieldText, fontSize: 13, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  isDense: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: "Let them know briefly what's happening...",
                  hintStyle: TextStyle(fontFamily: 'Open Sans', color: _placeholder, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: _infoBg, borderRadius: BorderRadius.circular(10)),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_rounded, color: _infoIcon, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "This is saved to your schedule so there's a record of it. CareLink doesn't send the patient an automatic notification — message or call them directly if the shift is soon.",
                      style: TextStyle(fontFamily: 'Inter', color: _infoText, fontSize: 11, fontWeight: FontWeight.w500, height: 1.5),
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
                    onPressed: _submitting ? null : () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _accent),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontFamily: 'Open Sans', color: _accent, fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Material(
                    color: _accent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _submitting ? null : _submit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        child: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text(
                                'Submit report',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontFamily: 'Open Sans', color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
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
