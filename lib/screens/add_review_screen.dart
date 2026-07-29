import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/caregiver_service.dart';
import '../services/patient_service.dart';
import '../services/review_service.dart';
import '../services/storage_service.dart';
import '../widgets/status_bar.dart';
import '../widgets/upload_picker_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Add Review Screen  (Figma node 401-251)
//  Real caregiver info (name, care type, and — best-effort — the matching
//  booking's date range), a real Firestore write on submit, real photo/video
//  upload (Cloudinary, same pipeline as caregiver document uploads), and a
//  real "add to favourites" toggle. Nothing here is gated behind a
//  "completed booking" check — no code path ever marks a booking completed
//  yet, so gating on that would make this screen permanently unreachable.
// ─────────────────────────────────────────────────────────────────────────────
class AddReviewScreen extends StatefulWidget {
  const AddReviewScreen({super.key});

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _ReviewMedia {
  const _ReviewMedia({required this.name, required this.url});
  final String name;
  final String url;
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  static const Color bg = Color(0xFFF5EEDE);
  static const Color titleGreen = Color(0xFF06402B);
  static const Color nameDark = Color(0xFF313131);
  static const Color subtitleGray = Color.fromRGBO(49, 49, 49, 0.68);
  static const Color starFilled = Color(0xFFE08D02);
  static const Color starEmpty = Color.fromRGBO(49, 49, 49, 0.73);
  static const Color ratingLabel = Color(0xFFD15F0E);
  static const Color sectionLabel = Color.fromRGBO(68, 51, 28, 0.81);
  static const Color tagDark = Color(0xFF44331C);
  static const Color tagSelectedText = Color(0xFFF1C58B);
  static const Color textAreaBg = Color.fromRGBO(121, 98, 67, 0.42);
  static const Color textAreaHint = Color(0xFF44331C);
  static const Color dropzoneBg = Color.fromRGBO(193, 179, 157, 0.18);
  static const Color dropzoneBorder = Color.fromRGBO(68, 51, 28, 0.34);
  static const Color helperText = Color.fromRGBO(0, 0, 0, 0.63);
  static const Color fileRowBorder = Color.fromRGBO(0, 0, 0, 0.4);
  static const Color fileRowText = Color(0xFF2F2313);
  static const Color progressFill = Color(0xFFA34207);
  static const Color favBg = Color(0xFF313131);
  static const Color favBorder = Color(0xFF334155);
  static const Color favTrackOff = Color(0xFF6F6C54);

  static const _tagOptions = [
    'Punctual',
    'Very caring',
    'Good communicator',
    'Professional',
    'Patient & gentle',
    'Handled medication well',
  ];

  static const _ratingLabels = {
    1: 'poor',
    2: 'fair',
    3: 'good',
    4: 'very good',
    5: 'excellent',
  };

  int _rating = 0;
  final Set<String> _tags = {};
  final TextEditingController _textController = TextEditingController();
  final List<_ReviewMedia> _media = [];
  bool _uploading = false;
  bool _addToFavourites = false;
  bool _submitting = false;

  String? _caregiverId;
  bool _loadedArgs = false;
  Map<String, dynamic>? _caregiverProfile;
  Map<String, dynamic>? _matchingBooking;

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
    _textController.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedArgs) return;
    _loadedArgs = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['caregiverId'] is String) {
      _caregiverId = args['caregiverId'] as String;
      _loadCaregiverContext();
    }
  }

  Future<void> _loadCaregiverContext() async {
    final id = _caregiverId;
    if (id == null) return;
    final profile = await CaregiverService.getCaregiverProfile(id);
    Map<String, dynamic>? booking;
    final uid = AuthService.currentUser?.uid;
    if (uid != null) {
      final bookings = await BookingService.streamBookingsForPatient(uid).first;
      final matches = bookings
          .where((b) => b['caregiverId'] == id && b['status'] != 'cancelled')
          .toList();
      if (matches.isNotEmpty) booking = matches.first;
    }
    if (mounted) {
      setState(() {
        _caregiverProfile = profile;
        _matchingBooking = booking;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String get _caregiverName => (_caregiverProfile?['name'] as String?) ?? 'your caregiver';

  String? get _careType {
    final types = (_caregiverProfile?['careTypes'] as List?)?.cast<String>();
    return types != null && types.isNotEmpty ? types.first : null;
  }

  String? get _dateRangeLabel {
    final start = _matchingBooking?['startDate'] as String?;
    final end = _matchingBooking?['endDate'] as String?;
    if (start == null) return null;
    return end != null ? '$start – $end' : start;
  }

  Future<void> _pickMedia() async {
    if (_media.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can attach up to 5 files.')),
      );
      return;
    }
    final picked = await pickImageOrDocument(context, allowPdf: false, allowVideo: true);
    if (picked == null || !mounted) return;
    if (picked.bytes.length > 20 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Files must be under 20 MB.')),
      );
      return;
    }
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    setState(() => _uploading = true);
    try {
      final url = await StorageService.uploadBytes(
        storagePath: StorageService.reviewMediaPath(uid, picked.name),
        bytes: picked.bytes,
        contentType: picked.mimeType,
      );
      if (!mounted) return;
      setState(() {
        _media.add(_ReviewMedia(name: picked.name, url: url));
        _uploading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not upload that file. Please try again.')),
      );
    }
  }

  Future<void> _submit() async {
    final id = _caregiverId;
    final uid = AuthService.currentUser?.uid;
    if (id == null || uid == null) return;
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a star rating.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ReviewService.submitReview(
        caregiverId: id,
        patientUid: uid,
        rating: _rating,
        tags: _tags.toList(),
        text: _textController.text.trim(),
        mediaUrls: _media.map((m) => m.url).toList(),
        bookingId: _matchingBooking?['id'] as String?,
      );
      if (_addToFavourites) {
        await PatientService.toggleFavorite(patientUid: uid, caregiverUid: id, isFavorite: true);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks — your review was submitted.')),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not submit your review. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTitleRow(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _caregiverName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Open Sans',
                        color: nameDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_careType != null || _dateRangeLabel != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (_careType != null) _careType!,
                          if (_dateRangeLabel != null) _dateRangeLabel!,
                        ].join(' · '),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Open Sans',
                          color: subtitleGray,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final starIndex = i + 1;
                        return GestureDetector(
                          onTap: () => setState(() => _rating = starIndex),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.star_rounded,
                              size: 38,
                              color: starIndex <= _rating ? starFilled : starEmpty,
                            ),
                          ),
                        );
                      }),
                    ),
                    if (_rating > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        '$_rating star${_rating == 1 ? '' : 's'} — ${_ratingLabels[_rating]}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Open Sans',
                          color: ratingLabel,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    const Text(
                      'What stood out?',
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        color: sectionLabel,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tagOptions.map((tag) {
                        final selected = _tags.contains(tag);
                        return GestureDetector(
                          onTap: () => setState(() {
                            if (selected) {
                              _tags.remove(tag);
                            } else {
                              _tags.add(tag);
                            }
                          }),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: selected ? 13 : 14,
                              vertical: selected ? 9 : 10,
                            ),
                            decoration: BoxDecoration(
                              color: selected ? tagDark : Colors.transparent,
                              border: Border.all(color: tagDark),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontFamily: 'Open Sans',
                                color: selected ? tagSelectedText : tagDark,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Write a review',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: sectionLabel,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${_textController.text.length}/300',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Color.fromRGBO(68, 51, 28, 0.74),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: textAreaBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _textController,
                        maxLength: 300,
                        minLines: 3,
                        maxLines: 6,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: textAreaHint,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          counterText: '',
                          contentPadding: EdgeInsets.all(13),
                          hintText: 'Tell other families about your experience…',
                          hintStyle: TextStyle(
                            fontFamily: 'Inter',
                            color: textAreaHint,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add photos or video',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: sectionLabel,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Optional · up to ${5 - _media.length}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: tagDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _uploading ? null : _pickMedia,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: dropzoneBg,
                          border: Border.all(color: dropzoneBorder),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            if (_uploading)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(color: progressFill, strokeWidth: 2.5),
                                ),
                              )
                            else
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: Icon(Icons.cloud_upload_outlined, color: Colors.black54, size: 48),
                              ),
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: const TextStyle(
                                  fontFamily: 'Open Sans',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                children: [
                                  TextSpan(
                                    text: _uploading ? 'Uploading…' : 'Drag & drop files or ',
                                    style: const TextStyle(color: Color.fromRGBO(0, 0, 0, 0.74)),
                                  ),
                                  if (!_uploading)
                                    const TextSpan(
                                      text: 'Browse',
                                      style: TextStyle(color: Color(0xFFCA7826)),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: const [
                                Icon(Icons.info_outline_rounded, color: helperText, size: 14),
                                SizedBox(width: 4),
                                Text('Photos: JPG, PNG, HEIC',
                                    style: TextStyle(fontFamily: 'Inter', color: helperText, fontSize: 10, fontWeight: FontWeight.w500)),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6),
                                  child: SizedBox(width: 3, height: 3, child: DecoratedBox(decoration: BoxDecoration(color: helperText, shape: BoxShape.circle))),
                                ),
                                Text('Video: MP4, MOV',
                                    style: TextStyle(fontFamily: 'Inter', color: helperText, fontSize: 10, fontWeight: FontWeight.w500)),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6),
                                  child: SizedBox(width: 3, height: 3, child: DecoratedBox(decoration: BoxDecoration(color: helperText, shape: BoxShape.circle))),
                                ),
                                Text('up to 20 MB each',
                                    style: TextStyle(fontFamily: 'Inter', color: helperText, fontSize: 10, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_media.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      const Text(
                        'Uploaded',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: sectionLabel,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...List.generate(_media.length, (i) {
                        final file = _media[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: fileRowBorder, width: 1.5),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    file.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Open Sans',
                                      color: fileRowText,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() => _media.removeAt(i)),
                                  child: const Icon(Icons.cancel_rounded, color: progressFill, size: 22),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(
                        color: favBg,
                        border: Border.all(color: favBorder),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Add $_caregiverName to favourites',
                              style: const TextStyle(
                                fontFamily: 'Open Sans',
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Switch(
                            value: _addToFavourites,
                            onChanged: (v) => setState(() => _addToFavourites = v),
                            activeThumbColor: Colors.white,
                            activeTrackColor: favTrackOff,
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: favTrackOff.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Material(
                      color: titleGreen,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: _submitting ? null : _submit,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text(
                                  'Submit review',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'Skip for now',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color.fromRGBO(0, 0, 0, 0.51),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Title row ─────────────────────────────────────────────
  Widget _buildTitleRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 22, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: titleGreen, size: 20),
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'Leave a review',
            style: TextStyle(
              fontFamily: 'Open Sans',
              color: titleGreen,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
