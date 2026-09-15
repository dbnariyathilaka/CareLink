import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'booking_service.dart';
import 'review_service.dart';

/// A short preview for the top-of-screen popup card — title + one-line
/// body, built from the same real booking/review events NotificationBadgeService
/// already counts for the unread badge, just carrying enough text to render
/// a toast instead of only a count. Full detail still lives on the real
/// notifications screens; tapping the popup just opens those.
class PopupNotification {
  final String title;
  final String body;
  final DateTime timestamp;
  const PopupNotification({required this.title, required this.body, required this.timestamp});
}

/// Drives the global "new notification" popup card for both caregiver and
/// patient sides. Separate from NotificationBadgeService's
/// `lastViewedNotificationsAt` (which marks things read when the
/// notifications screen is opened) — this tracks its own
/// `lastPopupNotifiedAt` cursor on `users/{uid}` so a popup fires exactly
/// once per real event, and survives being logged out: the cursor is
/// server-side, so whatever's newer than it the moment this stream starts
/// (including right after a fresh login) shows immediately — no missed
/// event silently disappears just because no one had the app open when it
/// happened.
class PopupNotificationService {
  PopupNotificationService._();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> markShown(String uid, DateTime at) {
    return _firestore.collection('users').doc(uid).set(
      {'lastPopupNotifiedAt': Timestamp.fromDate(at)},
      SetOptions(merge: true),
    );
  }

  static bool _isNew(DateTime t, DateTime? cursor) => cursor == null || t.isAfter(cursor);

  static PopupNotification? _latestCaregiverEvent(
    List<Map<String, dynamic>> bookings,
    List<Map<String, dynamic>> reviews,
    DateTime? cursor,
  ) {
    PopupNotification? latest;
    void consider(dynamic rawTimestamp, String title, String body) {
      if (rawTimestamp is! Timestamp) return;
      final t = rawTimestamp.toDate();
      if (!_isNew(t, cursor)) return;
      if (latest == null || t.isAfter(latest!.timestamp)) {
        latest = PopupNotification(title: title, body: body, timestamp: t);
      }
    }

    for (final b in bookings) {
      final status = b['status'] as String?;
      final careType = b['careType'] as String?;
      if (status == 'requested') {
        consider(
          b['createdAt'],
          'New booking request',
          careType != null ? 'You have a new care request for $careType.' : 'You have a new care request.',
        );
      }
      if (status == 'cancelled') {
        consider(b['cancelledAt'], 'Booking cancelled', 'A patient cancelled their care request.');
      }
      final pending = b['pendingExtension'] as Map<String, dynamic>?;
      if (pending != null) {
        consider(pending['requestedAt'], 'Extension requested', 'A patient requested to extend an ongoing visit.');
      }
    }
    for (final r in reviews) {
      consider(r['createdAt'], 'New review', 'You received a new review.');
    }
    return latest;
  }

  static PopupNotification? _latestPatientEvent(
    List<Map<String, dynamic>> bookings,
    DateTime? cursor,
  ) {
    PopupNotification? latest;
    void consider(dynamic rawTimestamp, String title, String body) {
      if (rawTimestamp is! Timestamp) return;
      final t = rawTimestamp.toDate();
      if (!_isNew(t, cursor)) return;
      if (latest == null || t.isAfter(latest!.timestamp)) {
        latest = PopupNotification(title: title, body: body, timestamp: t);
      }
    }

    for (final b in bookings) {
      final caregiverName = (b['caregiverName'] as String?) ?? 'Your caregiver';
      if (b['status'] == 'confirmed') {
        consider(b['respondedAt'], 'Booking accepted', '$caregiverName accepted your request.');
      }
      if (b['paymentStatus'] == 'paid') {
        consider(b['paidAt'], 'Payment completed', 'Your payment to $caregiverName was successful.');
      }
    }
    return latest;
  }

  /// Emits at most once per qualifying event (deduped by its own timestamp)
  /// regardless of how many times the underlying streams re-fire before the
  /// `markShown` write propagates back through `userSub`.
  static Stream<PopupNotification> caregiverPopups(String uid) {
    final controller = StreamController<PopupNotification>.broadcast();
    DateTime? cursor;
    List<Map<String, dynamic>> bookings = const [];
    List<Map<String, dynamic>> reviews = const [];
    var gotUser = false, gotBookings = false, gotReviews = false;
    DateTime? lastEmitted;

    void emit() {
      if (!gotUser || !gotBookings || !gotReviews) return;
      final latest = _latestCaregiverEvent(bookings, reviews, cursor);
      if (latest != null && latest.timestamp != lastEmitted) {
        lastEmitted = latest.timestamp;
        controller.add(latest);
      }
    }

    final userSub = _firestore.collection('users').doc(uid).snapshots().listen((snap) {
      cursor = (snap.data()?['lastPopupNotifiedAt'] as Timestamp?)?.toDate();
      gotUser = true;
      emit();
    }, onError: (_) {});
    final bookingsSub = BookingService.streamBookingsForCaregiver(uid).listen((data) {
      bookings = data;
      gotBookings = true;
      emit();
    }, onError: (_) {});
    final reviewsSub = ReviewService.streamReviewsForCaregiver(uid).listen((data) {
      reviews = data;
      gotReviews = true;
      emit();
    }, onError: (_) {});

    controller.onCancel = () {
      userSub.cancel();
      bookingsSub.cancel();
      reviewsSub.cancel();
    };
    return controller.stream;
  }

  static Stream<PopupNotification> patientPopups(String uid) {
    final controller = StreamController<PopupNotification>.broadcast();
    DateTime? cursor;
    List<Map<String, dynamic>> bookings = const [];
    var gotUser = false, gotBookings = false;
    DateTime? lastEmitted;

    void emit() {
      if (!gotUser || !gotBookings) return;
      final latest = _latestPatientEvent(bookings, cursor);
      if (latest != null && latest.timestamp != lastEmitted) {
        lastEmitted = latest.timestamp;
        controller.add(latest);
      }
    }

    final userSub = _firestore.collection('users').doc(uid).snapshots().listen((snap) {
      cursor = (snap.data()?['lastPopupNotifiedAt'] as Timestamp?)?.toDate();
      gotUser = true;
      emit();
    }, onError: (_) {});
    final bookingsSub = BookingService.streamBookingsForPatient(uid).listen((data) {
      bookings = data;
      gotBookings = true;
      emit();
    }, onError: (_) {});

    controller.onCancel = () {
      userSub.cancel();
      bookingsSub.cancel();
    };
    return controller.stream;
  }
}
