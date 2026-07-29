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
  static final Uri _uploadUrl =
      Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/auto/upload');

  static Future<String> uploadBytes({
    required String storagePath,
    required Uint8List bytes,
    String? contentType,
  }) async {
    final slash = storagePath.lastIndexOf('/');
    final folder = slash == -1 ? '' : storagePath.substring(0, slash);
    final filename = slash == -1 ? storagePath : storagePath.substring(slash + 1);

    final request = http.MultipartRequest('POST', _uploadUrl)
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

  static String reviewMediaPath(String uid, String filename) =>
      'reviews/$uid/${DateTime.now().millisecondsSinceEpoch}_$filename';

  static String _extOf(String filename) {
    final i = filename.lastIndexOf('.');
    return i == -1 ? '' : filename.substring(i).toLowerCase();
  }
}
