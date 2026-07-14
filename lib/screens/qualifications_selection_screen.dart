import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Caregiver Qualifications Quiz  (Advanced Match — Step 4)
//  4 question screens in one stateful widget:
//    Q1 · Education    (Que 1/4)  – single-select
//    Q2 · Experience   (Que 2/4)  – single-select
//    Q3 · Training     (Que 3/4)  – single-select (Yes / No)
//    Q4 · Languages    (Que 4/4)  – multi-select  → Continue
// ─────────────────────────────────────────────────────────────────────────────
class QualificationsSelectionScreen extends StatefulWidget {
  const QualificationsSelectionScreen({super.key});

  @override
  State<QualificationsSelectionScreen> createState() =>
      _QualificationsSelectionScreenState();
}

class _QualificationsSelectionScreenState
    extends State<QualificationsSelectionScreen>
    with SingleTickerProviderStateMixin {
  // ── Design tokens ──────────────────────────────────────────────────────────
  static const Color _keppel      = Color(0xFF3DB498);
  static const Color _bottleGreen = Color(0xFF06291F);
  static const Color _azure11     = Color(0xFF0F172A);
  static const Color _azure17     = Color(0xFF1E293B);
  static const Color _azure27     = Color(0xFF334155);
  static const Color _azure65     = Color(0xFF94A3B8);
  static const Color _grey98      = Color(0xFFF8FAFC);
  static const Color _tealTop     = Color(0xFF1A7A6E);
  static const Color _tealMid     = Color(0xFF0D4F47);

  // ── Quiz state ─────────────────────────────────────────────────────────────
  int _currentQ = 0; // 0-based index of current question
  static const int _totalQ = 4;

  // Q1 – Education (single-select)
  String? _education;
  static const _eduOptions = [
    'Primary',
    'Secondary',
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

  // Slide animation
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _slideCtrl.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _bookingArgs = Map<String, dynamic>.from(args);
    }
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  void _animateToNext() {
    _slideCtrl.reset();
    _slideCtrl.forward();
  }

  void _onNext() {
    if (_currentQ < _totalQ - 1) {
      setState(() {
        _currentQ++;
        _animateToNext();
      });
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

  bool get _canProceed {
    switch (_currentQ) {
      case 0:
        return _education != null;
      case 1:
        return _experience != null;
      case 2:
        return _training != null;
      case 3:
        return _languages.isNotEmpty;
      default:
        return false;
    }
  }

  // ── Questions metadata ─────────────────────────────────────────────────────
  String get _questionTitle {
    const titles = [
      'Highest educational qualification',
      'Years of caregiving experience',
      'Have you received formal caregiving training?',
      'Languages you can speak',
    ];
    return titles[_currentQ];
  }

  IconData get _questionIcon {
    const icons = [
      Icons.school_rounded,
      Icons.work_history_rounded,
      Icons.verified_rounded,
      Icons.translate_rounded,
    ];
    return icons[_currentQ];
  }

  String get _buttonLabel => _currentQ == _totalQ - 1 ? 'Continue' : 'Next';

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _azure11,
      body: Column(
        children: [
          // Header
          _buildHeader(context),

          // Question hero card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: _buildHeroCard(),
          ),

          // Question title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _questionTitle,
                style: const TextStyle(
                  color: _grey98,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
            ),
          ),

          // Options list (animated slide-in)
          Expanded(
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: _buildOptions(),
              ),
            ),
          ),

          // Next / Continue button
          _buildBottomButton(context),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (_currentQ > 0) {
                  setState(() {
                    _currentQ--;
                    _animateToNext();
                  });
                } else {
                  Navigator.pop(context);
                }
              },
              child: const Icon(Icons.arrow_back, color: _grey98, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Caregiver qualifications',
              style: TextStyle(
                color: _grey98,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero Teal Card ─────────────────────────────────────────────────────────
  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      height: 172,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_tealTop, _tealMid],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // "Que X/4" badge
          Positioned(
            top: 14,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Que ${_currentQ + 1}/$_totalQ',
                style: const TextStyle(
                  color: _grey98,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Large central icon
          Center(
            child: Icon(
              _questionIcon,
              color: _grey98.withValues(alpha: 0.9),
              size: 70,
            ),
          ),
        ],
      ),
    );
  }

  // ── Options ────────────────────────────────────────────────────────────────
  Widget _buildOptions() {
    switch (_currentQ) {
      case 0:
        return _buildSingleSelect(_eduOptions, _education, (v) {
          setState(() => _education = v);
        });
      case 1:
        return _buildSingleSelect(_expOptions, _experience, (v) {
          setState(() => _experience = v);
        });
      case 2:
        return _buildSingleSelect(_trainOptions, _training, (v) {
          setState(() => _training = v);
        });
      case 3:
        return _buildMultiSelect(_langOptions, _languages);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSingleSelect(
    List<String> options,
    String? selected,
    ValueChanged<String> onTap,
  ) {
    return Column(
      children: options.map((opt) {
        final isSelected = opt == selected;
        return GestureDetector(
          onTap: () => onTap(opt),
          child: _buildOptionRow(opt, isSelected),
        );
      }).toList(),
    );
  }

  Widget _buildMultiSelect(List<String> options, Set<String> selected) {
    return Column(
      children: options.map((opt) {
        final isSelected = selected.contains(opt);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                selected.remove(opt);
              } else {
                selected.add(opt);
              }
            });
          },
          child: _buildOptionRow(opt, isSelected),
        );
      }).toList(),
    );
  }

  Widget _buildOptionRow(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      decoration: BoxDecoration(
        color: isSelected ? _keppel.withValues(alpha: 0.10) : _azure17,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? _keppel : _azure27,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? _keppel : _grey98,
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? _keppel : Colors.transparent,
              border: Border.all(
                color: isSelected ? _keppel : _azure65,
                width: 1.5,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check_rounded, color: _bottleGreen, size: 14)
                : null,
          ),
        ],
      ),
    );
  }

  // ── Bottom button ──────────────────────────────────────────────────────────
  Widget _buildBottomButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_azure11.withValues(alpha: 0), _azure11],
          stops: const [0.0, 0.35],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Material(
            color: _canProceed ? _keppel : _azure27,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _canProceed ? _onNext : null,
              child: SizedBox(
                height: 54,
                child: Center(
                  child: Text(
                    _buttonLabel,
                    style: TextStyle(
                      color: _canProceed ? _bottleGreen : _azure65,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
