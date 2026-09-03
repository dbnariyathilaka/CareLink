import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'patient_service.dart';

/// Thin wrapper around the `bookingRequests` Firestore collection — each
/// document is one patient→caregiver care request, from the moment it's
/// sent through to acceptance/completion/cancellation.
class BookingService {
  BookingService._();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('bookingRequests');

  // A cancelled booking is archived here (reduced fields) and then deleted
  // from bookingRequests, rather than lingering there forever as
  // status: 'cancelled' — keeps the live collection to only requests that
  // are still actually pending/active.
  static CollectionReference<Map<String, dynamic>> get _cancelledCollection =>
      _firestore.collection('cancelledBookings');

  static Future<void> createBookingRequest({
    required String patientUid,
    String? caregiverId,
    required String caregiverName,
    required String careType,
    required String startDate,
    required String startTime,
    String? endTime,
    String? duration,
    String? endDate,
    required String location,
    double? locationLat,
    double? locationLng,
    bool isAdvanced = false,
    bool isEmergency = false,
  }) async {
    await _collection.add({
      'patientUid': patientUid,
      'caregiverId': caregiverId,
      'caregiverName': caregiverName,
      'careType': careType,
      'startDate': startDate,
      'startTime': startTime,
      'endTime': endTime,
      'duration': duration,
      'endDate': endDate,
      'location': location,
      if (locationLat != null) 'locationLat': locationLat,
      if (locationLng != null) 'locationLng': locationLng,
      'isAdvanced': isAdvanced,
      'isEmergency': isEmergency,
      'status': 'requested',
      'arrivalConfirmed': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    // Best-effort care-circle activity log — never block the booking on it.
    unawaited(PatientService.logActivity(
      patientUid,
      '$caregiverName requested for $startDate at $startTime',
      icon: 'event_available',
    ));
  }

  /// Merges the live `bookingRequests` for this patient with their archived
  /// `cancelledBookings` — cancelling deletes a doc from the former and
  /// writes a reduced copy to the latter (see [cancelBooking]), so callers
  /// that want the full history (e.g. the "Cancelled" tab in My Bookings)
  /// need both sources combined into one stream. Sorted client-side
  /// (newest first) to avoid requiring composite Firestore indexes.
  static Stream<List<Map<String, dynamic>>> streamBookingsForPatient(
    String patientUid,
  ) {
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();
    List<Map<String, dynamic>>? active;
    List<Map<String, dynamic>>? cancelled;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? activeSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? cancelledSub;

    void emit() {
      if (active == null || cancelled == null) return;
      final combined = [...active!, ...cancelled!];
      combined.sort((a, b) {
        final at = (a['createdAt'] ?? a['cancelledAt']);
        final bt = (b['createdAt'] ?? b['cancelledAt']);
        if (at is! Timestamp || bt is! Timestamp) return 0;
        return bt.compareTo(at);
      });
      controller.add(combined);
    }

    controller.onListen = () {
      activeSub = _collection
          .where('patientUid', isEqualTo: patientUid)
          .snapshots()
          .listen((snap) {
        active = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        _enforcePaymentDeadline(active!);
        emit();
      }, onError: (_) {
        // e.g. permission-denied right as the auth token is revoked on
        // logout, while this screen is still mid-teardown — nothing to
        // recover here, just don't let it become an unhandled stream error.
      });
      cancelledSub = _cancelledCollection
          .where('patientUid', isEqualTo: patientUid)
          .snapshots()
          .listen((snap) {
        cancelled = snap.docs
            .map((d) => {'id': d.id, 'status': 'cancelled', ...d.data()})
            .toList();
        emit();
      }, onError: (_) {});
    };
    controller.onCancel = () {
      activeSub?.cancel();
      cancelledSub?.cancel();
    };
    return controller.stream;
  }

  /// A request gives the caregiver (accept/decline) and then the patient
  /// (pay) 6 hours from when it was originally sent — the same window
  /// `confirm_booking_screen.dart` already tells the patient about
  /// ("$caregiverName has 6 hours to accept this request.") but that
  /// nothing previously enforced. Past that deadline, a booking that's
  /// still just 'requested' (caregiver never responded) or 'confirmed' but
  /// unpaid (patient never completed checkout) is stale and auto-cancels —
  /// whichever side dropped the ball.
  // Public so screens (e.g. my_bookings_screen's "Make the payment before…"
  // caption) can show the real deadline instead of a value that could drift
  // from what actually triggers the auto-cancel below.
  static const Duration paymentDeadline = Duration(hours: 6);

  static bool _isPastPaymentDeadline(Map<String, dynamic> b) {
    final status = b['status'] as String?;
    if (status != 'requested' && status != 'confirmed') return false;
    if (status == 'confirmed' && b['paymentStatus'] == 'paid') return false;
    final createdAt = b['createdAt'];
    if (createdAt is! Timestamp) return false;
    return DateTime.now().difference(createdAt.toDate()) > paymentDeadline;
  }

  // Multiple screens (dashboard, notifications, my-bookings) can each hold
  // their own streamBookingsForPatient subscription at once — this guards
  // against two of them racing to archive the same stale booking twice.
  static final Set<String> _cancelling = {};

  /// Fire-and-forget: auto-cancels any booking in [bookings] that blew past
  /// [_paymentDeadline] without being both confirmed and paid. Only the
  /// owning patient's client can actually perform the cancel (Firestore
  /// rules restrict delete to `patientUid == request.auth.uid`), so this is
  /// only wired into [streamBookingsForPatient] — enforcement happens
  /// lazily, the next time that patient's app is open and streams their
  /// bookings, since there's no server/cron in this app to do it while
  /// no one is looking.
  static void _enforcePaymentDeadline(List<Map<String, dynamic>> bookings) {
    for (final b in bookings) {
      if (!_isPastPaymentDeadline(b)) continue;
      final id = b['id'] as String?;
      if (id == null || _cancelling.contains(id)) continue;
      _cancelling.add(id);
      final reason = b['status'] == 'requested'
          ? 'Auto-cancelled — the caregiver did not respond within 6 hours of the request.'
          : 'Auto-cancelled — payment was not completed within 6 hours of the request.';
      unawaited(cancelBooking(id, reason: reason).whenComplete(() => _cancelling.remove(id)));
    }
  }

  /// Archives a reduced copy of the booking (enough to still render a
  /// "Cancelled" card) to cancelledBookings, then deletes the live doc —
  /// cancelling removes the request from the active collection entirely
  /// rather than leaving it there forever with status: 'cancelled'.
  static Future<void> cancelBooking(String bookingId, {String? reason}) async {
    final doc = _collection.doc(bookingId);
    final snap = await doc.get();
    final data = snap.data();
    if (data != null) {
      await _cancelledCollection.add({
        'patientUid': data['patientUid'],
        'caregiverId': data['caregiverId'],
        'caregiverName': data['caregiverName'],
        'careType': data['careType'],
        'startDate': data['startDate'],
        'startTime': data['startTime'],
        'endTime': data['endTime'],
        'duration': data['duration'],
        'endDate': data['endDate'],
        'location': data['location'],
        'originalBookingId': bookingId,
        'createdAt': data['createdAt'],
        'cancelledAt': FieldValue.serverTimestamp(),
        if (reason != null) 'cancelReason': reason,
      });
    }
    await doc.delete();
  }

  /// Caregiver's response to a direct booking request — the real
  /// accept/decline action behind the caregiver's bookings screen.
  static Future<void> respondToRequest(String bookingId, {required bool accept}) {
    return _collection.doc(bookingId).update({
      'status': accept ? 'confirmed' : 'declined',
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Marks a booking as paid — written by the sandbox PayHere-style
  /// checkout once its (simulated) charge succeeds. `notifications_screen`
  /// already keys its dormant "Payment completed" card off this exact
  /// field name, so setting it here is what activates that card.
  static Future<void> markBookingPaid(String bookingId) {
    return _collection.doc(bookingId).update({
      'paymentStatus': 'paid',
      'paidAt': FieldValue.serverTimestamp(),
    });
  }

  /// Caregiver flags that they personally can't make an already-scheduled
  /// shift, with a reason and optional note. Doesn't cancel the booking or
  /// notify anyone (no such pipeline exists) — just records the real
  /// exception so it's visible on the caregiver's own schedule.
  static Future<void> reportCantAttend(
    String bookingId, {
    required String reason,
    String? note,
  }) {
    return _collection.doc(bookingId).update({
      'cantAttend': true,
      'cantAttendReason': reason,
      'cantAttendNote': note,
      'cantAttendAt': FieldValue.serverTimestamp(),
    });
  }

  /// Clears a previously-recorded "can't attend" flag.
  static Future<void> clearCantAttend(String bookingId) {
    return _collection.doc(bookingId).update({
      'cantAttend': false,
      'cantAttendReason': FieldValue.delete(),
      'cantAttendNote': FieldValue.delete(),
      'cantAttendAt': FieldValue.delete(),
    });
  }

  /// Bookings assigned to a specific caregiver — used for the caregiver's
  /// own schedule (arrival confirmation, live-location sharing).
  static Stream<List<Map<String, dynamic>>> streamBookingsForCaregiver(
    String caregiverUid,
  ) {
    return _collection
        .where('caregiverId', isEqualTo: caregiverUid)
        .snapshots()
        .map((snap) {
      final docs = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      docs.sort((a, b) {
        final at = a['createdAt'];
        final bt = b['createdAt'];
        if (at is! Timestamp || bt is! Timestamp) return 0;
        return bt.compareTo(at);
      });
      return docs;
    });
  }

  /// Live updates for a single booking — used by the patient's track screen
  /// to watch `liveLocation` and `arrivalConfirmed` change in real time.
  static Stream<Map<String, dynamic>?> streamBooking(String bookingId) {
    return _collection.doc(bookingId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return {'id': snap.id, ...?snap.data()};
    });
  }

  /// Caregiver confirms they've physically arrived at the patient's
  /// location — stops the "caregiver on the way" notification from firing
  /// and freezes the live-tracking screen's status.
  static Future<void> confirmArrival(String bookingId) {
    return _collection.doc(bookingId).update({
      'arrivalConfirmed': true,
      'arrivedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Real GPS position from the caregiver's device while a shift is in
  /// progress — written repeatedly as they move, read live by the patient's
  /// track screen.
  static Future<void> updateLiveLocation({
    required String bookingId,
    required double lat,
    required double lng,
  }) {
    return _collection.doc(bookingId).update({
      'liveLocation': {
        'lat': lat,
        'lng': lng,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    });
  }

  /// Clears the shared position — called when the caregiver turns location
  /// sharing off or confirms arrival.
  static Future<void> stopLiveLocation(String bookingId) {
    return _collection.doc(bookingId).update({
      'liveLocation': FieldValue.delete(),
    });
  }

  /// Records a patient-initiated request to extend an ongoing visit's end
  /// time. Left pending until the caregiver confirms it (no auto-apply).
  static Future<void> requestExtension({
    required String bookingId,
    required String newEndTime,
    required int extraMinutes,
  }) {
    return _collection.doc(bookingId).update({
      'pendingExtension': {
        'newEndTime': newEndTime,
        'extraMinutes': extraMinutes,
        'requestedAt': FieldValue.serverTimestamp(),
      },
    });
  }

  /// Caregiver's response to a patient's pending extension request — accepting
  /// applies the new end time, declining just clears the request.
  static Future<void> resolveExtension(String bookingId, {required bool accept}) async {
    final doc = _collection.doc(bookingId);
    if (accept) {
      final snap = await doc.get();
      final pending = snap.data()?['pendingExtension'] as Map<String, dynamic>?;
      final newEndTime = pending?['newEndTime'] as String?;
      await doc.update({
        if (newEndTime != null) 'endTime': newEndTime,
        'pendingExtension': FieldValue.delete(),
      });
    } else {
      await doc.update({'pendingExtension': FieldValue.delete()});
    }
  }

  /// All bookings across every patient/caregiver — used by the admin
  /// bookings screen. Combines live requests with the cancelled archive,
  /// same merge pattern as [streamBookingsForPatient] but unfiltered.
  static Stream<List<Map<String, dynamic>>> streamAllBookingsForAdmin() {
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();
    List<Map<String, dynamic>>? active;
    List<Map<String, dynamic>>? cancelled;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? activeSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? cancelledSub;

    void emit() {
      if (active == null || cancelled == null) return;
      final combined = [...active!, ...cancelled!];
      combined.sort((a, b) {
        final at = (a['createdAt'] ?? a['cancelledAt']);
        final bt = (b['createdAt'] ?? b['cancelledAt']);
        if (at is! Timestamp || bt is! Timestamp) return 0;
        return bt.compareTo(at);
      });
      controller.add(combined);
    }

    controller.onListen = () {
      activeSub = _collection.snapshots().listen((snap) {
        active = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        emit();
      });
      cancelledSub = _cancelledCollection.snapshots().listen((snap) {
        cancelled = snap.docs
            .map((d) => {'id': d.id, 'status': 'cancelled', ...d.data()})
            .toList();
        emit();
      });
    };
    controller.onCancel = () {
      activeSub?.cancel();
      cancelledSub?.cancel();
    };
    return controller.stream;
  }

  /// Real booking/cancellation counts for the admin patient profile — there
  /// is no "disputes" concept anywhere in the schema, so that stat is not
  /// derivable and must not be fabricated by callers.
  static Future<({int active, int cancelled})> countBookingsForPatient(
    String patientUid,
  ) async {
    final activeSnap =
        await _collection.where('patientUid', isEqualTo: patientUid).count().get();
    final cancelledSnap = await _cancelledCollection
        .where('patientUid', isEqualTo: patientUid)
        .count()
        .get();
    return (active: activeSnap.count ?? 0, cancelled: cancelledSnap.count ?? 0);
  }

  /// Same as [countBookingsForPatient] but for a caregiver.
  static Future<({int active, int cancelled})> countBookingsForCaregiver(
    String caregiverUid,
  ) async {
    final activeSnap =
        await _collection.where('caregiverId', isEqualTo: caregiverUid).count().get();
    final cancelledSnap = await _cancelledCollection
        .where('caregiverId', isEqualTo: caregiverUid)
        .count()
        .get();
    return (active: activeSnap.count ?? 0, cancelled: cancelledSnap.count ?? 0);
  }

  /// The caregiver name from a patient's most recently confirmed booking —
  /// a real (not fabricated) "assigned caregiver" for the admin patient
  /// profile. Null if the patient has no confirmed booking.
  static Future<String?> getLatestConfirmedCaregiverName(String patientUid) async {
    final snap = await _collection
        .where('patientUid', isEqualTo: patientUid)
        .where('status', isEqualTo: 'confirmed')
        .get();
    if (snap.docs.isEmpty) return null;
    final docs = snap.docs.toList()
      ..sort((a, b) {
        final at = a.data()['createdAt'];
        final bt = b.data()['createdAt'];
        if (at is! Timestamp || bt is! Timestamp) return 0;
        return bt.compareTo(at);
      });
    return docs.first.data()['caregiverName'] as String?;
  }

  /// Bookings actually completed by a caregiver — a confirmed booking whose
  /// scheduled end has already passed. There is no stored "completed"
  /// status in the schema (only requested/confirmed/declined/cancelled), so
  /// this is derived from the real schedule fields rather than a fabricated
  /// number.
  static Future<int> countCompletedBookingsForCaregiver(String caregiverUid) async {
    final snap = await _collection
        .where('caregiverId', isEqualTo: caregiverUid)
        .where('status', isEqualTo: 'confirmed')
        .get();
    final now = DateTime.now();
    return snap.docs.where((d) {
      final data = d.data();
      final end = parseBookingDateTime(
        (data['endDate'] as String?) ?? (data['startDate'] as String?),
        data['endTime'] as String? ?? data['startTime'] as String?,
      );
      return end != null && end.isBefore(now);
    }).length;
  }

  /// Confirmed bookings grouped by the weekday they were created on, for the
  /// last 7 days — used by the admin dashboard's real bookings chart.
  static Future<Map<int, int>> countBookingsByWeekdayLast7Days() async {
    final since = DateTime.now().subtract(const Duration(days: 7));
    final snap = await _collection
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .get();
    final counts = <int, int>{for (var i = 1; i <= 7; i++) i: 0};
    for (final doc in snap.docs) {
      final createdAt = doc.data()['createdAt'];
      if (createdAt is Timestamp) {
        final weekday = createdAt.toDate().weekday; // 1=Mon..7=Sun
        counts[weekday] = (counts[weekday] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Requests still waiting for a caregiver to be matched — the real
  /// "unfulfilled requests" count for the admin dashboard/bookings screen.
  static Future<int> countUnfulfilled() async {
    final snap = await _collection.where('status', isEqualTo: 'requested').count().get();
    return snap.count ?? 0;
  }

  /// Bookings requested since [since] — used for the admin dashboard's
  /// "this month" stat.
  static Future<int> countCreatedSince(DateTime since) async {
    final snap = await _collection
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .count()
        .get();
    return snap.count ?? 0;
  }

  /// Best-effort parse of the app's free-form "20 Dec 2025" / "8:00 AM"
  /// display strings back into a real DateTime — there's no ISO date stored
  /// anywhere, only these display strings from the booking flow.
  static DateTime? parseBookingDateTime(String? dateStr, String? timeStr) {
    if (dateStr == null) return null;
    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    final dateParts = dateStr.trim().split(RegExp(r'\s+'));
    if (dateParts.length < 3) return null;
    final day = int.tryParse(dateParts[0]);
    final monthKey = dateParts[1].toLowerCase();
    final month = months[monthKey.length >= 3 ? monthKey.substring(0, 3) : monthKey];
    final year = int.tryParse(dateParts[2]);
    if (day == null || month == null || year == null) return null;

    var hour = 0;
    var minute = 0;
    if (timeStr != null) {
      final match = RegExp(r'(\d{1,2}):(\d{2})\s*([AaPp][Mm])?').firstMatch(timeStr);
      if (match != null) {
        hour = int.parse(match.group(1)!);
        minute = int.parse(match.group(2)!);
        final meridiem = match.group(3)?.toLowerCase();
        if (meridiem == 'pm' && hour != 12) hour += 12;
        if (meridiem == 'am' && hour == 12) hour = 0;
      }
    }
    return DateTime(year, month, day, hour, minute);
  }
}
