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
        emit();
      });
      cancelledSub = _cancelledCollection
          .where('patientUid', isEqualTo: patientUid)
          .snapshots()
          .listen((snap) {
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

  /// Archives a reduced copy of the booking (enough to still render a
  /// "Cancelled" card) to cancelledBookings, then deletes the live doc —
  /// cancelling removes the request from the active collection entirely
  /// rather than leaving it there forever with status: 'cancelled'.
  static Future<void> cancelBooking(String bookingId) async {
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
}
