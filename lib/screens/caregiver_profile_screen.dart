import 'package:flutter/material.dart';
import '../services/caregiver_service.dart';
import '../services/review_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/remote_or_local_image.dart';
import '../widgets/status_bar.dart';

class CaregiverProfileScreen extends StatefulWidget {
  const CaregiverProfileScreen({super.key});

  @override
  State<CaregiverProfileScreen> createState() => _CaregiverProfileScreenState();
}

class _CaregiverProfileScreenState extends State<CaregiverProfileScreen> {
  static const Color bgCream = Color(0xFFF5EEDE);
  static const Color darkGreen = Color(0xFF06402B);
  static const Color statBoxBg = Color(0xFFCCCCC4);
  static const Color statLabel = Color(0xFF313131);
  static const Color availableBadgeBg = Color.fromRGBO(231, 92, 17, 0.18);
  static const Color availableAccent = Color(0xFFA94813);
  static const Color matchCardBg = Color.fromRGBO(6, 64, 43, 0.85);
  static const Color matchCardBorder = Color(0xFF334155);
  static const Color barTrack = Color(0xFF0F172A);
  static const Color barFill = Color(0xFFFBBC05);
  static const Color chipBg = Color(0xFF1E293B);
  static const Color chipBorder = Color(0xFF334155);
  static const Color chipText = Color(0xFFCBD5E1);
  static const Color bodyText = Color.fromRGBO(0, 0, 0, 0.58);

  String? _caregiverId;
  Map<String, dynamic>? _caregiver;
  Map<String, dynamic>? _matchBreakdown;
  bool _loading = true;
  bool _loadedArgs = false;
  Stream<List<Map<String, dynamic>>>? _reviewsStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedArgs) return;
    _loadedArgs = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['caregiverId'] is String) {
      _caregiverId = args['caregiverId'] as String;
      if (args['matchBreakdown'] is Map) {
        _matchBreakdown = Map<String, dynamic>.from(args['matchBreakdown'] as Map);
      }
      _reviewsStream = ReviewService.streamReviewsForCaregiver(_caregiverId!);
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
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildTitleRow(context),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(color: darkGreen))
                      : _caregiverId == null
                          ? const EmptyState(
                              icon: Icons.person_off_outlined,
                              message: 'No caregiver selected.',
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(22, 6, 22, 110),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildProfileHeader(),
                                  const SizedBox(height: 18),
                                  _buildStatsRow(),
                                  if (_matchBreakdown != null) ...[
                                    const SizedBox(height: 16),
                                    _buildMatchBreakdownCard(),
                                  ],
                                  const SizedBox(height: 20),
                                  _buildSkillsSection(),
                                  const SizedBox(height: 20),
                                  _buildAboutSection(),
                                  const SizedBox(height: 20),
                                  StreamBuilder<List<Map<String, dynamic>>>(
                                    stream: _reviewsStream,
                                    builder: (context, snapshot) {
                                      final reviews = snapshot.data ?? const [];
                                      return _buildReviewsSection(context, reviews);
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                ),
              ],
            ),
          ),
          // Sticky bottom buttons
          if (!_loading && _caregiverId != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomButtons(context),
            ),
        ],
      ),
    );
  }

  // ── Title row: back + "Caregiver profile" ────────────────
  Widget _buildTitleRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 22, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: darkGreen, size: 22),
          ),
          const SizedBox(width: 12),
          const Text(
            'Caregiver profile',
            style: TextStyle(
              fontFamily: 'Open Sans',
              color: darkGreen,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Avatar + name + subtitle + availability badge ─────────
  Widget _buildProfileHeader() {
    final name = (_caregiver?['name'] as String?)?.trim() ?? '';
    final photoUrl = (_caregiver?['photoUrl'] as String?)?.trim();
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
    final distanceKm = _caregiver?['distanceKm'];
    final subtitle = [
      if (careTypes.isNotEmpty) careTypes.join(', '),
      if (city != null && city.isNotEmpty) city,
      if (distanceKm != null) '$distanceKm km',
    ].join(' · ');
    final isAvailable = _caregiver?['available'] != false;

    return Center(
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF94A3B8),
            ),
            child: (photoUrl != null && photoUrl.isNotEmpty)
                ? ClipOval(
                    child: RemoteOrLocalImage(
                      source: photoUrl,
                      width: 76,
                      height: 76,
                      fit: BoxFit.cover,
                    ),
                  )
                : Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF20385B),
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          Text(
            name.isEmpty ? 'Unnamed caregiver' : name,
            style: const TextStyle(
              fontFamily: 'Open Sans',
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Open Sans',
                color: Color(0xFF94A3B8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (isAvailable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: availableBadgeBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: availableAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Available now',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: availableAccent,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Stat boxes: years exp, rating, jobs done ──────────────
  Widget _buildStatsRow() {
    final yearsExperience = _caregiver?['yearsExperience'];
    final rating = _caregiver?['rating'];
    final jobsDone = _caregiver?['jobsDone'];
    return Row(
      children: [
        Expanded(
          child: _statBox(
            yearsExperience?.toString() ?? '—',
            'Yrs exp',
            valueColor: darkGreen,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statBox(
            rating?.toString() ?? '—',
            'Rating',
            valueColor: const Color(0xFFE04913),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statBox(
            jobsDone?.toString() ?? '—',
            'Jobs done',
            valueColor: darkGreen,
          ),
        ),
      ],
    );
  }

  Widget _statBox(String value, String label, {required Color valueColor}) {
    return Container(
      height: 66,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: statBoxBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Open Sans',
              color: valueColor,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Open Sans',
              color: statLabel,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Match breakdown card (only when scoring data is passed in) ─
  Widget _buildMatchBreakdownCard() {
    final breakdown = _matchBreakdown!;
    final overall = breakdown['overall'] ?? 0;
    const metrics = [
      ('skillMatch', 'Skill match'),
      ('experience', 'Experience'),
      ('availability', 'Availability'),
      ('proximity', 'Proximity'),
      ('feedback', 'Feedback'),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: matchCardBg,
        border: Border.all(color: matchCardBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your match breakdown',
                style: TextStyle(
                  color: Color(0xFFF8FAFC),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$overall%',
                style: const TextStyle(
                  color: Color(0xFFC7C7C5),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final (key, label) in metrics) ...[
            _matchBar(label, (breakdown[key] as num?)?.toInt() ?? 0),
            if (key != metrics.last.$1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _matchBar(String label, int percent) {
    final clamped = percent.clamp(0, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5, fontWeight: FontWeight.w500),
            ),
            Text(
              '$clamped%',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(height: 6, width: double.infinity, color: barTrack),
                  Container(
                    height: 6,
                    width: constraints.maxWidth * clamped / 100,
                    color: barFill,
                  ),
                ],
              );
            },
          ),
        ),
      ],
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
            fontFamily: 'Open Sans',
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        if (skills.isEmpty)
          const Text(
            'No skills listed yet.',
            style: TextStyle(
              color: Color(0xFF94A3B8),
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
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: chipBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: chipText,
          fontSize: 12,
          fontWeight: FontWeight.w600,
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
            fontFamily: 'Open Sans',
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          bio.isEmpty ? 'No bio provided yet.' : bio,
          style: const TextStyle(
            color: bodyText,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  // ── Reviews section ───────────────────────────────────────
  Widget _buildReviewsSection(BuildContext context, List<Map<String, dynamic>> reviews) {
    final hasReviews = reviews.isNotEmpty;
    final ratings = reviews
        .map((r) => (r['rating'] as num?)?.toDouble())
        .whereType<double>()
        .toList();
    final avgRating = ratings.isEmpty ? null : ratings.reduce((a, b) => a + b) / ratings.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Reviews',
              style: TextStyle(
                fontFamily: 'Open Sans',
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            // Nothing to see in full if there are no reviews yet.
            if (hasReviews)
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/caregiver-reviews',
                    arguments: {'caregiverId': _caregiverId},
                  );
                },
                child: const Text(
                  'See all',
                  style: TextStyle(
                    color: darkGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (!hasReviews)
          const EmptyState(
            icon: Icons.rate_review_outlined,
            message: 'No reviews yet.',
          )
        else
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFBBC05), size: 18),
              const SizedBox(width: 4),
              Text(
                avgRating == null ? '—' : avgRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontFamily: 'Open Sans',
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'from ${reviews.length} review${reviews.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontFamily: 'Open Sans',
                  color: bodyText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
      ],
    );
  }

  // ── Bottom sticky buttons ──────────────────────────────────
  Widget _buildBottomButtons(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            bgCream.withValues(alpha: 0.0),
            bgCream,
          ],
          stops: const [0.0, 0.25],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
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
                    border: Border.all(color: darkGreen, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Leave a review',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: darkGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Filled "Send booking request" button
            Material(
              color: darkGreen,
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: const Text(
                    'Send booking request',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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
