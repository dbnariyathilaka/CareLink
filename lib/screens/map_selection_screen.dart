import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MapSelectionScreen extends StatefulWidget {
  const MapSelectionScreen({super.key});

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  // Figma design tokens mapped to AppTheme
  static const Color _azure11 = AppTheme.surfaceColor; // #0F172A
  static const Color _azure17 = AppTheme.cardColor;    // #1E293B
  static const Color _azure27 = AppTheme.borderColor;  // #334155
  static const Color _azure65 = AppTheme.textSecondary; // #94A3B8
  static const Color _grey98 = AppTheme.textPrimary;    // #F8FAFC

  // Advanced match flow
  bool _isAdvanced = false;
  Map<String, dynamic> _bookingArgs = {};

  // Dynamic accent colors based on flow
  Color get _accentColor => _isAdvanced ? const Color(0xFF3DB498) : AppTheme.primaryGreen;
  Color get _accentText  => _isAdvanced ? const Color(0xFF06291F) : AppTheme.bottleGreen;

  // Interactive Map State
  double _zoomLevel = 14.0;
  bool _isLocating = false;
  String _address = 'Search location';
  double _currentLat = 6.8402;
  double _currentLng = 79.9839;
  bool _usingGPS = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _isAdvanced = args['isAdvanced'] ?? false;
      _bookingArgs = Map<String, dynamic>.from(args);
    }
  }

  void _simulateGPSLocation() {
    setState(() {
      _isLocating = true;
    });

    // Simulate mobile location retrieval delay
    Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _isLocating = false;
          _usingGPS = true;
          _address = 'Homagama, Colombo (GPS)';
          _currentLat = 6.8402;
          _currentLng = 79.9839;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Mobile GPS Location acquired!'),
            backgroundColor: _accentColor,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _azure11,
      body: Stack(
        children: [
          // 1. Full-screen custom map background
          Positioned.fill(
            child: InteractiveViewer(
              maxScale: 3.0,
              minScale: 0.8,
              child: CustomPaint(
                painter: _FullscreenMapPainter(
                  zoomLevel: _zoomLevel,
                  lat: _currentLat,
                  lng: _currentLng,
                  usingGPS: _usingGPS,
                ),
              ),
            ),
          ),

          // 2. Pulsing target indicator at map center
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40), // offset for visual pin tip
              child: _buildCenterTargetPin(),
            ),
          ),

          // 3. Status Bar Spacer & Back top-left overlay
          Positioned(
            top: 20,
            left: 20,
            child: SafeArea(
              child: Text(
                '9:41',
                style: TextStyle(
                  color: _grey98.withValues(alpha: 0.8),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // 4. Floating map tools on the right (Zoom, Location GPS)
          Positioned(
            right: 16,
            top: 60,
            child: SafeArea(
              child: Column(
                children: [
                  _buildFloatingTool(
                    icon: Icons.add_rounded,
                    onTap: () {
                      setState(() => _zoomLevel = (_zoomLevel + 1).clamp(10, 20));
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildFloatingTool(
                    icon: Icons.remove_rounded,
                    onTap: () {
                      setState(() => _zoomLevel = (_zoomLevel - 1).clamp(10, 20));
                    },
                  ),
                  const SizedBox(height: 14),
                  // Active state for GPS location
                  _buildGPSFloatingButton(),
                ],
              ),
            ),
          ),

          // 5. Bottom Panel Sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomPanel(context),
          ),

          // 6. Loading screen/GPS loader overlay
          if (_isLocating) _buildLocatingOverlay(),
        ],
      ),
    );
  }

  // ── Floating tools helper ──
  Widget _buildFloatingTool({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _azure17,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _azure27),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: _grey98, size: 22),
      ),
    );
  }

  Widget _buildGPSFloatingButton() {
    return GestureDetector(
      onTap: _simulateGPSLocation,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _usingGPS ? _accentColor : _azure17,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _usingGPS ? _accentColor : _azure27),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          _usingGPS ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
          color: _usingGPS ? _accentText : _grey98,
          size: 20,
        ),
      ),
    );
  }

  // ── Center Target Pin ──
  Widget _buildCenterTargetPin() {
    if (_isAdvanced) {
      // Advanced match: solid black teardrop pin matching Figma P-11g
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (_usingGPS)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _accentColor.withValues(alpha: 0.25),
                  ),
                ),
              Icon(
                Icons.location_on_rounded,
                color: _usingGPS ? _accentColor : Colors.black,
                size: 44,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    }

    // Normal flow: tooltip + pulsing ring pin
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Marker tooltip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _usingGPS ? _accentColor : _azure27),
          ),
          child: Text(
            _usingGPS ? 'Active GPS Position' : 'Drag Map to Set',
            style: TextStyle(
              color: _usingGPS ? _accentColor : _grey98,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Pulsing Circle Under Pin
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (_usingGPS ? _accentColor : Colors.red).withValues(alpha: 0.35),
              ),
            ),
            Icon(
              Icons.location_on_rounded,
              color: _usingGPS ? _accentColor : Colors.redAccent,
              size: 38,
            ),
          ],
        ),
      ],
    );
  }

  // ── Bottom Sheet Panel ──
  Widget _buildBottomPanel(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _azure17,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(
          top: BorderSide(color: _azure27, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF475569),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 15),

          // Search location input bar
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Search location overlay is active.'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              decoration: BoxDecoration(
                color: _azure11,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _azure27),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: _azure65, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _address,
                      style: TextStyle(
                        color: _address == 'Search location' ? _azure65 : _grey98,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons Row
          Row(
            children: [
              // Back Button
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9),
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: _azure27),
                      ),
                      child: const Text(
                        'Back',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _grey98,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Select Button
              Expanded(
                child: Material(
                  color: _accentColor,
                  borderRadius: BorderRadius.circular(9),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/location-confirm',
                        arguments: {
                          ..._bookingArgs,
                          'city': _usingGPS ? 'Homagama' : 'Selected Location',
                          'location': _usingGPS ? 'Homagama' : 'Selected Location',
                          'lat': _currentLat,
                          'lng': _currentLng,
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      child: Text(
                        'Select',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _accentText,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Locate simulation spinner
  Widget _buildLocatingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
            ),
            const SizedBox(height: 16),
            const Text(
              'Acquiring Mobile GPS location...',
              style: TextStyle(
                color: _grey98,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Full screen Custom Painter map ──
class _FullscreenMapPainter extends CustomPainter {
  final double zoomLevel;
  final double lat;
  final double lng;
  final bool usingGPS;

  _FullscreenMapPainter({
    required this.zoomLevel,
    required this.lat,
    required this.lng,
    required this.usingGPS,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Fill background (Moss Green/Zanah land colors)
    final bgPaint = Paint()..color = const Color(0xFFE3E7DE);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Forest / Park area green (c7e3bc)
    final parkPaint = Paint()..color = const Color(0xFFC7E3BC);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.4, size.height * 0.2),
        width: 320,
        height: 250,
      ),
      parkPaint,
    );

    // Lake/River water blue (cfe7c6)
    final lakePaint = Paint()..color = const Color(0xFFCFE7C6);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.1, size.height * 0.75),
        width: 220,
        height: 200,
      ),
      lakePaint,
    );

    // Draw main highways and avenues
    final roadPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Highway 1 (Diagonal Left-Right)
    roadPaint.strokeWidth = 32.0;
    canvas.drawLine(
      Offset(-50, size.height * 0.4),
      Offset(size.width + 50, size.height * 0.6),
      roadPaint,
    );

    // Local road lines (yellowish/white)
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

    // Yellow accent center lines for highway
    final centerLinePaint = Paint()
      ..color = const Color(0xFFF6F1DD)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(-50, size.height * 0.4),
      Offset(size.width + 50, size.height * 0.6),
      centerLinePaint,
    );

    // Draw text labels
    _drawText(canvas, 'Riverside Park', Offset(size.width * 0.4, size.height * 0.18), const Color(0xFF188038));
    _drawText(canvas, 'Valley Farm Supplies', Offset(size.width * 0.15, size.height * 0.12), const Color(0xFF3C4043));
    _drawText(canvas, 'City Bank ATM', Offset(size.width * 0.25, size.height * 0.42), const Color(0xFF1A73E8));
    _drawText(canvas, 'Gaziler Physiotherapy', Offset(size.width * 0.15, size.height * 0.55), const Color(0xFFC5221F));
    _drawText(canvas, 'Erensu Barracks', Offset(size.width * 0.65, size.height * 0.72), const Color(0xFF3C4043));
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
  bool shouldRepaint(covariant _FullscreenMapPainter oldDelegate) {
    return oldDelegate.zoomLevel != zoomLevel ||
        oldDelegate.lat != lat ||
        oldDelegate.lng != lng ||
        oldDelegate.usingGPS != usingGPS;
  }
}
