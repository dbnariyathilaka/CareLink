import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../app_state.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/caregiver_service.dart';
import '../widgets/patient_notification_badge.dart';
import '../widgets/remote_or_local_image.dart';
import '../widgets/status_bar.dart';

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
  final String? caregiverId;
  final String? photoUrl;
  final int? ratingStars;
  final String? requestSentAgo;
  final String? cancelReason;
  final String? bookingId;
  final bool isPaid;
  final DateTime? paymentDeadline;
  final VoidCallback? onMessage;
  final VoidCallback? onRebook;
  final VoidCallback? onCancel;
  final VoidCallback? onPayNow;

  const _Booking({
    required this.caregiverName,
    required this.initials,
    required this.subtitle,
    required this.status,
    this.caregiverId,
    this.photoUrl,
    this.ratingStars,
    this.requestSentAgo,
    this.cancelReason,
    this.bookingId,
    this.isPaid = false,
    this.paymentDeadline,
    this.onMessage,
    this.onRebook,
    this.onCancel,
    this.onPayNow,
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
    setStatusBarStyle(Brightness.dark);
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

  // 'confirmed' is the real status BookingService.respondToRequest writes
  // when a caregiver accepts — it belongs in the "Upcoming" bucket here.
  // 'upcoming'/'ongoing' are kept too since they're the display names used
  // elsewhere on this screen, in case that ever changes to write them
  // directly, but nothing currently persists those strings to Firestore.
  _BookingStatus _statusFromString(String s) {
    switch (s) {
      case 'confirmed':
      case 'upcoming':
        return _BookingStatus.upcoming;
      case 'ongoing':
        return _BookingStatus.ongoing;
      case 'completed':
        return _BookingStatus.completed;
      case 'cancelled':
        return _BookingStatus.cancelled;
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

  String _formatClock(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  final Map<String, String?> _caregiverPhotos = {};

  Future<String?> _resolveCaregiverPhoto(String? caregiverId) async {
    if (caregiverId == null || caregiverId.isEmpty) return null;
    if (_caregiverPhotos.containsKey(caregiverId)) return _caregiverPhotos[caregiverId];
    final profile = await CaregiverService.getCaregiverProfile(caregiverId);
    final photo = (profile?['photoUrl'] as String?)?.trim();
    final result = (photo != null && photo.isNotEmpty) ? photo : null;
    _caregiverPhotos[caregiverId] = result;
    return result;
  }

  _Booking _bookingFromDoc(Map<String, dynamic> doc) {
    final name = doc['caregiverName'] as String? ?? 'Caregiver';
    final caregiverId = doc['caregiverId'] as String?;
    final photoUrl = (doc['caregiverPhotoUrl'] as String?)?.trim();
    final status = _statusFromString(doc['status'] as String? ?? 'requested');
    final createdAt = doc['createdAt'];
    final sentAgo = createdAt is Timestamp ? _timeAgo(createdAt.toDate()) : null;
    final cancellable = status == _BookingStatus.requested ||
        status == _BookingStatus.upcoming;
    final onMessage = status != _BookingStatus.requested && status != _BookingStatus.cancelled
        ? () => Navigator.pushNamed(
              context,
              '/patient-chat',
              arguments: {
                'bookingId': doc['id'],
                'caregiverId': caregiverId,
                'caregiverName': name,
                'caregiverPhotoUrl': photoUrl,
                'status': doc['status'],
              },
            )
        : null;
    final onRebook = caregiverId != null
        ? () => Navigator.pushNamed(
              context,
              '/caregiver-profile',
              arguments: {'caregiverId': caregiverId},
            )
        : null;
    final bookingId = doc['id'] as String?;
    final careType = doc['careType'] as String?;
    final isPaid = doc['paymentStatus'] == 'paid';
    final paymentDeadline = createdAt is Timestamp
        ? createdAt.toDate().add(BookingService.paymentDeadline)
        : null;
    final onPayNow = (status == _BookingStatus.upcoming && !isPaid && bookingId != null)
        ? () => Navigator.pushNamed(
              context,
              '/payhere-checkout',
              arguments: {
                'bookingId': bookingId,
                'caregiverId': caregiverId,
                'caregiverName': name,
                'careType': careType,
                // No hourly rate is stored on a booking yet — matches the
                // flat per-booking estimate used elsewhere (dashboard,
                // notifications "Pay here").
                'amount': 5000,
              },
            )
        : null;
    return _Booking(
      caregiverName: name,
      caregiverId: caregiverId,
      photoUrl: photoUrl,
      initials: _initialsFor(name),
      subtitle: careType ?? '',
      status: status,
      ratingStars: (doc['rating'] as num?)?.toInt(),
      requestSentAgo: sentAgo,
      cancelReason: doc['cancelReason'] as String?,
      bookingId: bookingId,
      isPaid: isPaid,
      paymentDeadline: paymentDeadline,
      onMessage: onMessage,
      onRebook: onRebook,
      onCancel: cancellable ? () => _showRequestDetailsDialog(doc) : null,
      onPayNow: onPayNow,
    );
  }

  // ── "Request details" popup (Figma node 218-185) — shown first when the
  // patient taps "Cancel request", before the actual cancel-confirmation
  // sheet, so they can double check what they're about to cancel. ─
  void _showRequestDetailsDialog(Map<String, dynamic> doc) {
    final id = doc['id'] as String;
    final name = (doc['caregiverName'] as String?) ?? 'Caregiver';
    final careType = doc['careType'] as String? ?? '';
    final startDate = doc['startDate'] as String? ?? '';
    final startTime = doc['startTime'] as String? ?? '';
    final duration = doc['duration'] as String?;
    final endDate = doc['endDate'] as String?;
    final endTime = doc['endTime'] as String?;
    final location = doc['location'] as String? ?? '';
    final hasDuration = duration != null && duration.isNotEmpty;

    final rows = <MapEntry<String, String>>[
      if (startDate.isNotEmpty) MapEntry('Start date', startDate),
      if (startTime.isNotEmpty) MapEntry('Start time', startTime),
      if (hasDuration) MapEntry('Duration', duration),
      if (endDate != null && endDate.isNotEmpty) MapEntry('End date', endDate),
      if (!hasDuration && endTime != null && endTime.isNotEmpty)
        MapEntry('End time', endTime),
      if (location.isNotEmpty) MapEntry('Location', location),
      if (careType.isNotEmpty) MapEntry('Work schedule', careType),
    ];

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5EEE8),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.fromLTRB(26, 16, 26, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(dialogCtx),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.close_rounded,
                      color: Color(0xFFA82222),
                      size: 26,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(58, 73, 69, 0.37),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  children: List.generate(rows.length, (i) {
                    final isLast = i == rows.length - 1;
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: isLast
                          ? null
                          : const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Color.fromRGBO(70, 86, 81, 0.61),
                                  width: 1,
                                ),
                              ),
                            ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            rows[i].key,
                            style: const TextStyle(
                              fontFamily: 'Open Sans',
                              color: Color(0xFF1E293B),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Expanded so a long value (e.g. a full address)
                          // wraps onto multiple lines instead of
                          // overflowing past the dialog's right edge.
                          Expanded(
                            child: Text(
                              rows[i].value,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontFamily: 'Open Sans',
                                color: Color(0xFF312960),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: const Color(0xFFE9BDBD),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          Navigator.pop(dialogCtx);
                          _confirmCancel(
                            bookingId: id,
                            caregiverName: name,
                            careType: careType,
                            startDate: startDate,
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 11),
                          child: Text(
                            'Cancel request',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Open Sans',
                              color: Color(0xFFEF4444),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 17),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => Navigator.pop(dialogCtx),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF1E293B), width: 2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Back',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Open Sans',
                              color: Color(0xFF1E293B),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── "Cancel this request?" bottom sheet (Figma node 275-2195) ─
  void _confirmCancel({
    required String bookingId,
    required String caregiverName,
    required String careType,
    required String startDate,
  }) {
    final details = [careType, startDate].where((s) => s.isNotEmpty).join(' · ');
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5EEE8),
          border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1)),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
          ),
        ),
        padding: EdgeInsets.only(
          left: 22,
          right: 22,
          top: 14,
          // viewInsets covers the keyboard; padding.bottom covers the
          // on-screen nav bar. Missing the latter is why the button and
          // "Keep request" text were getting clipped by it.
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom +
              MediaQuery.of(sheetCtx).padding.bottom +
              24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF475569),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 21),
            Image.asset(
              'assets/images/cancel_request_icon.png',
              width: 73,
              height: 73,
              errorBuilder: (_, _, _) => Container(
                width: 73,
                height: 73,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 36),
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'Cancel this request?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Open Sans',
                color: Color(0xFF1E293B),
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                style: const TextStyle(
                  fontFamily: 'Open Sans',
                  color: Color.fromRGBO(0, 0, 0, 0.64),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: "You're about to cancel your booking request to "),
                  TextSpan(
                    text: caregiverName,
                    style: const TextStyle(color: Color(0xFF1E293B)),
                  ),
                  if (details.isNotEmpty) TextSpan(text: '. $details'),
                  const TextSpan(text: '. The caregiver will be notified.'),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                border: Border.all(color: const Color(0xFF334155)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.event_available_rounded, color: Color(0xFF94A3B8), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Free to cancel now — this request hasn't been accepted "
                      "yet, so no cancellation fee applies.",
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        color: Color(0xFFCBD5E1),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.pop(sheetCtx);
                BookingService.cancelBooking(bookingId);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Text(
                  'Yes, cancel request',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.pop(sheetCtx),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Text(
                  'Keep request',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Color.fromRGBO(30, 41, 59, 0.68),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _bookingsStream,
                builder: (context, snapshot) {
                  final docs = snapshot.data ?? const [];
                  final allBookings = docs.map(_bookingFromDoc).toList();

                  // No requests at all yet — filter tabs have nothing to
                  // filter, so skip straight to the welcoming empty state.
                  if (allBookings.isEmpty) {
                    return _buildEmptyBookingsState(
                      title: 'No bookings yet',
                      body: "You haven't sent any care requests yet. Find a "
                          "caregiver from your top 5 matches and send your "
                          "first request.",
                      showActions: true,
                    );
                  }

                  final bookings = _applyFilter(allBookings);
                  final isFilteredEmpty = bookings.isEmpty;
                  return Column(
                    children: [
                      _buildFilterTabs(),
                      const SizedBox(height: 10),
                      Expanded(
                        child: isFilteredEmpty
                            ? _buildEmptyBookingsState(
                                title: _emptyTitleFor(_selectedFilter),
                                body: _emptyBodyFor(_selectedFilter),
                                showActions: false,
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(13, 0, 12, 20),
                                itemCount: bookings.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 14),
                                itemBuilder: (_, i) => _buildBookingCard(bookings[i]),
                              ),
                      ),
                    ],
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

  String _emptyTitleFor(_BookingFilter filter) {
    switch (filter) {
      case _BookingFilter.all:
        return 'No bookings yet';
      case _BookingFilter.upcoming:
        return 'No upcoming bookings';
      case _BookingFilter.requested:
        return 'No requested bookings';
      case _BookingFilter.past:
        return 'No past bookings';
      case _BookingFilter.cancelled:
        return 'No cancelled bookings';
    }
  }

  String _emptyBodyFor(_BookingFilter filter) {
    switch (filter) {
      case _BookingFilter.all:
        return "You haven't sent any care requests yet. Find a caregiver "
            "from your top 5 matches and send your first request.";
      case _BookingFilter.upcoming:
        return "You don't have any upcoming visits scheduled right now.";
      case _BookingFilter.requested:
        return "You don't have any pending requests right now.";
      case _BookingFilter.past:
        return "You don't have any completed bookings yet.";
      case _BookingFilter.cancelled:
        return "You don't have any cancelled bookings.";
    }
  }

  // ── Empty state (illustrated) ──────────────────────────────
  static const String _emptyBookingsGif = 'assets/images/empty_bookings.webp';

  Widget _buildEmptyBookingsState({
    required String title,
    required String body,
    required bool showActions,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          SizedBox(
            width: 220,
            height: 220,
            child: Image.asset(
              _emptyBookingsGif,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.event_available_rounded,
                color: Color(0xFFAAA897),
                size: 120,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Open Sans',
              color: Color(0xFF462911),
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color.fromRGBO(39, 34, 77, 0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.6,
            ),
          ),
          if (showActions) ...[
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/search'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFFAAA897),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Find a caregiver',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF462911),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Your matches refresh automatically if no one responds.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Open Sans',
                color: Color.fromRGBO(33, 43, 57, 0.83),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.38,
              ),
            ),
          ],
        ],
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
              ClipOval(
                child: (b.photoUrl != null && b.photoUrl!.isNotEmpty)
                    ? RemoteOrLocalImage(
                        source: b.photoUrl!,
                        width: 42,
                        height: 42,
                        fit: BoxFit.cover,
                      )
                    : (b.caregiverId != null && b.caregiverId!.isNotEmpty)
                        ? FutureBuilder<String?>(
                            future: _resolveCaregiverPhoto(b.caregiverId),
                            builder: (context, snap) {
                              final photo = snap.data;
                              if (photo != null && photo.isNotEmpty) {
                                return RemoteOrLocalImage(
                                  source: photo,
                                  width: 42,
                                  height: 42,
                                  fit: BoxFit.cover,
                                );
                              }
                              return Container(
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
                              );
                            },
                          )
                        : Container(
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
                    // Figma node 769:632 — only shown for an unpaid upcoming
                    // booking, using the real 6-hour auto-cancel deadline
                    // (BookingService.paymentDeadline) rather than a
                    // hardcoded example time.
                    if (b.status == _BookingStatus.upcoming &&
                        !b.isPaid &&
                        b.paymentDeadline != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Make the payment before ${_formatClock(b.paymentDeadline!)}',
                        style: const TextStyle(
                          fontFamily: 'Open Sans',
                          color: Color(0xFFB7694D),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
        return Text(
          b.cancelReason ?? 'No review · Cancelled',
          style: const TextStyle(
            fontFamily: 'Open Sans',
            color: Color(0xFF6E6F72),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        );

      case _BookingStatus.requested:
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

      // Figma nodes 769:599 ("Paid") / 769:632 ("Payment Due") — now a real
      // split on paymentStatus instead of the unified placeholder this used
      // to show before the sandbox PayHere checkout existed.
      case _BookingStatus.upcoming:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (b.isPaid)
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: Color(0xFFBA4242), size: 6),
                  SizedBox(width: 5),
                  Text(
                    'Paid',
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      color: Color(0xFFBA4242),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            else
              Material(
                color: const Color(0xFF973D3D),
                borderRadius: BorderRadius.circular(17),
                child: InkWell(
                  borderRadius: BorderRadius.circular(17),
                  onTap: b.onPayNow,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    child: Text(
                      'Payment Due',
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
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
      color: darkGreen,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 67,
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
                      index == 4
                          ? PatientNotificationIconWithBadge(
                              icon: Icon(item.icon, color: color, size: 25),
                              badgeBorderColor: darkGreen,
                            )
                          : Icon(item.icon, color: color, size: 25),
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
        ),
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
