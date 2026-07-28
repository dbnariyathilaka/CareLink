import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Thin wrapper around Firebase Storage for profile pictures and caregiver
/// verification documents (police clearance, certificates, other docs).
class StorageService {
  StorageService._();
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String> uploadBytes({
    required String storagePath,
    required Uint8List bytes,
    String? contentType,
  }) async {
    final ref = _storage.ref(storagePath);
    await ref.putData(
      bytes,
      SettableMetadata(contentType: contentType ?? _contentTypeFor(storagePath)),
    );
    return ref.getDownloadURL();
  }

  static Future<String> uploadXFile(String storagePath, XFile file) async {
    return uploadBytes(
      storagePath: storagePath,
      bytes: await file.readAsBytes(),
      contentType: file.mimeType,
    );
  }

  static Future<String> uploadPlatformFile(
    String storagePath,
    PlatformFile file,
  ) async {
    final bytes = file.bytes ?? await File(file.path!).readAsBytes();
    return uploadBytes(storagePath: storagePath, bytes: bytes);
  }

  static String profilePhotoPath(String uid, String filename) =>
      'users/$uid/profile${_extOf(filename)}';

  static String policeClearancePath(String uid, String filename) =>
      'caregivers/$uid/police_clearance/clearance${_extOf(filename)}';

  static String certificatePath(String uid, String filename) =>
      'caregivers/$uid/certificates/${DateTime.now().millisecondsSinceEpoch}_$filename';

  static String otherDocumentPath(String uid, String filename) =>
      'caregivers/$uid/other_documents/${DateTime.now().millisecondsSinceEpoch}_$filename';

  static String _extOf(String filename) {
    final i = filename.lastIndexOf('.');
    return i == -1 ? '' : filename.substring(i).toLowerCase();
  }

  static String? _contentTypeFor(String path) {
    final ext = path.toLowerCase().split('.').last;
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'pdf' => 'application/pdf',
      _ => null,
    };
  }
}
