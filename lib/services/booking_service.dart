import 'package:cloud_firestore/cloud_firestore.dart';

/// Thin wrapper around the `bookingRequests` Firestore collection — each
/// document is one patient→caregiver care request, from the moment it's
/// sent through to acceptance/completion/cancellation.
class BookingService {
  BookingService._();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('bookingRequests');

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
  }) {
    return _collection.add({
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
  }

  /// Sorted client-side (newest first) to avoid requiring a composite
  /// Firestore index for `where(patientUid) + orderBy(createdAt)`.
  static Stream<List<Map<String, dynamic>>> streamBookingsForPatient(
    String patientUid,
  ) {
    return _collection
        .where('patientUid', isEqualTo: patientUid)
        .snapshots()
        .map((snap) {
      final docs =
          snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      docs.sort((a, b) {
        final at = a['createdAt'];
        final bt = b['createdAt'];
        if (at is! Timestamp || bt is! Timestamp) return 0;
        return bt.compareTo(at);
      });
      return docs;
    });
  }

  static Future<void> cancelBooking(String bookingId) {
    return _collection.doc(bookingId).update({'status': 'cancelled'});
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
}
