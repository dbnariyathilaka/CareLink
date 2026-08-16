import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';

/// A file picked via [pickImageOrDocument], ready to hand to StorageService.
class PickedUpload {
  const PickedUpload({required this.bytes, required this.name, this.mimeType});
  final Uint8List bytes;
  final String name;
  final String? mimeType;
}

/// Shared "Take a photo / Choose from gallery / Choose a PDF / Remove photo"
/// bottom sheet used by every profile-photo and document picker in the app.
///
/// Returns `null` if the user dismissed the sheet or removed the file
/// (in which case [onRemove] has already been invoked).
Future<PickedUpload?> pickImageOrDocument(
  BuildContext context, {
  bool allowPdf = true,
  bool allowVideo = false,
  bool allowRemove = false,
  VoidCallback? onRemove,
}) async {
  const indigo = Color(0xFF6366F1);
  const red = Color(0xFFEF4444);

  final choice = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppTheme.cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: AppTheme.borderColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded, color: indigo),
            title: const Text('Take a photo',
                style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
            onTap: () => Navigator.pop(context, 'camera'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded, color: indigo),
            title: const Text('Choose from gallery',
                style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
            onTap: () => Navigator.pop(context, 'gallery'),
          ),
          if (allowPdf)
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_rounded, color: indigo),
              title: const Text('Choose a PDF',
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, 'pdf'),
            ),
          if (allowVideo)
            ListTile(
              leading: const Icon(Icons.videocam_rounded, color: indigo),
              title: const Text('Choose a video',
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, 'video'),
            ),
          if (allowRemove)
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: red),
              title: const Text('Remove photo',
                  style: TextStyle(color: red, fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, 'remove'),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  if (choice == null) return null;

  if (choice == 'remove') {
    onRemove?.call();
    return null;
  }

  if (choice == 'pdf') {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    final file = result?.files.single;
    if (file?.bytes == null) return null;
    return PickedUpload(bytes: file!.bytes!, name: file.name, mimeType: 'application/pdf');
  }

  if (choice == 'video') {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked == null) return null;
    return PickedUpload(
      bytes: await picked.readAsBytes(),
      name: picked.name,
      mimeType: picked.mimeType ?? 'video/mp4',
    );
  }

  final picked = await ImagePicker().pickImage(
    source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
    imageQuality: 85,
  );
  if (picked == null) return null;
  return PickedUpload(
    bytes: await picked.readAsBytes(),
    name: picked.name,
    mimeType: picked.mimeType,
  );
}

/// Opens the camera directly — no intermediate sheet.
Future<PickedUpload?> pickFromCamera() async {
  final picked = await ImagePicker().pickImage(
    source: ImageSource.camera,
    imageQuality: 85,
  );
  if (picked == null) return null;
  return PickedUpload(
    bytes: await picked.readAsBytes(),
    name: picked.name,
    mimeType: picked.mimeType,
  );
}

/// Opens the photo gallery directly — no intermediate sheet.
Future<PickedUpload?> pickFromGallery() async {
  final picked = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    imageQuality: 85,
  );
  if (picked == null) return null;
  return PickedUpload(
    bytes: await picked.readAsBytes(),
    name: picked.name,
    mimeType: picked.mimeType,
  );
}
