import 'package:flutter/material.dart';
import '../services/caregiver_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';

class CaregiverProfileScreen extends StatefulWidget {
  const CaregiverProfileScreen({super.key});

  @override
  State<CaregiverProfileScreen> createState() => _CaregiverProfileScreenState();
}

class _CaregiverProfileScreenState extends State<CaregiverProfileScreen> {
  static const Color _geyser = Color(0xFFCBD5E1); // azure/84

  String? _caregiverId;
  Map<String, dynamic>? _caregiver;
  bool _loading = true;
  bool _loadedArgs = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedArgs) return;
    _loadedArgs = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['caregiverId'] is String) {
      _caregiverId = args['caregiverId'] as String;
      CaregiverService.getCaregiverProfile(_caregiverId!).then((profile) {
        if (mounted) {
          setState(() {
            _caregiver = profile;
            _loading = false;
          });
        }
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildTitleRow(context),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.primaryGreen))
                      : _caregiverId == null
                          ? const EmptyState(
                              icon: Icons.person_off_outlined,
                              message: 'No caregiver selected.',
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(22, 0, 22, 100),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildProfileHeader(),
                                  const SizedBox(height: 16),
                                  _buildStatsRow(),
                                  const SizedBox(height: 20),
                                  _buildSkillsSection(),
                                  const SizedBox(height: 20),
                                  _buildAboutSection(),
                                  const SizedBox(height: 20),
                                  _buildReviewsSection(context),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                ),
              ],
            ),
          ),
          // Sticky bottom button
          if (!_loading && _caregiverId != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomButton(context),
            ),
        ],
      ),
    );
  }

  // ── Title row: back + "Caregiver profile" ────────────────
  Widget _buildTitleRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: AppTheme.textPrimary, size: 24),
          ),
          const SizedBox(width: 10),
          const Text(
            'Caregiver profile',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Avatar + name + subtitle ──────────────────────────────
  Widget _buildProfileHeader() {
    final name = (_caregiver?['name'] as String?)?.trim() ?? '';
    final initials = name.isEmpty
        ? '?'
        : name
            .trim()
            .split(RegExp(r'\s+'))
            .map((w) => w.isNotEmpty ? w[0] : '')
            .take(2)
            .join()
            .toUpperCase();
    final city = _caregiver?['city'] as String?;
    final careTypes = (_caregiver?['careTypes'] as List?)?.cast<String>() ?? [];
    final subtitle = [
      if (careTypes.isNotEmpty) careTypes.join(', '),
      if (city != null && city.isNotEmpty) city,
    ].join(' · ');

    return Center(
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Large avatar 78px
          Container(
            width: 78,
            height: 78,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF22C55E), AppTheme.primaryGreenDark],
              ),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppTheme.bottleGreen,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name.isEmpty ? 'Unnamed caregiver' : name,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Stat boxes: only years of experience is real data so far ─
  Widget _buildStatsRow() {
    final yearsExperience = _caregiver?['yearsExperience'] as int?;
    return Row(
      children: [
        Expanded(
          child: _statBox(
            yearsExperience?.toString() ?? '—',
            'Yrs exp',
            valueColor: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: _statBox('—', 'Rating', valueColor: AppTheme.textSecondary)),
        const SizedBox(width: 10),
        Expanded(child: _statBox('—', 'Jobs done', valueColor: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _statBox(String value, String label, {required Color valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 13),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Skills & qualifications ───────────────────────────────
  Widget _buildSkillsSection() {
    final skills = (_caregiver?['skills'] as List?)?.cast<String>() ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Skills & qualifications',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        if (skills.isEmpty)
          const Text(
            'No skills listed yet.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills.map((s) => _skillChip(s)).toList(),
          ),
      ],
    );
  }

  Widget _skillChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _geyser,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ── About section ─────────────────────────────────────────
  Widget _buildAboutSection() {
    final bio = (_caregiver?['bio'] as String?)?.trim() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          bio.isEmpty ? 'No bio provided yet.' : bio,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  // ── Reviews section ───────────────────────────────────────
  Widget _buildReviewsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Reviews',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/caregiver-reviews');
              },
              child: const Text(
                'See all',
                style: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const EmptyState(
          icon: Icons.rate_review_outlined,
          message: 'No reviews yet.',
        ),
      ],
    );
  }

  // ── Bottom sticky button ──────────────────────────────────
  Widget _buildBottomButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.surfaceColor.withValues(alpha: 0.0),
            AppTheme.surfaceColor,
          ],
          stops: const [0.0, 0.2],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Outlined "Leave a review" button
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => Navigator.pushNamed(
                  context,
                  '/add-review',
                  arguments: {'caregiverId': _caregiverId},
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.primaryGreen, width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Leave a review',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Filled "Send booking request" button
            Material(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => Navigator.pushNamed(
                  context,
                  '/send-request',
                  arguments: {'caregiverId': _caregiverId},
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: const Text(
                    'Send booking request',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.bottleGreen,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
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
