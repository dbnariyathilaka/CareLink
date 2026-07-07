import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class _ReviewData {
  final String initials;
  final List<Color> avatarGradient;
  final Color initialsColor;
  final String name;
  final int stars;
  final String date;
  final String text;
  final String tag;

  const _ReviewData({
    required this.initials,
    required this.avatarGradient,
    required this.initialsColor,
    required this.name,
    required this.stars,
    required this.date,
    required this.text,
    required this.tag,
  });
}

// ─────────────────────────────────────────────────────────────
//  Caregiver Reviews Received Screen
//  Figma node: 46-4521
// ─────────────────────────────────────────────────────────────
class CaregiverReviewsScreen extends StatefulWidget {
  const CaregiverReviewsScreen({super.key});

  @override
  State<CaregiverReviewsScreen> createState() => _CaregiverReviewsScreenState();
}

class _CaregiverReviewsScreenState extends State<CaregiverReviewsScreen> {
  static const Color _indigo = Color(0xFF6366F1);
  static const Color _amber = Color(0xFFF59E0B);

  int _selectedFilter = 0; // 0=All, 1=5★, 2=4★, 3=3★
  static const List<String> _filters = ['All', '5★', '4★', '3★'];

  static const List<({int stars, double fraction, int count})> _distribution = [
    (stars: 5, fraction: 0.9, count: 18),
    (stars: 4, fraction: 0.3, count: 4),
    (stars: 3, fraction: 0.1, count: 1),
    (stars: 2, fraction: 0.0, count: 0),
    (stars: 1, fraction: 0.0, count: 0),
  ];

  static const List<_ReviewData> _reviews = [
    _ReviewData(
      initials: 'NA',
      avatarGradient: [AppTheme.primaryGreen, AppTheme.primaryGreenDark],
      initialsColor: AppTheme.bottleGreen,
      name: 'Nipuni Ariyathilaka',
      stars: 5,
      date: 'Nov 2025',
      text: '"Brian was incredibly patient and kind with my mother. '
          'Punctual every single day."',
      tag: 'Elder care',
    ),
    _ReviewData(
      initials: 'KP',
      avatarGradient: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
      initialsColor: Colors.white,
      name: 'Kamal Perera',
      stars: 5,
      date: 'Oct 2025',
      text: '"Professional and reassuring during my post-surgery '
          'recovery. Highly recommend."',
      tag: 'Post-surgery',
    ),
  ];

  List<_ReviewData> get _filtered {
    if (_selectedFilter == 0) return _reviews;
    final targetStars = 6 - _selectedFilter; // 1->5, 2->4, 3->3
    return _reviews.where((r) => r.stars == targetStars).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 22, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Reviews received',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRatingSummaryCard(),
                    const SizedBox(height: 14),
                    _buildFilterRow(),
                    const SizedBox(height: 14),
                    ..._filtered.map(
                      (review) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildReviewCard(review),
                      ),
                    ),
                    if (_filtered.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No reviews in this range yet.',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
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
    );
  }

  // ── Rating summary card ───────────────────────────────────
  Widget _buildRatingSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            child: Column(
              children: const [
                Text(
                  '4.5',
                  style: TextStyle(
                    color: _amber,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '★★★★★',
                  style: TextStyle(
                    color: _amber,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '24 reviews',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              children: _distribution.map((d) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        child: Text(
                          '${d.stars}★',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceColor,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: d.fraction,
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _amber,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${d.count}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter chips + sort ───────────────────────────────────
  Widget _buildFilterRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: List.generate(_filters.length, (i) {
            final selected = i == _selectedFilter;
            return Padding(
              padding: EdgeInsets.only(right: i == _filters.length - 1 ? 0 : 7),
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected ? _indigo : AppTheme.cardColor,
                    border: selected ? null : Border.all(color: AppTheme.borderColor),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _filters[i],
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFFCBD5E1),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sorting coming soon!')),
            );
          },
          child: Row(
            children: const [
              Text(
                'Newest',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary, size: 15),
            ],
          ),
        ),
      ],
    );
  }

  // ── Review card ───────────────────────────────────────────
  Widget _buildReviewCard(_ReviewData review) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: review.avatarGradient,
                  ),
                ),
                child: Center(
                  child: Text(
                    review.initials,
                    style: TextStyle(
                      color: review.initialsColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${'★' * review.stars} · ${review.date}',
                      style: const TextStyle(
                        color: _amber,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            review.text,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 9),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              review.tag,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
