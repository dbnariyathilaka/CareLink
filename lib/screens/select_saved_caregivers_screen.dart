import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/caregiver_service.dart';
import '../services/patient_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/remote_or_local_image.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────────────────
//  Select Saved Caregivers — reached from the dashboard's "Saved
//  caregivers" row via its (+) button. Lets a patient tick/untick any
//  number of caregivers and commit the whole selection at once with
//  Save/Cancel, rather than the previous behaviour of just dropping them
//  into the general search screen with no way to actually favorite anyone
//  from there.
// ─────────────────────────────────────────────────────────────────────────
class SelectSavedCaregiversScreen extends StatefulWidget {
  const SelectSavedCaregiversScreen({super.key});

  @override
  State<SelectSavedCaregiversScreen> createState() =>
      _SelectSavedCaregiversScreenState();
}

class _SelectSavedCaregiversScreenState
    extends State<SelectSavedCaregiversScreen> {
  static const Color bgCream = Color(0xFFF5EEDE);
  static const Color darkGreen = Color(0xFF06402B);
  static const Color headerGreenLight = Color(0xFF0E7A50);
  static const Color cardTan = Color(0xFFD1C8B4);

  bool _loading = true;
  bool _saving = false;
  List<Map<String, dynamic>> _caregivers = [];
  Set<String> _originalIds = {};
  Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.light);
    _load();
  }

  Future<void> _load() async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    final results = await Future.wait([
      CaregiverService.searchCaregivers(),
      PatientService.getFavoriteCaregiverIds(uid),
    ]);
    final caregivers = results[0] as List<Map<String, dynamic>>;
    final favoriteIds = (results[1] as List<String>).toSet();
    if (!mounted) return;
    setState(() {
      _caregivers = caregivers;
      _originalIds = favoriteIds;
      _selectedIds = {...favoriteIds};
      _loading = false;
    });
  }

  Future<void> _save() async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    final added = _selectedIds.difference(_originalIds);
    final removed = _originalIds.difference(_selectedIds);
    if (added.isEmpty && removed.isEmpty) {
      Navigator.pop(context, false);
      return;
    }
    setState(() => _saving = true);
    await Future.wait([
      for (final id in added)
        PatientService.toggleFavorite(
          patientUid: uid,
          caregiverUid: id,
          isFavorite: true,
        ),
      for (final id in removed)
        PatientService.toggleFavorite(
          patientUid: uid,
          caregiverUid: id,
          isFavorite: false,
        ),
    ]);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  String _initialsOf(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed
        .split(RegExp(r'\s+'))
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildBody()),
          _buildBottomBar(context),
        ],
      ),
    );
  }

  // Paints full-bleed behind the transparent status bar (edge-to-edge mode);
  // the top padding below (not an outer SafeArea) keeps content clear of it.
  Widget _buildHeader(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(22, topInset + 12, 22, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [headerGreenLight, darkGreen],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context, false),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(height: 10),
          const Text(
            'Saved caregivers',
            style: TextStyle(
              fontFamily: 'Open Sans',
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _loading
                ? 'Tap caregivers to save them for quick access'
                : '${_selectedIds.length} selected',
            style: const TextStyle(
              fontFamily: 'Open Sans',
              color: Color.fromRGBO(226, 217, 227, 0.87),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: darkGreen));
    }
    if (_caregivers.isEmpty) {
      return const EmptyState(
        icon: Icons.person_search_rounded,
        message: 'No caregivers have registered yet — check back soon.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      itemCount: _caregivers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _buildCaregiverRow(_caregivers[index]),
    );
  }

  Widget _buildCaregiverRow(Map<String, dynamic> caregiver) {
    final uid = caregiver['uid'] as String?;
    final name = (caregiver['name'] as String?)?.trim() ?? '';
    final photoUrl = (caregiver['photoUrl'] as String?)?.trim();
    final city = caregiver['city'] as String?;
    final selected = uid != null && _selectedIds.contains(uid);

    return GestureDetector(
      onTap: uid == null
          ? null
          : () => setState(() {
                if (selected) {
                  _selectedIds.remove(uid);
                } else {
                  _selectedIds.add(uid);
                }
              }),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardTan,
          borderRadius: BorderRadius.circular(12),
          border: selected ? Border.all(color: darkGreen, width: 1.5) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFE9C368),
                shape: BoxShape.circle,
              ),
              child: (photoUrl != null && photoUrl.isNotEmpty)
                  ? ClipOval(
                      child: RemoteOrLocalImage(
                        source: photoUrl,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Text(
                        _initialsOf(name),
                        style: const TextStyle(
                          fontFamily: 'Quattrocento Sans',
                          color: darkGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'Unnamed caregiver' : name,
                    style: const TextStyle(
                      fontFamily: 'Open Sans',
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (city != null && city.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      city,
                      style: const TextStyle(
                        fontFamily: 'Open Sans',
                        color: Colors.black54,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? darkGreen : Colors.black38,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: darkGreen),
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    color: darkGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _saving || _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
