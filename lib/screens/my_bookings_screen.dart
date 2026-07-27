import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../app_state.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../widgets/empty_state.dart';

// ─────────────────────────────────────────────────────────────
//  My Bookings Screen  (Patient)
//  Figma node: 218-184
// ─────────────────────────────────────────────────────────────

enum _BookingStatus { ongoing, completed, cancelled, requested, upcoming }

enum _BookingFilter { all, upcoming, requested, past, cancelled }

class _Booking {
  final String caregiverName;
  final String initials;
  final String subtitle;
  final _BookingStatus status;
  final bool isActiveNow;
  final int? ratingStars;
  final String? requestSentAgo;
  final VoidCallback? onMessage;
  final VoidCallback? onRebook;
  final VoidCallback? onCancel;

  const _Booking({
    required this.caregiverName,
    required this.initials,
    required this.subtitle,
    required this.status,
    this.isActiveNow = false,
    this.ratingStars,
    this.requestSentAgo,
    this.onMessage,
    this.onRebook,
    this.onCancel,
  });
}

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  static const Color bgCream = Color(0xFFF5EEDE);
  static const Color darkGreen = Color(0xFF06402B);
  static const Color cardBg = Color(0xFFBAADA1);
  static const Color cardDivider = Color.fromRGBO(0, 0, 0, 0.1);
  static const Color tabActive = Color(0xFFC56322);
  static const Color tabInactive = Color.fromRGBO(0, 0, 0, 0.53);
  static const Color navHomeLabel = Color(0xFFFEE269);
  static const Color navMatchLabel = Color(0xFFFFA722);

  _BookingFilter _selectedFilter = _BookingFilter.all;

  late final AnimationController _matchIconController;
  late final Animation<double> _matchIconRotation;

  Stream<List<Map<String, dynamic>>>? _bookingsStream;

  @override
  void initState() {
    super.initState();
    final uid = AuthService.currentUser?.uid;
    if (uid != null) {
      _bookingsStream = BookingService.streamBookingsForPatient(uid);
    }
    _matchIconController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _matchIconRotation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 2),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 6,
      ),
    ]).animate(_matchIconController);
  }

  @override
  void dispose() {
    _matchIconController.dispose();
    super.dispose();
  }

  List<_Booking> _applyFilter(List<_Booking> bookings) {
    switch (_selectedFilter) {
      case _BookingFilter.all:
        return bookings;
      case _BookingFilter.upcoming:
        return bookings.where((b) => b.status == _BookingStatus.upcoming).toList();
      case _BookingFilter.requested:
        return bookings.where((b) => b.status == _BookingStatus.requested).toList();
      case _BookingFilter.past:
        return bookings.where((b) => b.status == _BookingStatus.completed).toList();
      case _BookingFilter.cancelled:
        return bookings.where((b) => b.status == _BookingStatus.cancelled).toList();
    }
  }

  _BookingStatus _statusFromString(String s) {
    switch (s) {
      case 'ongoing':
        return _BookingStatus.ongoing;
      case 'completed':
        return _BookingStatus.completed;
      case 'cancelled':
        return _BookingStatus.cancelled;
      case 'upcoming':
        return _BookingStatus.upcoming;
      case 'requested':
      default:
        return _BookingStatus.requested;
    }
  }

  String _initialsFor(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  _Booking _bookingFromDoc(Map<String, dynamic> doc) {
    final id = doc['id'] as String;
    final name = doc['caregiverName'] as String? ?? 'Caregiver';
    final status = _statusFromString(doc['status'] as String? ?? 'requested');
    final createdAt = doc['createdAt'];
    final sentAgo = createdAt is Timestamp ? _timeAgo(createdAt.toDate()) : null;
    final cancellable = status == _BookingStatus.requested ||
        status == _BookingStatus.upcoming;
    return _Booking(
      caregiverName: name,
      initials: _initialsFor(name),
      subtitle: doc['careType'] as String? ?? '',
      status: status,
      requestSentAgo: sentAgo,
      onCancel: cancellable ? () => _confirmCancel(id) : null,
    );
  }

  void _confirmCancel(String bookingId) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgCream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Cancel request?',
          style: TextStyle(
            fontFamily: 'Open Sans',
            color: darkGreen,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'The caregiver will no longer be notified about this request.',
          style: TextStyle(fontFamily: 'Open Sans', color: darkGreen),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep it', style: TextStyle(color: darkGreen)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              BookingService.cancelBooking(bookingId);
            },
            child: const Text(
              'Cancel request',
              style: TextStyle(color: Color(0xFFBA4242), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterTabs(),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _bookingsStream,
                builder: (context, snapshot) {
                  final docs = snapshot.data ?? const [];
                  final bookings =
                      _applyFilter(docs.map(_bookingFromDoc).toList());
                  if (bookings.isEmpty) {
                    return EmptyState(
                      icon: Icons.event_available_rounded,
                      iconColor: darkGreen,
                      textColor: darkGreen.withValues(alpha: 0.7),
                      message: _selectedFilter == _BookingFilter.all
                          ? "You haven't sent any care requests yet. Search for "
                              "a caregiver and send your first request."
                          : "No bookings in this category yet.",
                      actionLabel: _selectedFilter == _BookingFilter.all
                          ? 'Find a caregiver'
                          : null,
                      onAction: _selectedFilter == _BookingFilter.all
                          ? () => Navigator.pushNamed(context, '/search')
                          : null,
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(13, 0, 12, 20),
                    itemCount: bookings.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (_, i) => _buildBookingCard(bookings[i]),
                  );
                },
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────
  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(22, 22, 22, 0),
      child: Text(
        'My bookings',
        style: TextStyle(
          fontFamily: 'Open Sans',
          color: darkGreen,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ── Filter tabs ────────────────────────────────────────────
  Widget _buildFilterTabs() {
    final tabs = [
      (filter: _BookingFilter.all, label: 'All'),
      (filter: _BookingFilter.upcoming, label: 'Upcoming'),
      (filter: _BookingFilter.requested, label: 'Requested'),
      (filter: _BookingFilter.past, label: 'Past'),
      (filter: _BookingFilter.cancelled, label: 'Cancelled'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
      child: Row(
        children: List.generate(tabs.length * 2 - 1, (i) {
          if (i.isOdd) return const SizedBox(width: 18);
          final tab = tabs[i ~/ 2];
          final isActive = tab.filter == _selectedFilter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = tab.filter),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Text(
                tab.label,
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: isActive ? tabActive : tabInactive,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Booking card ───────────────────────────────────────────
  Widget _buildBookingCard(_Booking b) {
    final style = _statusStyle(b.status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: style.avatarColor,
                  gradient: style.avatarGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    b.initials,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: style.avatarTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.caregiverName,
                      style: const TextStyle(
                        fontFamily: 'Open Sans',
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      b.subtitle,
                      style: const TextStyle(
                        fontFamily: 'Open Sans',
                        color: Color.fromRGBO(0, 0, 0, 0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: style.pillBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  style.label,
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    color: style.pillText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 11),
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: cardDivider, width: 1)),
            ),
            child: _buildCardFooter(b),
          ),
        ],
      ),
    );
  }

  Widget _buildCardFooter(_Booking b) {
    switch (b.status) {
      case _BookingStatus.ongoing:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF6A441E),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'Active now',
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    color: Color(0xFF6A441E),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: b.onMessage,
              child: const Row(
                children: [
                  Icon(Icons.chat_bubble, color: Colors.black, size: 16),
                  SizedBox(width: 5),
                  Text(
                    'Message',
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case _BookingStatus.completed:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '★' * (b.ratingStars ?? 5),
              style: const TextStyle(
                color: Color(0xFFFFBE00),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            GestureDetector(
              onTap: b.onRebook,
              child: Text(
                'Re-book ${b.caregiverName.split(' ').first}',
                style: const TextStyle(
                  fontFamily: 'Open Sans',
                  color: Color(0xFF69670F),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );

      case _BookingStatus.cancelled:
        return const Text(
          'No review · Cancelled',
          style: TextStyle(
            fontFamily: 'Open Sans',
            color: Color(0xFF6E6F72),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        );

      case _BookingStatus.requested:
      case _BookingStatus.upcoming:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Awaiting response · sent ${b.requestSentAgo ?? '—'}',
              style: const TextStyle(
                fontFamily: 'Open Sans',
                color: Color(0xFF6E6F72),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            GestureDetector(
              onTap: b.onCancel,
              child: const Text(
                'Cancel request',
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  color: Color(0xFFBA4242),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
    }
  }

  _StatusStyle _statusStyle(_BookingStatus status) {
    switch (status) {
      case _BookingStatus.ongoing:
        return const _StatusStyle(
          label: 'Ongoing',
          pillBg: Color(0xFFCAAB8C),
          pillText: Color(0xFF6A441E),
          avatarColor: Color(0xFF76A78C),
          avatarTextColor: Color(0xFF1B412C),
        );
      case _BookingStatus.completed:
        return _StatusStyle(
          label: 'Completed',
          pillBg: const Color(0xFFBCBB83),
          pillText: const Color(0xFF69670F),
          avatarGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          ),
          avatarTextColor: const Color(0xFF3B2406),
        );
      case _BookingStatus.cancelled:
        return const _StatusStyle(
          label: 'Cancelled',
          pillBg: Color.fromRGBO(239, 68, 68, 0.15),
          pillText: Color(0xFFA52828),
          avatarColor: Color(0xFF334155),
          avatarTextColor: Color(0xFF94A3B8),
        );
      case _BookingStatus.requested:
        return _StatusStyle(
          label: 'Requested',
          pillBg: const Color(0xFF869CB4),
          pillText: const Color(0xFF25374B),
          avatarGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
          ),
          avatarTextColor: const Color(0xFF42413F),
        );
      case _BookingStatus.upcoming:
        return _StatusStyle(
          label: 'Upcoming',
          pillBg: const Color(0xFFB590BC),
          pillText: const Color(0xFF370D3F),
          avatarGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
          ),
          avatarTextColor: const Color(0xFF42413F),
        );
    }
  }

  // ── Bottom nav (matches dashboard/search) ─────────────────
  Widget _buildBottomBar() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        _buildBottomNav(),
        Positioned(top: -22, child: _buildMatchFab()),
      ],
    );
  }

  Widget _buildBottomNav() {
    final items = [
      (icon: Icons.home_rounded, label: 'Home', route: '/patient-dashboard'),
      (icon: Icons.search_rounded, label: 'Search', route: '/search'),
      (icon: null, label: 'Match', route: null),
      (icon: Icons.calendar_month_outlined, label: 'Booking', route: null),
      (icon: Icons.notifications_none_rounded, label: 'Notification', route: '/notifications'),
    ];
    return Container(
      width: double.infinity,
      height: 67,
      color: darkGreen,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(items.length, (index) {
          final item = items[index];

          if (index == 2) {
            return const SizedBox(
              width: 60,
              child: Padding(
                padding: EdgeInsets.only(top: 41),
                child: Text(
                  'Match',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Quattrocento Sans',
                    color: navMatchLabel,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }

          // "Booking" tab is the current screen.
          final color = index == 3
              ? navHomeLabel
              : Colors.white;
          return GestureDetector(
            onTap: item.route != null
                ? () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      item.route!,
                      (route) => route.settings.name == '/patient-dashboard',
                    )
                : null,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 60,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, color: color, size: 25),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontFamily: 'Quattrocento Sans',
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMatchFab() {
    return GestureDetector(
      onTap: () {
        if (AppState.hasActiveMatch.value) {
          Navigator.pushNamed(context, '/advanced-match-results');
        } else {
          Navigator.pushNamed(context, '/advanced-match-send-request');
        }
      },
      child: Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: RotationTransition(
          turns: _matchIconRotation,
          child: SvgPicture.asset(
            'assets/images/match_target_icon.svg',
            width: 65,
            height: 65,
          ),
        ),
      ),
    );
  }
}

class _StatusStyle {
  final String label;
  final Color pillBg;
  final Color pillText;
  final Color? avatarColor;
  final Gradient? avatarGradient;
  final Color avatarTextColor;

  const _StatusStyle({
    required this.label,
    required this.pillBg,
    required this.pillText,
    this.avatarColor,
    this.avatarGradient,
    required this.avatarTextColor,
  });
}
