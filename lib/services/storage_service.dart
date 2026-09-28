import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Uploads profile pictures and caregiver verification documents (police
/// clearance, certificates, other docs) to Cloudinary via an unsigned
/// upload preset, and returns the resulting HTTPS download URL.
class StorageService {
  StorageService._();

  static const String _cloudName = 'ov1bmnqf';
  static const String _uploadPreset = 'Care_Match';

  // Cloudinary's "auto" resource-type detection files a PDF under `image`,
  // which this Cloudinary account (ov1bmnqf) is configured to block direct
  // delivery of (401 "deny or ACL failure" — a security restriction against
  // PDF-based XSS). Routing PDFs through `raw` instead does NOT avoid this —
  // confirmed by hand: a PDF uploaded via `raw` still 401s with the exact
  // same X-Cld-Error. This account's "Restricted media types" security
  // setting evidently blocks PDF/ZIP delivery account-wide, independent of
  // resource_type, so there's no upload-side fix for it — it can only be
  // lifted from the Cloudinary console (Settings → Security). Non-image
  // files still go through `raw` here since it's otherwise the correct
  // resource type for a non-transformable document, but it does not by
  // itself make PDFs viewable while that account setting is on.
  static const Set<String> _imageExtensions = {
    '.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic', '.heif', '.bmp',
  };

  static Uri _uploadUrlFor(String filename) {
    final ext = _extOf(filename);
    final resourceType = _imageExtensions.contains(ext) ? 'auto' : 'raw';
    return Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload');
  }

  static Future<String> uploadBytes({
    required String storagePath,
    required Uint8List bytes,
    String? contentType,
  }) async {
    final slash = storagePath.lastIndexOf('/');
    final folder = slash == -1 ? '' : storagePath.substring(0, slash);
    final filename = slash == -1 ? storagePath : storagePath.substring(slash + 1);

    final request = http.MultipartRequest('POST', _uploadUrlFor(filename))
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    if (folder.isNotEmpty) {
      request.fields['folder'] = folder;
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200) {
      throw Exception('Cloudinary upload failed (${response.statusCode}): ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['secure_url'] as String;
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

  static String referenceDocumentPath(String uid, String filename) =>
      'caregivers/$uid/reference${_extOf(filename)}';

  static String reviewMediaPath(String uid, String filename) =>
      'reviews/$uid/${DateTime.now().millisecondsSinceEpoch}_$filename';

  static String careJournalPhotoPath(String patientUid, String filename) =>
      'patients/$patientUid/care_journal/${DateTime.now().millisecondsSinceEpoch}_$filename';

  static String _extOf(String filename) {
    final i = filename.lastIndexOf('.');
    return i == -1 ? '' : filename.substring(i).toLowerCase();
  }
}
