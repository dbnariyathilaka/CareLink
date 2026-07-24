import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';

class _ReviewMedia {
  final XFile file;
  final bool isVideo;
  const _ReviewMedia({required this.file, required this.isVideo});
}

class AddReviewScreen extends StatefulWidget {
  const AddReviewScreen({super.key});

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  static const Color _amber = Color(0xFFF59E0B);
  static const Color _amberOutline = Color(0xFFF59E0B);

  int _selectedStars = 4;
  final Set<String> _selectedTags = {'Punctual', 'Very caring'};
  final TextEditingController _reviewController = TextEditingController();
  bool _addToFavourites = true;
  final List<_ReviewMedia> _media = [];
  static const int _maxMedia = 5;

  static const List<String> _tags = [
    'Punctual',
    'Very caring',
    'Good communicator',
    'Professional',
    'Patient & gentle',
    'Handled medication well',
  ];

  static const List<String> _starLabels = [
    '',
    'poor',
    'fair',
    'good',
    'very good',
    'excellent',
  ];

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildTitleRow(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCaregiverInfo(),
                        const SizedBox(height: 24),
                        _buildStarRating(),
                        const SizedBox(height: 22),
                        _buildWhatStoodOut(),
                        const SizedBox(height: 22),
                        _buildWriteReview(),
                        const SizedBox(height: 22),
                        _buildMediaSection(),
                        const SizedBox(height: 16),
                        _buildFavouritesToggle(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Sticky bottom buttons
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomButtons(context),
          ),
        ],
      ),
    );
  }



  // ── Title row ─────────────────────────────────────────────
  Widget _buildTitleRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: AppTheme.textPrimary, size: 24),
          ),
          const SizedBox(width: 10),
          const Text(
            'Leave a review',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Caregiver info subtitle ───────────────────────────────
  Widget _buildCaregiverInfo() {
    return Center(
      child: Column(
        children: const [
          Text(
            'Alice Fernando',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Elder care · 20 Nov – 20 Dec 2025',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Interactive star rating ───────────────────────────────
  Widget _buildStarRating() {
    final label = _selectedStars > 0 ? _starLabels[_selectedStars] : '';
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final starIndex = i + 1;
            final filled = starIndex <= _selectedStars;
            return GestureDetector(
              onTap: () => setState(() => _selectedStars = starIndex),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: _amberOutline,
                  size: 42,
                ),
              ),
            );
          }),
        ),
        if (_selectedStars > 0) ...[
          const SizedBox(height: 8),
          Text(
            '$_selectedStars stars — $label',
            style: const TextStyle(
              color: _amber,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  // ── What stood out? chip selector ────────────────────────
  Widget _buildWhatStoodOut() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What stood out?',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: _tags.map((tag) {
            final selected = _selectedTags.contains(tag);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (selected) {
                    _selectedTags.remove(tag);
                  } else {
                    _selectedTags.add(tag);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.primaryGreen.withValues(alpha: 0.15)
                      : AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected ? AppTheme.primaryGreen : AppTheme.borderColor,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: selected ? AppTheme.primaryGreen : AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Write a review text area ──────────────────────────────
  Widget _buildWriteReview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Write a review',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _reviewController,
              builder: (_, value, _) => Text(
                '${value.text.length}/300',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _reviewController,
          maxLength: 300,
          maxLines: 5,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            hintText: 'Tell other families about your experience...',
            hintStyle: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
            filled: true,
            fillColor: AppTheme.cardColor,
            counterText: '',
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ── Add photos or video ────────────────────────────────────
  Future<void> _showMediaPicker() async {
    if (_media.length >= _maxMedia) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can add up to 5 photos or videos.')),
      );
      return;
    }
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
              leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.primaryGreen),
              title: const Text('Take a photo',
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, 'camera_photo'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppTheme.primaryGreen),
              title: const Text('Choose photo from gallery',
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, 'gallery_photo'),
            ),
            ListTile(
              leading: const Icon(Icons.videocam_rounded, color: AppTheme.primaryGreen),
              title: const Text('Choose video from gallery',
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, 'gallery_video'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;

    final picker = ImagePicker();
    XFile? picked;
    bool isVideo = false;
    switch (choice) {
      case 'camera_photo':
        picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      case 'gallery_photo':
        picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      case 'gallery_video':
        picked = await picker.pickVideo(source: ImageSource.gallery);
        isVideo = true;
    }
    if (picked == null || !mounted) return;

    final sizeBytes = await picked.length();
    if (sizeBytes > 20 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That file is larger than 20 MB.')),
      );
      return;
    }

    setState(() {
      _media.add(_ReviewMedia(file: picked!, isVideo: isVideo));
    });
  }

  Widget _buildMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Add photos or video',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Optional · up to $_maxMedia',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 70,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildAddMediaTile(),
              for (int i = 0; i < _media.length; i++) ...[
                const SizedBox(width: 10),
                _buildMediaThumb(i),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        _buildBrowseDropzone(),
        const SizedBox(height: 8),
        _buildMediaHint(),
      ],
    );
  }

  Widget _buildAddMediaTile() {
    return GestureDetector(
      onTap: _showMediaPicker,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF131F33),
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_rounded, color: AppTheme.primaryGreen, size: 22),
            SizedBox(height: 3),
            Text(
              'Add',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaThumb(int index) {
    final item = _media[index];
    return Stack(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(10),
            image: !item.isVideo
                ? DecorationImage(
                    image: FileImage(File(item.file.path)),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: item.isVideo
              ? const Center(
                  child: Icon(Icons.play_circle_rounded, color: AppTheme.textSecondary, size: 28),
                )
              : null,
        ),
        if (item.isVideo)
          Positioned(
            left: 5,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Video',
                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        Positioned(
          right: 4,
          top: 4,
          child: GestureDetector(
            onTap: () => setState(() => _media.removeAt(index)),
            child: Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrowseDropzone() {
    return GestureDetector(
      onTap: _showMediaPicker,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_upload_rounded, color: AppTheme.primaryGreen, size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Browse files to upload',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'or drag & drop from your device',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Material(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _showMediaPicker,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  child: Text(
                    'Browse',
                    style: TextStyle(
                      color: AppTheme.bottleGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaHint() {
    const style = TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w500);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Icon(Icons.info_outline_rounded, color: Color(0xFF64748B), size: 14),
        const SizedBox(width: 6),
        const Text('Photos: JPG, PNG, HEIC', style: style),
        _buildDot(),
        const Text('Video: MP4, MOV', style: style),
        _buildDot(),
        const Text('up to 20 MB each', style: style),
      ],
    );
  }

  Widget _buildDot() => Container(
        width: 3,
        height: 3,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: AppTheme.borderColor,
          borderRadius: BorderRadius.circular(1.5),
        ),
      );

  // ── Add to favourites toggle ──────────────────────────────
  Widget _buildFavouritesToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Add Alice to favourites',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _addToFavourites = !_addToFavourites),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                color: _addToFavourites
                    ? AppTheme.primaryGreen
                    : AppTheme.borderColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: _addToFavourites
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.all(3),
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sticky bottom: Submit + Skip ──────────────────────────
  Widget _buildBottomButtons(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.surfaceColor.withValues(alpha: 0),
            AppTheme.surfaceColor,
          ],
          stops: const [0.0, 0.3],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Submit review button
            Material(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => Navigator.pop(context),
                child: const SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Submit review',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.bottleGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Skip for now
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Skip for now',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
