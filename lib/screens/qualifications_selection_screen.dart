import 'package:flutter/material.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Caregiver Qualifications Quiz  (Advanced Match — Step 4)
//  4 question screens sharing one light-theme card template:
//    Q1 · Education    (Figma node 334-869)  – single-select
//    Q2 · Experience   (Figma node 338-922)  – single-select
//    Q3 · Training     (Figma node 334-868)  – single-select (Yes / No)
//    Q4 · Languages    (Figma node 344-995)  – multi-select  → Continue
// ─────────────────────────────────────────────────────────────────────────────
class QualificationsSelectionScreen extends StatefulWidget {
  const QualificationsSelectionScreen({super.key});

  @override
  State<QualificationsSelectionScreen> createState() =>
      _QualificationsSelectionScreenState();
}

class _QualificationsSelectionScreenState
    extends State<QualificationsSelectionScreen> {
  // ── Design tokens ────────────────────────────────────────────────────────
  static const Color _bgCream = Color(0xFFF5EEDE);
  static const Color _cardCream = Color(0xFFFDF1CA);
  static const Color _accent = Color(0xFF6D4275);
  static const Color _headingPurple = Color(0xFF430F4C);
  static const Color _optionText = Color(0xFF4A1C52);
  static const Color _optionBorder = Color(0xFF43114C);
  static const Color _radioBorder = Color(0xFF3A0443);
  static const Color _creamButtonText = Color(0xFFF6F0E2);

  // ── Quiz state ───────────────────────────────────────────────────────────
  int _currentQ = 0; // 0-based index of current question
  static const int _totalQ = 4;

  // Q1 – Education (single-select)
  String? _education;
  static const _eduOptions = [
    'Primary',
    'Diploma',
    'Degree or higher',
  ];

  // Q2 – Experience (single-select)
  String? _experience;
  static const _expOptions = [
    'Less than 1 year',
    '1–3 years',
    '4–6 years',
    'More than 6 years',
  ];

  // Q3 – Training (single-select)
  String? _training;
  static const _trainOptions = ['Yes', 'No'];

  // Q4 – Languages (multi-select)
  final Set<String> _languages = {'Sinhala', 'English'};
  static const _langOptions = ['Sinhala', 'English', 'Tamil'];

  Map<String, dynamic> _bookingArgs = {};

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _bookingArgs = Map<String, dynamic>.from(args);
    }
  }

  void _goToQuestion(int index) {
    setState(() => _currentQ = index);
  }

  void _onNext() {
    if (_currentQ < _totalQ - 1) {
      _goToQuestion(_currentQ + 1);
    } else {
      // Last question → navigate to confirm-booking
      Navigator.pushNamed(
        context,
        '/confirm-booking',
        arguments: {
          ..._bookingArgs,
          'education': _education,
          'experience': _experience,
          'training': _training,
          'languages': _languages.toList(),
        },
      );
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_currentQ == 0) {
      return _buildQuestionCard(
        context,
        heroAsset: 'assets/images/qualification1.png',
        title: 'Highest educational qualification',
        options: _eduOptions,
        isSelected: (v) => v == _education,
        onToggle: (v) => setState(() => _education = v),
        canProceed: _education != null,
      );
    }
    if (_currentQ == 1) {
      return _buildQuestionCard(
        context,
        heroAsset: 'assets/images/qualification2.png',
        title: 'Years of caregiving experience',
        options: _expOptions,
        isSelected: (v) => v == _experience,
        onToggle: (v) => setState(() => _experience = v),
        canProceed: _experience != null,
      );
    }
    if (_currentQ == 2) {
      return _buildQuestionCard(
        context,
        heroAsset: 'assets/images/qualification3.png',
        title: 'Do you accept a formal trained caregiver?',
        options: _trainOptions,
        isSelected: (v) => v == _training,
        onToggle: (v) => setState(() => _training = v),
        canProceed: _training != null,
      );
    }
    // Q4 · Languages (multi-select)
    return _buildQuestionCard(
      context,
      heroAsset: 'assets/images/qualification4.png',
      title: 'Languages the caregiver must speak',
      options: _langOptions,
      isSelected: (v) => _languages.contains(v),
      onToggle: (v) => setState(() {
        if (_languages.contains(v)) {
          _languages.remove(v);
        } else {
          _languages.add(v);
        }
      }),
      canProceed: _languages.isNotEmpty,
    );
  }

  // ── Shared question layout: purple header bar, hero photo, cream card ──
  Widget _buildQuestionCard(
    BuildContext context, {
    required String heroAsset,
    required String title,
    required List<String> options,
    required bool Function(String) isSelected,
    required void Function(String) onToggle,
    required bool canProceed,
  }) {
    return Scaffold(
      backgroundColor: _bgCream,
      // Per Figma node 567-198: the photo runs from the very top of the
      // screen and the header is painted OVER it (not stacked above it as
      // a separate opaque block) — that's what closes the small gap that
      // used to show at the header's rounded bottom corners, since those
      // corners now reveal the photo underneath instead of the scaffold's
      // cream background.
      body: Stack(
        children: [
          // The image still only gets "screen height minus the card's own
          // height" via Expanded in this Column, instead of the full
          // device height a Positioned.fill directly on Image would give
          // it — BoxFit.cover zooms to fully cover whatever box it's laid
          // out in, and sizing that box off the real device's full height
          // (usually taller than the Figma mock) was forcing far more zoom
          // than intended, eating the margin around the subject. Sizing
          // off the actual visible region keeps the crop consistent with
          // each question's card height, while the header now simply
          // paints on top of this same layer rather than budgeting its
          // own separate row above it.
          Positioned.fill(
            child: Column(
              // Column defaults to CrossAxisAlignment.center, which gives
              // children loose (not full-width) constraints — the image
              // was sizing to its own intrinsic asset width instead of
              // filling the screen, leaving cream background visible on
              // both sides. stretch forces both the image and the card to
              // span the full width.
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  // topCenter, not the default center — BoxFit.cover crops
                  // symmetrically around the alignment point, and centered
                  // cropping was cutting the headroom above each subject's
                  // face along with the excess at the bottom, leaving the
                  // face right at the top edge where the header covers it.
                  // Anchoring to the top keeps that headroom and crops the
                  // extra from the bottom instead, so faces sit lower,
                  // clear of the header, across all four hero photos.
                  child: Image.asset(
                    heroAsset,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: _cardCream,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.25),
                        blurRadius: 4,
                        offset: Offset(0, -8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 19, 24, 20),
                  // SafeArea keeps the "Next" button clear of the on-screen
                  // nav bar — Figma's mock frame has no OS chrome overlaid
                  // to account for, so without this the button sits flush
                  // against the physical bottom edge and gets clipped.
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Open Sans',
                            color: _headingPurple,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ...options.map((opt) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 15),
                            child: GestureDetector(
                              onTap: () => onToggle(opt),
                              child: _buildOptionRow(opt, isSelected(opt)),
                            ),
                          );
                        }),
                        const SizedBox(height: 9),
                        Material(
                          color: _accent,
                          borderRadius: BorderRadius.circular(15),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(15),
                            onTap: canProceed ? _onNext : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              child: Text(
                                'Next',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Open Sans',
                                  color: _creamButtonText.withValues(
                                      alpha: canProceed ? 1 : 0.5),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Header — painted last, so it's always on top of the image
          // layer above. Pinned to the top edge regardless of how the
          // image/card split their space below it.
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(17, 15, 17, 15),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_currentQ > 0) {
                            _goToQuestion(_currentQ - 1);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Caregiver qualifications',
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionRow(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.fromLTRB(19, 18, 2, 18),
      decoration: BoxDecoration(
        color: isSelected ? const Color.fromRGBO(102, 52, 112, 0.4) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _optionBorder, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Open Sans',
              color: _optionText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? _accent : Colors.transparent,
              border: Border.all(color: _radioBorder, width: 1.5),
            ),
            child: isSelected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                : null,
          ),
        ],
      ),
    );
  }
}
