import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LocationConfirmScreen extends StatefulWidget {
  const LocationConfirmScreen({super.key});

  @override
  State<LocationConfirmScreen> createState() => _LocationConfirmScreenState();
}

class _LocationConfirmScreenState extends State<LocationConfirmScreen> {
  // Figma design tokens mapped to AppTheme
  static const Color _azure11 = AppTheme.surfaceColor; // #0F172A
  static const Color _grey98 = AppTheme.textPrimary;    // #F8FAFC
  static const Color _chestnut = Color(0xFFB5484B);      // #B5484B

  late String _city;
  late double _lat;
  late double _lng;
  bool _isAdvanced = false;
  Timer? _navigationTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Extract route arguments passed from MapSelectionScreen
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _city = args?['city'] ?? 'Homagama (GPS)';
    _lat = args?['lat'] ?? 6.8402;
    _lng = args?['lng'] ?? 79.9839;
    _isAdvanced = args?['isAdvanced'] ?? false;

    // Start auto-navigation timer
    _navigationTimer?.cancel();
    _navigationTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) {
        if (_isAdvanced) {
          Navigator.pushNamed(context, '/qualifications-intro', arguments: args);
        } else {
          Navigator.pushNamed(context, '/confirm-booking', arguments: args);
        }
      }
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _azure11,
      body: Stack(
        children: [
          // 1. Full-screen map background
          Positioned.fill(
            child: CustomPaint(
              painter: _StaticConfirmMapPainter(),
            ),
          ),

          // 2. Translucent target circle at center
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _chestnut.withValues(alpha: 0.63),
              ),
              child: Center(
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _chestnut,
                  ),
                ),
              ),
            ),
          ),

          // 3. Header title overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 90,
              decoration: const BoxDecoration(
                color: _azure11,
                boxShadow: [
                  BoxShadow(
                    color: _azure11,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              alignment: Alignment.center,
              child: SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back, color: _grey98, size: 24),
                    ),
                    const Text(
                      'Location',
                      style: TextStyle(
                        color: _grey98,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    // Profile avatar icon (visible in advanced match flow per Figma P-11h)
                    if (_isAdvanced)
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1E293B),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: _grey98,
                          size: 18,
                        ),
                      )
                    else
                      const SizedBox(width: 24),
                  ],
                ),
              ),
            ),
          ),

          // 4. Bottom toast/card indicator
          Positioned(
            left: 16,
            right: 16,
            bottom: 30,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _chestnut,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.add_location_alt_rounded,
                      color: _grey98,
                      size: 26,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Location changed to $_city!',
                            style: const TextStyle(
                              color: _grey98,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_lat.toStringAsFixed(6)}, ${_lng.toStringAsFixed(6)}',
                            style: TextStyle(
                              color: _grey98.withValues(alpha: 0.85),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Map painter matching map styles
class _StaticConfirmMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Fill background (Zanah/Moss Green)
    final bgPaint = Paint()..color = const Color(0xFFE3E7DE);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final parkPaint = Paint()..color = const Color(0xFFC7E3BC);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.4, size.height * 0.2),
        width: 320,
        height: 250,
      ),
      parkPaint,
    );

    final lakePaint = Paint()..color = const Color(0xFFCFE7C6);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.1, size.height * 0.75),
        width: 220,
        height: 200,
      ),
      lakePaint,
    );

    final roadPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    roadPaint.strokeWidth = 32.0;
    canvas.drawLine(
      Offset(-50, size.height * 0.4),
      Offset(size.width + 50, size.height * 0.6),
      roadPaint,
    );

    roadPaint.strokeWidth = 14.0;
    canvas.drawLine(
      Offset(size.width * 0.3, -50),
      Offset(size.width * 0.3, size.height + 50),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, -50),
      Offset(size.width * 0.7, size.height + 50),
      roadPaint,
    );

    // Text labels
    _drawText(canvas, 'Riverside Park', Offset(size.width * 0.4, size.height * 0.18), const Color(0xFF188038));
    _drawText(canvas, 'Valley Farm Supplies', Offset(size.width * 0.15, size.height * 0.12), const Color(0xFF3C4043));
    _drawText(canvas, 'City Bank ATM', Offset(size.width * 0.25, size.height * 0.42), const Color(0xFF1A73E8));
    _drawText(canvas, 'Gaziler Physiotherapy', Offset(size.width * 0.15, size.height * 0.55), const Color(0xFFC5221F));
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, offset - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
