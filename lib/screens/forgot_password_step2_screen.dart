import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ForgotPasswordStep2Screen extends StatefulWidget {
  const ForgotPasswordStep2Screen({super.key});

  @override
  State<ForgotPasswordStep2Screen> createState() =>
      _ForgotPasswordStep2ScreenState();
}

class _ForgotPasswordStep2ScreenState extends State<ForgotPasswordStep2Screen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final List<TextEditingController> _codeControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _codeFocusNodes = List.generate(6, (_) => FocusNode());

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOut,
      ),
    );

    _fadeController.forward();

    // Auto-focus transitions
    for (int i = 0; i < 6; i++) {
      _codeFocusNodes[i].addListener(() => setState(() {}));
      _codeControllers[i].addListener(() {
        if (_codeControllers[i].text.length == 1 && i < 5) {
          _codeFocusNodes[i + 1].requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _codeFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email =
        (ModalRoute.of(context)?.settings.arguments as String?) ??
            'nipuni@email.com';

    const Color creamBg = Color(0xFFF6F0E2);
    const Color darkGreen = Color(0xFF06402B);

    return Scaffold(
      backgroundColor: creamBg,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _fadeController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: child,
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button (arrow icon in forest green)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 12),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: darkGreen,
                    size: 22,
                  ),
                  onPressed: () => Navigator.pop(context),
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ),

              // Form Scrollable Container
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title: Check your email
                        const Text(
                          'Check your email',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: darkGreen,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Envelope Vector Art
                        Center(
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: darkGreen.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: CustomPaint(
                              painter: _EnvelopeIconPainter(color: darkGreen),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Subtitle
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 20,
                                color: darkGreen,
                                height: 1.4,
                              ),
                              children: [
                                const TextSpan(text: 'We sent a 6-digit code to '),
                                TextSpan(
                                  text: email,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),

                        // 6-digit Code Inputs (Row)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (i) {
                            final controller = _codeControllers[i];
                            final focusNode = _codeFocusNodes[i];
                            final isFocused = focusNode.hasFocus;

                            return Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: darkGreen.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: darkGreen,
                                  width: isFocused ? 2.0 : 0.0,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: KeyboardListener(
                                focusNode: FocusNode(), // Dummy node for backspace catching
                                onKeyEvent: (event) {
                                  if (event is KeyDownEvent &&
                                      event.logicalKey ==
                                          LogicalKeyboardKey.backspace &&
                                      controller.text.isEmpty &&
                                      i > 0) {
                                    _codeFocusNodes[i - 1].requestFocus();
                                  }
                                },
                                child: TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  maxLength: 1,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: darkGreen,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: const InputDecoration(
                                    counterText: '',
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (val) {
                                    setState(() {});
                                  },
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 48),

                        // Reset Password Button (rounded-[15px] matching Figma)
                        Container(
                          width: double.infinity,
                          height: 58,
                          decoration: BoxDecoration(
                            color: darkGreen,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF06402B).withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(2, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(15),
                              onTap: () {
                                final codeFilled = _codeControllers.every(
                                    (controller) =>
                                        controller.text.isNotEmpty);
                                if (!codeFilled) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter the 6-digit code'),
                                    ),
                                  );
                                  return;
                                }
                                Navigator.pushNamed(
                                  context,
                                  '/forgot-password-new',
                                  arguments: email,
                                );
                              },
                              child: const Center(
                                child: Text(
                                  'Reset Password',
                                  style: TextStyle(
                                    color: creamBg,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for a stylized envelope icon in vector lines
class _EnvelopeIconPainter extends CustomPainter {
  final Color color;
  _EnvelopeIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Draw outer envelope rectangle
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: 70, height: 48);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), strokePaint);

    // Draw envelope folds (triangle)
    final foldPath = Path();
    foldPath.moveTo(cx - 35, cy - 24);
    foldPath.lineTo(cx, cy + 4);
    foldPath.lineTo(cx + 35, cy - 24);
    canvas.drawPath(foldPath, strokePaint);

    // Draw bottom corner folds
    final bottomFolds = Path();
    bottomFolds.moveTo(cx - 35, cy + 24);
    bottomFolds.lineTo(cx - 10, cy + 4);
    bottomFolds.moveTo(cx + 35, cy + 24);
    bottomFolds.lineTo(cx + 10, cy + 4);
    canvas.drawPath(bottomFolds, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
