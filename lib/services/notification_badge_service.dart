import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'booking_service.dart';
import 'review_service.dart';

/// Powers the red unread-count badge shown above the Notification icon in
/// both bottom nav bars. There's no notifications collection anywhere in
/// this app (see caregiver_notifications_screen.dart / notifications_screen.dart
/// — both feeds are derived live from real bookings/reviews, not stored
/// documents), so "unread" can't be a per-notification flag. Instead this
/// counts real underlying events (a new booking request, a cancellation, an
/// extension request, a review, a booking acceptance, a completed payment)
/// whose own real timestamp is newer than the real `lastViewedNotificationsAt`
/// this service writes onto `users/{uid}` the moment either notifications
/// screen is opened. A user who has never opened their notifications screen
/// has no baseline to compare against, so this shows 0 rather than
/// retroactively flooding them with every historical event.
class NotificationBadgeService {
  NotificationBadgeService._();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> markNotificationsViewed(String uid) {
    return _firestore.collection('users').doc(uid).set(
      {'lastViewedNotificationsAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  static bool _isNew(dynamic timestamp, DateTime? lastViewed) {
    if (timestamp is! Timestamp || lastViewed == null) return false;
    return timestamp.toDate().isAfter(lastViewed);
  }

  static int _countUnreadCaregiver(
    List<Map<String, dynamic>> bookings,
    List<Map<String, dynamic>> reviews,
    DateTime? lastViewed,
  ) {
    var count = 0;
    for (final b in bookings) {
      final status = b['status'] as String?;
      if (status == 'requested' && _isNew(b['createdAt'], lastViewed)) count++;
      if (status == 'cancelled' && _isNew(b['cancelledAt'], lastViewed)) count++;
      final pending = b['pendingExtension'] as Map<String, dynamic>?;
      if (pending != null && _isNew(pending['requestedAt'], lastViewed)) count++;
    }
    for (final r in reviews) {
      if (_isNew(r['createdAt'], lastViewed)) count++;
    }
    return count;
  }

  static int _countUnreadPatient(
    List<Map<String, dynamic>> bookings,
    DateTime? lastViewed,
  ) {
    var count = 0;
    for (final b in bookings) {
      if (b['status'] == 'confirmed' && _isNew(b['respondedAt'], lastViewed)) count++;
      if (b['paymentStatus'] == 'paid' && _isNew(b['paidAt'], lastViewed)) count++;
    }
    return count;
  }

  /// Manually multiplexes the three real Firestore streams this needs
  /// (the user's own doc for lastViewedNotificationsAt, bookings, reviews)
  /// into one live count — no rxdart dependency required.
  static Stream<int> caregiverUnreadCount(String uid) {
    final controller = StreamController<int>.broadcast();
    DateTime? lastViewed;
    List<Map<String, dynamic>> bookings = const [];
    List<Map<String, dynamic>> reviews = const [];
    var gotUser = false, gotBookings = false, gotReviews = false;

    void emit() {
      if (!gotUser || !gotBookings || !gotReviews) return;
      controller.add(_countUnreadCaregiver(bookings, reviews, lastViewed));
    }

    final userSub = _firestore.collection('users').doc(uid).snapshots().listen((snap) {
      lastViewed = (snap.data()?['lastViewedNotificationsAt'] as Timestamp?)?.toDate();
      gotUser = true;
      emit();
    });
    final bookingsSub = BookingService.streamBookingsForCaregiver(uid).listen((data) {
      bookings = data;
      gotBookings = true;
      emit();
    });
    final reviewsSub = ReviewService.streamReviewsForCaregiver(uid).listen((data) {
      reviews = data;
      gotReviews = true;
      emit();
    });

    controller.onCancel = () {
      userSub.cancel();
      bookingsSub.cancel();
      reviewsSub.cancel();
    };
    return controller.stream;
  }

  static Stream<int> patientUnreadCount(String uid) {
    final controller = StreamController<int>.broadcast();
    DateTime? lastViewed;
    List<Map<String, dynamic>> bookings = const [];
    var gotUser = false, gotBookings = false;

    void emit() {
      if (!gotUser || !gotBookings) return;
      controller.add(_countUnreadPatient(bookings, lastViewed));
    }

    final userSub = _firestore.collection('users').doc(uid).snapshots().listen((snap) {
      lastViewed = (snap.data()?['lastViewedNotificationsAt'] as Timestamp?)?.toDate();
      gotUser = true;
      emit();
    });
    final bookingsSub = BookingService.streamBookingsForPatient(uid).listen((data) {
      bookings = data;
      gotBookings = true;
      emit();
    });

    controller.onCancel = () {
      userSub.cancel();
      bookingsSub.cancel();
    };
    return controller.stream;
  }
}
