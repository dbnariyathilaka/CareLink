import 'package:flutter/material.dart';
import '../services/care_journal_service.dart';
import '../services/storage_service.dart';
import '../widgets/no_underline_text_editing_controller.dart';
import '../widgets/upload_picker_sheet.dart';

// ─────────────────────────────────────────────────────────────
//  "Add entry" bottom sheet  (Care journal)
//  Figma node: 355-3351
//  Real: category, freeform note, real photo upload (Cloudinary,
//  same picker/upload path as everywhere else in the app), an
//  editable occurred-at time, and a real "flag as important" bit
//  that highlights the entry on the timeline.
//  Not real: voice dictation (mic button) — shows the same
//  "isn't available yet" honesty pattern used for mic/attach
//  buttons elsewhere in the app, since there's no speech-to-text
//  backend. "Alerts admin for review" from Figma's flag-toggle
//  copy is dropped too — there's no admin review queue, so the
//  flag is described by what it actually does: highlight the
//  entry here.
// ─────────────────────────────────────────────────────────────
const _categories = ['General', 'Meal', 'Medication', 'Hygiene', 'Vitals', 'Incident'];

Future<bool> showAddJournalEntrySheet(
  BuildContext context, {
  required String patientUid,
  required String authorUid,
  required String authorName,
  required bool offline,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddJournalEntrySheet(
      patientUid: patientUid,
      authorUid: authorUid,
      authorName: authorName,
      offline: offline,
    ),
  );
  return result ?? false;
}

class AddJournalEntrySheet extends StatefulWidget {
  const AddJournalEntrySheet({
    super.key,
    required this.patientUid,
    required this.authorUid,
    required this.authorName,
    required this.offline,
  });

  final String patientUid;
  final String authorUid;
  final String authorName;
  final bool offline;

  @override
  State<AddJournalEntrySheet> createState() => _AddJournalEntrySheetState();
}

class _AddJournalEntrySheetState extends State<AddJournalEntrySheet> {
  static const Color _sheetBg = Color(0xFF4E3B30);
  static const Color _handle = Color(0xFFDEBEAB);
  static const Color _labelTeal = Color(0xFF5B7B80);
  static const Color _editTeal = Color(0xFF0D9488);
  static const Color _fieldBg = Color(0xFFD9D5CA);
  static const Color _fieldBorder = Color(0xFFE2ECEE);
  static const Color _fieldText = Color(0xFF4A4129);
  static const Color _chipSelectedBg = Color(0xFF76675D);
  static const Color _saveBg = Color(0xFFC4B1A6);
  static const Color _saveText = Color(0xFF4E3B30);

  String _category = _categories.first;
  TimeOfDay _time = TimeOfDay.now();
  final TextEditingController _textController = NoUnderlineTextEditingController();
  String? _photoUrl;
  String? _photoName;
  bool _uploadingPhoto = false;
  bool _flagged = false;
  bool _saving = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  void _notAvailableYet(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature isn\'t available yet.')),
    );
  }

  Future<void> _attachPhoto() async {
    final picked = await pickImageOrDocument(context, allowPdf: false);
    if (picked == null || !mounted) return;
    setState(() => _uploadingPhoto = true);
    try {
      final url = await StorageService.uploadBytes(
        storagePath: StorageService.careJournalPhotoPath(widget.patientUid, picked.name),
        bytes: picked.bytes,
        contentType: picked.mimeType,
      );
      if (!mounted) return;
      setState(() {
        _photoUrl = url;
        _photoName = picked.name;
        _uploadingPhoto = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not upload photo. Please try again.')),
      );
    }
  }

  Future<void> _save() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write a note before saving.')),
      );
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    try {
      await CareJournalService.addEntry(
        patientUid: widget.patientUid,
        authorUid: widget.authorUid,
        authorName: widget.authorName,
        category: _category.toLowerCase(),
        text: text,
        photoUrl: _photoUrl,
        flagged: _category == 'Incident' || _flagged,
        occurredAt: DateTime(now.year, now.month, now.day, _time.hour, _time.minute),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save entry: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: _sheetBg,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(22), topRight: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 26),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 36, height: 4, decoration: BoxDecoration(color: _handle, borderRadius: BorderRadius.circular(999))),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Add entry', style: TextStyle(fontFamily: 'Open Sans', color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: const Icon(Icons.close_rounded, color: _handle, size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('Category', style: TextStyle(fontFamily: 'Open Sans', color: _labelTeal, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((c) {
                    final selected = c == _category;
                    return GestureDetector(
                      onTap: () => setState(() => _category = c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                        decoration: BoxDecoration(
                          color: selected ? _chipSelectedBg : Colors.transparent,
                          border: Border.all(color: selected ? const Color.fromRGBO(222, 190, 171, 0.63) : _handle),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(c, style: TextStyle(fontFamily: 'Open Sans', color: selected ? Colors.white : _handle, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text('Time', style: TextStyle(fontFamily: 'Open Sans', color: _labelTeal, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _pickTime,
                      child: Text('${_formatTime(_time)} · Edit', style: const TextStyle(fontFamily: 'Open Sans', color: _editTeal, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 90),
                  padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
                  decoration: BoxDecoration(color: _fieldBg, border: Border.all(color: _fieldBorder), borderRadius: BorderRadius.circular(10)),
                  child: Stack(
                    children: [
                      TextField(
                        controller: _textController,
                        maxLines: null,
                        minLines: 3,
                        style: const TextStyle(fontFamily: 'Open Sans', color: Color(0xFF2E271A), fontSize: 13, fontWeight: FontWeight.w400),
                        decoration: const InputDecoration(
                          isDense: true,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.only(right: 36, bottom: 24),
                          hintText: 'What happened during this part of the visit?',
                          hintStyle: TextStyle(fontFamily: 'Open Sans', color: Color.fromRGBO(74, 65, 41, 0.5), fontSize: 11, fontWeight: FontWeight.w400),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: () => _notAvailableYet('Voice notes'),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: const Color(0xFFBDB7A6), borderRadius: BorderRadius.circular(16)),
                            child: const Icon(Icons.mic_rounded, color: _sheetBg, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: _uploadingPhoto ? null : _attachPhoto,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _fieldBg,
                      border: Border.all(color: const Color(0xFF44331C)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        if (_uploadingPhoto)
                          const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF44331C)))
                        else
                          Icon(_photoUrl != null ? Icons.check_circle_rounded : Icons.add_a_photo_rounded, color: const Color(0xFF44331C), size: 19),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _photoUrl != null ? _photoName ?? 'Photo attached' : 'Attach a photo',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontFamily: 'Open Sans', color: _fieldText, fontSize: 12, fontWeight: FontWeight.w400),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(color: _fieldBg, border: Border.all(color: _fieldBorder), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Flag as important', style: TextStyle(fontFamily: 'Open Sans', color: _fieldText, fontSize: 12, fontWeight: FontWeight.w400)),
                            SizedBox(height: 2),
                            Text('Highlights this entry on the timeline', style: TextStyle(fontFamily: 'Open Sans', color: _fieldText, fontSize: 12, fontWeight: FontWeight.w400)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _category == 'Incident' || _flagged,
                        onChanged: _category == 'Incident' ? null : (v) => setState(() => _flagged = v),
                        activeThumbColor: const Color(0xFF44331C),
                        activeTrackColor: const Color(0xFF6C634C),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _saving ? null : _save,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(color: _saveBg, borderRadius: BorderRadius.circular(10)),
                    child: _saving
                        ? const Center(
                            child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: _saveText)),
                          )
                        : const Text('Save as draft', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Open Sans', color: _saveText, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
                if (widget.offline) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Offline — will sync when back online',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Open Sans', color: Color(0xFF71B0AD), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
