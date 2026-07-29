import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/status_bar.dart';

// ─────────────────────────────────────────────────────────────
//  In-call screen — simulated voice / video call UI shown when
//  the patient taps the call or video buttons on the chat header.
//  Pops with the connected call Duration (or null if cancelled
//  before the callee "answered"), which the chat screen uses to
//  insert a "Voice call · Xm Ys" log bubble.
// ─────────────────────────────────────────────────────────────
class CallScreen extends StatefulWidget {
  final String calleeName;
  final String initials;
  final bool isVideo;

  const CallScreen({
    super.key,
    required this.calleeName,
    required this.initials,
    required this.isVideo,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

enum _CallPhase { ringing, connected }

class _CallScreenState extends State<CallScreen> {
  static const Color _green = AppTheme.primaryGreen;
  static const Color _green8 = AppTheme.bottleGreen;
  static const Color _red = Color(0xFFEF4444);

  _CallPhase _phase = _CallPhase.ringing;
  Timer? _ringTimer;
  Timer? _tickTimer;
  Duration _elapsed = Duration.zero;
  bool _muted = false;
  bool _secondaryOff = false; // speaker-off (voice) / camera-off (video)

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.light);
    _ringTimer = Timer(const Duration(milliseconds: 2200), _connect);
  }

  void _connect() {
    if (!mounted) return;
    setState(() => _phase = _CallPhase.connected);
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _ringTimer?.cancel();
    _tickTimer?.cancel();
    super.dispose();
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _endCall() {
    final connected = _phase == _CallPhase.connected && _elapsed.inSeconds > 0;
    Navigator.pop(context, connected ? _elapsed : null);
  }

  @override
  Widget build(BuildContext context) {
    final ringing = _phase == _CallPhase.ringing;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _endCall();
      },
      child: Scaffold(
        backgroundColor: widget.isVideo ? Colors.black : AppTheme.surfaceColor,
        body: SafeArea(
          child: Stack(
            children: [
              if (widget.isVideo) Positioned.fill(child: _buildVideoBackdrop()),
              Column(
                children: [
                  const SizedBox(height: 36),
                  if (!widget.isVideo) _buildAvatar(size: 120, fontSize: 40),
                  SizedBox(height: widget.isVideo ? 12 : 22),
                  Text(
                    widget.calleeName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ringing
                        ? (widget.isVideo ? 'Video calling…' : 'Calling…')
                        : _format(_elapsed),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (widget.isVideo && !ringing) _buildSelfPreview(),
                  const SizedBox(height: 28),
                  _buildControls(ringing),
                  const SizedBox(height: 36),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoBackdrop() {
    // Placeholder "remote video" surface — no real camera feed available.
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B1120), Colors.black],
        ),
      ),
      child: Center(child: _buildAvatar(size: 140, fontSize: 46)),
    );
  }

  Widget _buildAvatar({required double size, required double fontSize}) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_green, AppTheme.primaryGreenDark],
        ),
      ),
      child: Center(
        child: Text(
          widget.initials,
          style: TextStyle(color: _green8, fontSize: fontSize, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildSelfPreview() {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 20, top: 4),
        child: Container(
          width: 84,
          height: 112,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: _secondaryOff
              ? const Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 26)
              : const Icon(Icons.person_rounded, color: Colors.white54, size: 36),
        ),
      ),
    );
  }

  Widget _buildControls(bool ringing) {
    if (ringing) {
      return _endCallButton();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _controlButton(
          icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
          active: _muted,
          onTap: () => setState(() => _muted = !_muted),
        ),
        const SizedBox(width: 22),
        _endCallButton(),
        const SizedBox(width: 22),
        _controlButton(
          icon: widget.isVideo
              ? (_secondaryOff ? Icons.videocam_off_rounded : Icons.videocam_rounded)
              : (_secondaryOff ? Icons.volume_off_rounded : Icons.volume_up_rounded),
          active: _secondaryOff,
          onTap: () => setState(() => _secondaryOff = !_secondaryOff),
        ),
      ],
    );
  }

  Widget _controlButton({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: active ? const Color(0xFF0F172A) : Colors.white, size: 24),
      ),
    );
  }

  Widget _endCallButton() {
    return GestureDetector(
      onTap: _endCall,
      child: Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(color: _red, shape: BoxShape.circle),
        child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}
