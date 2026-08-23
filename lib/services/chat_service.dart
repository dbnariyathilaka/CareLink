import 'package:cloud_firestore/cloud_firestore.dart';

/// Real-time chat service for CareLink.
/// Messages are stored at `chats/{bookingId}/messages/{messageId}`.
/// Booking request docs at `bookingRequests/{bookingId}` store latest message metadata
/// and unread counts for fast list rendering.
class ChatService {
  ChatService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _messagesRef(String bookingId) =>
      _firestore.collection('chats').doc(bookingId).collection('messages');

  static DocumentReference<Map<String, dynamic>> _bookingRef(String bookingId) =>
      _firestore.collection('bookingRequests').doc(bookingId);

  /// Streams all messages for a given booking in chronological order (oldest to newest).
  static Stream<List<Map<String, dynamic>>> streamMessages(String bookingId) {
    return _messagesRef(bookingId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  /// Sends a text or audio message.
  static Future<void> sendMessage({
    required String bookingId,
    required String senderId,
    required String senderRole, // 'caregiver' or 'patient'
    required String text,
    String type = 'text', // 'text', 'audio', 'callLog'
    String? audioDuration,
  }) async {
    final now = FieldValue.serverTimestamp();

    // 1. Add message doc
    await _messagesRef(bookingId).add({
      'senderId': senderId,
      'senderRole': senderRole,
      'text': text,
      'type': type,
      if (audioDuration != null) ...{'audioDuration': audioDuration},
      'createdAt': now,
    });

    // 2. Update booking document with latest message metadata & increment other party's unread count
    final isCaregiver = senderRole == 'caregiver';
    await _bookingRef(bookingId).set({
      'lastMessage': type == 'audio' ? 'Voice note (${audioDuration ?? '0:08'})' : text,
      'lastMessageAt': now,
      'lastSenderRole': senderRole,
      if (isCaregiver)
        'patientUnreadCount': FieldValue.increment(1)
      else
        'caregiverUnreadCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  /// Logs a completed phone or video call event in the chat.
  static Future<void> logCall({
    required String bookingId,
    required String senderId,
    required String senderRole,
    required bool isVideo,
    required Duration duration,
  }) async {
    final m = duration.inMinutes;
    final s = duration.inSeconds.remainder(60);
    final formattedDuration = '${m}m ${s}s';
    final callText = '${isVideo ? 'Video' : 'Voice'} call · $formattedDuration';

    await sendMessage(
      bookingId: bookingId,
      senderId: senderId,
      senderRole: senderRole,
      text: callText,
      type: 'callLog',
    );
  }

  /// Marks messages as read by resetting the unread count for the given user role.
  static Future<void> markAsRead({
    required String bookingId,
    required String readerRole, // 'caregiver' or 'patient'
  }) async {
    final isCaregiver = readerRole == 'caregiver';
    await _bookingRef(bookingId).set({
      if (isCaregiver)
        'caregiverUnreadCount': 0
      else
        'patientUnreadCount': 0,
    }, SetOptions(merge: true));
  }
}
