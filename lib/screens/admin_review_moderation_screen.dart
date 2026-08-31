import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/patient_service.dart';
import '../services/review_service.dart';
import '../services/user_directory_service.dart';
import '../widgets/admin_bottom_nav.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  Admin — All Reviews
//  Previously this screen was a fully mocked "moderation queue" (flagged /
//  hidden / cleared reviews, fabricated fraud explanations, block-reviewer
//  actions) with zero backing data — the `reviews` collection has no
//  moderation-status field and no fraud detection exists anywhere in this
//  codebase. This screen now reads the real `reviews` collection via
//  ReviewService.streamAllReviews() and joins caregiver/patient names from
//  `users` — no moderation actions are offered because nothing real exists
//  for them to act on.
// ─────────────────────────────────────────────────────────────
class AdminReviewModerationScreen extends StatefulWidget {
  const AdminReviewModerationScreen({super.key});

  @override
  State<AdminReviewModerationScreen> createState() => _AdminReviewModerationScreenState();
}

class _AdminReviewModerationScreenState extends State<AdminReviewModerationScreen> {
  // ── Color Tokens matching Figma node 643:685 ────────────────────────────
  static const Color bgColor = Color(0xFFF5EEDE);
  static const Color titleColor = Color(0xFF544730);

  static const Color cardBg = Color(0xFFC4BBAC);
  static const Color cardBorder = Color(0xFF70573C);

  static const Color starColor = Color(0xFFB26915);
  static const Color timestampColor = Color(0xFF5D5445);

  static const Color nameColor = Color(0xFF544730);
  static const Color subtitleColor = Color(0xFF82716A);
  static const Color reviewTextColor = Color(0xFF5A4B37);

  static const Color tagBg = Color(0xFFA69785);
  static const Color tagTextColor = Color(0xFF5D5445);


  final Map<String, String> _caregiverNames = {};
  final Map<String, String> _patientNames = {};

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
  }

  Future<String> _resolveCaregiverName(String? caregiverId) async {
    if (caregiverId == null || caregiverId.isEmpty) return 'Caregiver';
    final cached = _caregiverNames[caregiverId];
    if (cached != null) return cached;
    final user = await UserDirectoryService.getUser(caregiverId);
    final name = (user?['name'] as String?)?.trim();
    final resolved = (name != null && name.isNotEmpty) ? name : 'Caregiver';
    _caregiverNames[caregiverId] = resolved;
    if (mounted) setState(() {});
    return resolved;
  }

  Future<String> _resolvePatientName(String? patientUid) async {
    if (patientUid == null || patientUid.isEmpty) return 'Patient';
    final cached = _patientNames[patientUid];
    if (cached != null) return cached;
    final resolved = await PatientService.getPatientName(patientUid);
    _patientNames[patientUid] = resolved;
    if (mounted) setState(() {});
    return resolved;
  }

  String _formatDate(dynamic createdAt) {
    if (createdAt is! Timestamp) return '';
    final dt = createdAt.toDate();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: ReviewService.streamAllReviews(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: titleColor),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Could not load reviews.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: titleColor.withValues(alpha: 0.6),
                        ),
                      ),
                    );
                  }

                  final reviews = snapshot.data ?? const <Map<String, dynamic>>[];

                  if (reviews.isEmpty) {
                    return Center(
                      child: Text(
                        'No reviews yet',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: titleColor.withValues(alpha: 0.6),
                        ),
                      ),
                    );
                  }

                  final totalRating = reviews.fold<double>(
                    0,
                    (acc, r) => acc + ((r['rating'] as num?)?.toDouble() ?? 0),
                  );
                  final avgRating = totalRating / reviews.length;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryBar(reviews.length, avgRating),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(22, 4, 22, 20),
                          itemCount: reviews.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 11),
                          itemBuilder: (context, index) => _buildReviewCard(reviews[index]),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const AdminBottomNav(active: AdminNavTab.review),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.only(right: 10),
              child: Icon(Icons.arrow_back_rounded, color: titleColor, size: 24),
            ),
          ),
          const Icon(Icons.reviews_rounded, color: titleColor, size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'All reviews',
              style: TextStyle(fontFamily: 'Inter', fontSize: 19, fontWeight: FontWeight.w800, color: titleColor),
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary bar (real, computed from the live review stream) ────────────
  Widget _buildSummaryBar(int count, double avgRating) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorder, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w800, color: nameColor),
                  ),
                  const Text(
                    'Total reviews',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 10.5, fontWeight: FontWeight.w500, color: subtitleColor),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    avgRating.toStringAsFixed(1),
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w800, color: nameColor),
                  ),
                  const Text(
                    'Average rating',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 10.5, fontWeight: FontWeight.w500, color: subtitleColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Review card ─────────────────────────────────────────────────────────
  Widget _buildReviewCard(Map<String, dynamic> review) {
    final caregiverId = review['caregiverId'] as String?;
    final patientUid = review['patientUid'] as String?;
    final rating = (review['rating'] as num?)?.toInt() ?? 0;
    final text = (review['text'] as String?)?.trim() ?? '';
    final tags = (review['tags'] as List?)?.whereType<String>().toList() ?? const <String>[];
    final dateLabel = _formatDate(review['createdAt']);

    final cachedCaregiverName = caregiverId != null ? _caregiverNames[caregiverId] : null;
    final cachedPatientName = patientUid != null ? _patientNames[patientUid] : null;
    if (cachedCaregiverName == null) _resolveCaregiverName(caregiverId);
    if (cachedPatientName == null) _resolvePatientName(patientUid);
    final caregiverName = cachedCaregiverName ?? '…';
    final patientName = cachedPatientName ?? '…';

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$patientName → $caregiverName',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, fontWeight: FontWeight.w700, color: nameColor),
                ),
              ),
              if (dateLabel.isNotEmpty)
                Text(
                  dateLabel,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 10.5, fontWeight: FontWeight.w500, color: timestampColor),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              return Icon(
                i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                size: 16,
                color: starColor,
              );
            }),
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              text,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 12.5, fontWeight: FontWeight.w400, color: reviewTextColor, height: 1.55),
            ),
          ],
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: tagBg, borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    tag,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 10.5, fontWeight: FontWeight.w600, color: tagTextColor),
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
