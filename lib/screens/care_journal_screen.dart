import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'add_journal_entry_sheet.dart';
import '../services/auth_service.dart';
import '../services/care_journal_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  Care Journal Screen  (Caregiver)
//  Figma node: 487-625 · "View care journey" from the patient
//  profile screen.
//
//  Figma mocks a "current status" dashboard (mood picker, a
//  vitals grid, an activities checklist) sitting permanently
//  above a separate history feed — that's two parallel copies of
//  the same information that would drift out of sync. Instead
//  there's one real source of truth: a timestamped timeline
//  backed by CareJournalService, and every one of Figma's example
//  cards (mood, vitals, meal, medication, incident) is just a
//  category of entry in that same timeline, added via the "+"
//  button (add_journal_entry_sheet.dart).
//
//  "Draft — pending sync" and the "Offline" pill are both real —
//  they read Firestore's own snapshot metadata rather than a
//  bespoke sync flag.
// ─────────────────────────────────────────────────────────────
class CareJournalScreen extends StatefulWidget {
  const CareJournalScreen({super.key});

  @override
  State<CareJournalScreen> createState() => _CareJournalScreenState();
}

class _CareJournalScreenState extends State<CareJournalScreen> {
  static const Color _bg = Color(0xFFF5EEDE);
  static const Color _titleGreen = Color(0xFF06402B);
  static const Color _subtitle = Color(0xFF5B7B80);
  static const Color _timelineBg = Color(0xFFEAE4D6);
  static const Color _timelineBorder = Color(0xFF156264);
  static const Color _draftBg = Color(0xFFD9D5CA);
  static const Color _draftBorder = Color(0xFF94A3B8);
  static const Color _flaggedBg = Color(0xFFF9EADC);
  static const Color _flaggedBorder = Color(0xFFEF4444);
  static const Color _bodyText = Color(0xFF0F2933);
  static const Color _flaggedText = Color(0xFFAB2525);

  bool _didReadArgs = false;
  Map<String, dynamic> _args = {};

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadArgs) return;
    _didReadArgs = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) _args = Map<String, dynamic>.from(args);
  }

  String? get _patientUid => _args['patientUid'] as String?;
  String get _patientName => (_args['patientName'] as String?) ?? 'Patient';

  String get _scheduleLabel {
    final parts = [
      if (_args['startDate'] != null) _args['startDate'] as String,
      if (_args['startTime'] != null && _args['endTime'] != null)
        '${_args['startTime']}–${_args['endTime']}'
      else if (_args['startTime'] != null)
        _args['startTime'] as String,
    ];
    return parts.isEmpty ? '' : parts.join(', ');
  }

  ({Color bg, Color text}) _categoryStyle(String category) {
    switch (category) {
      case 'meal':
        return (bg: const Color.fromRGBO(245, 158, 11, 0.15), text: const Color(0xFFB45309));
      case 'medication':
        return (bg: const Color.fromRGBO(59, 130, 246, 0.12), text: const Color(0xFF2563EB));
      case 'hygiene':
        return (bg: const Color.fromRGBO(13, 148, 136, 0.12), text: const Color(0xFF0D9488));
      case 'vitals':
        return (bg: const Color.fromRGBO(14, 165, 233, 0.12), text: const Color(0xFF0369A1));
      case 'incident':
        return (bg: const Color.fromRGBO(239, 68, 68, 0.12), text: const Color(0xFFDC2626));
      default:
        return (bg: const Color.fromRGBO(148, 163, 184, 0.15), text: const Color(0xFF5B7B80));
    }
  }

  String _formatClock(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${t.hour >= 12 ? 'PM' : 'AM'}';
  }

  Future<void> _addEntry() async {
    final uid = AuthService.currentUser?.uid;
    final patientUid = _patientUid;
    if (uid == null || patientUid == null) return;
    final profile = await AuthService.getUserProfile(uid);
    final authorName = (profile?['name'] as String?) ?? 'Caregiver';
    if (!mounted) return;
    await showAddJournalEntrySheet(
      context,
      patientUid: patientUid,
      authorUid: uid,
      authorName: authorName,
      offline: _offline,
    );
  }

  bool _offline = false;

  Future<void> _editEntry(String entryId, String currentText) async {
    final patientUid = _patientUid;
    if (patientUid == null) return;
    final controller = TextEditingController(text: currentText);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit entry'),
        content: TextField(controller: controller, maxLines: 4, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved == true && controller.text.trim().isNotEmpty) {
      await CareJournalService.updateEntry(patientUid, entryId, controller.text.trim());
    }
  }

  Future<void> _deleteEntry(String entryId) async {
    final patientUid = _patientUid;
    if (patientUid == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this entry?'),
        content: const Text('This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await CareJournalService.deleteEntry(patientUid, entryId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientUid = _patientUid;
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 18, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _titleGreen, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text('Care journal', style: TextStyle(fontFamily: 'Open Sans', color: _titleGreen, fontSize: 20, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (_offline)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(245, 158, 11, 0.12),
                        border: Border.all(color: const Color(0xFFF59E0B)),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_off_rounded, color: Color(0xFFB45309), size: 13),
                          SizedBox(width: 5),
                          Text('Offline', style: TextStyle(fontFamily: 'Inter', color: Color(0xFFB45309), fontSize: 10, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(53, 4, 22, 0),
              child: Text(
                _scheduleLabel.isEmpty ? _patientName : '$_patientName · $_scheduleLabel',
                style: const TextStyle(fontFamily: 'Open Sans', color: _subtitle, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: patientUid == null
                  ? const EmptyState(icon: Icons.menu_book_rounded, message: 'No patient selected.')
                  : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: CareJournalService.streamEntries(patientUid),
                      builder: (context, snapshot) {
                        final docs = snapshot.data?.docs ?? const [];
                        final isFromCache = snapshot.data?.metadata.isFromCache ?? false;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && _offline != isFromCache) setState(() => _offline = isFromCache);
                        });
                        if (docs.isEmpty) {
                          return const EmptyState(icon: Icons.menu_book_rounded, message: 'No journal entries yet. Tap + to add the first one.');
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 6, 20, 90),
                          itemCount: docs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) => _entryCard(docs[i]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: patientUid == null
          ? null
          : GestureDetector(
              onTap: _addEntry,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2D486F), Color(0xFF041E43)]),
                  boxShadow: [BoxShadow(color: const Color(0xFF0D9488).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 10))],
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
              ),
            ),
    );
  }

  Widget _entryCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final category = (data['category'] as String?) ?? 'general';
    final text = data['text'] as String? ?? '';
    final flagged = data['flagged'] == true;
    final authorUid = data['authorUid'] as String?;
    final photoUrl = data['photoUrl'] as String?;
    final createdAt = data['createdAt'];
    final time = createdAt is Timestamp ? createdAt.toDate() : DateTime.now();
    final pending = doc.metadata.hasPendingWrites;
    final isMine = authorUid == AuthService.currentUser?.uid;
    final style = _categoryStyle(category);

    final cardBg = pending ? _draftBg : (flagged ? _flaggedBg : _timelineBg);
    final borderColor = flagged ? _flaggedBorder : (pending ? _draftBorder : _timelineBorder);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13.5),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: borderColor, width: flagged ? 1.5 : 1),
        borderRadius: BorderRadius.circular(14),
        boxShadow: flagged
            ? [BoxShadow(color: const Color(0xFFEF4444).withValues(alpha: 0.1), blurRadius: 7, offset: const Offset(0, 4))]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatClock(time), style: const TextStyle(fontFamily: 'Inter', color: _subtitle, fontSize: 11, fontWeight: FontWeight.w600)),
              if (pending)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(999)),
                  child: const Text('Draft — pending sync', style: TextStyle(fontFamily: 'Inter', color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w700)),
                )
              else if (isMine)
                Row(
                  children: [
                    GestureDetector(onTap: () => _editEntry(doc.id, text), child: const Icon(Icons.edit_outlined, color: Color(0xFF94A3B8), size: 16)),
                    const SizedBox(width: 12),
                    GestureDetector(onTap: () => _deleteEntry(doc.id), child: const Icon(Icons.delete_outline_rounded, color: Color(0xFF94A3B8), size: 16)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (flagged) ...[
                const Icon(Icons.flag_rounded, color: Color(0xFFEF4444), size: 15),
                const SizedBox(width: 6),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(color: flagged ? const Color.fromRGBO(239, 68, 68, 0.12) : style.bg, borderRadius: BorderRadius.circular(999)),
                child: Text(
                  flagged ? 'Incident' : '${category[0].toUpperCase()}${category.substring(1)}',
                  style: TextStyle(fontFamily: 'Open Sans', color: flagged ? const Color(0xFFDC2626) : style.text, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(text, style: TextStyle(fontFamily: 'Open Sans', color: flagged ? _flaggedText : _bodyText, fontSize: 12, fontWeight: FontWeight.w500, height: 1.4)),
          if (photoUrl != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(photoUrl, height: 120, width: double.infinity, fit: BoxFit.cover),
            ),
          ],
        ],
      ),
    );
  }
}
