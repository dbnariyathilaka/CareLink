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
      'isAdvanced': isAdvanced,
      'status': 'requested',
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
