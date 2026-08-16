import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/patient_service.dart';
import '../services/review_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  Caregiver Reviews Received Screen
//  Reads real reviews from ReviewService for the caregiverId passed via
//  route arguments — previously this screen ignored its caller entirely
//  and always rendered a fixed "no reviews yet" placeholder, which is why
//  "See all" looked empty even when the profile's own rating summary
//  showed real review data.
// ─────────────────────────────────────────────────────────────
class CaregiverReviewsScreen extends StatefulWidget {
  const CaregiverReviewsScreen({super.key});

  @override
  State<CaregiverReviewsScreen> createState() => _CaregiverReviewsScreenState();
}

class _CaregiverReviewsScreenState extends State<CaregiverReviewsScreen> {
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String? _caregiverId;
  bool _loadedArgs = false;
  Stream<List<Map<String, dynamic>>>? _reviewsStream;
  final Map<String, String> _patientNames = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedArgs) return;
    _loadedArgs = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['caregiverId'] is String) {
      _caregiverId = args['caregiverId'] as String;
      _reviewsStream = ReviewService.streamReviewsForCaregiver(_caregiverId!);
    }
  }

  Future<String> _resolvePatientName(String? patientUid) async {
    if (patientUid == null) return 'A family member';
    final cached = _patientNames[patientUid];
    if (cached != null) return cached;
    final profile = await PatientService.getPatientProfile(patientUid);
    final name = (profile?['name'] as String?)?.trim();
    final resolved = name != null && name.isNotEmpty ? name : 'A family member';
    _patientNames[patientUid] = resolved;
    if (mounted) setState(() {});
    return resolved;
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return '';
    final d = ts.toDate();
    return '${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    setStatusBarStyle(Brightness.light);
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
              child: _caregiverId == null
                  ? const EmptyState(
                      icon: Icons.rate_review_outlined,
                      message: 'No reviews yet.',
                    )
                  : StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _reviewsStream,
                      builder: (context, snapshot) {
                        final reviews = snapshot.data ?? const [];
                        if (reviews.isEmpty) {
                          return const EmptyState(
                            icon: Icons.rate_review_outlined,
                            message: 'No reviews yet.',
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          itemCount: reviews.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 16),
                          itemBuilder: (_, i) => _buildReviewCard(reviews[i]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = (review['rating'] as num?)?.toInt() ?? 0;
    final text = (review['text'] as String?)?.trim() ?? '';
    final tags = (review['tags'] as List?)?.whereType<String>().toList() ?? const [];
    final createdAt = review['createdAt'];
    final dateLabel = createdAt is Timestamp ? _formatDate(createdAt) : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FutureBuilder<String>(
                future: _resolvePatientName(review['patientUid'] as String?),
                builder: (context, snap) {
                  return Text(
                    snap.data ?? 'A family member',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                },
              ),
              if (dateLabel.isNotEmpty)
                Text(
                  dateLabel,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(5, (i) {
              return Icon(
                i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                color: const Color(0xFFFBBC05),
                size: 18,
              );
            }),
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              text,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
