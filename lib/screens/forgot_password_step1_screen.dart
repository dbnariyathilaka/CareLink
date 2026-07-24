import 'package:flutter/material.dart';

class ForgotPasswordStep1Screen extends StatefulWidget {
  const ForgotPasswordStep1Screen({super.key});

  @override
  State<ForgotPasswordStep1Screen> createState() =>
      _ForgotPasswordStep1ScreenState();
}

class _ForgotPasswordStep1ScreenState extends State<ForgotPasswordStep1Screen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                        // Title: Forgot password?
                        const Text(
                          'Forgot password?',
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

                        // Beautiful Custom Key Vector Art
                        Center(
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: darkGreen.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: CustomPaint(
                              painter: _KeyIconPainter(color: darkGreen),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Subtitle
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            "Enter the email linked to your account and we'll send you a link to reset your password.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.normal,
                              color: darkGreen,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Email Field
                        _buildTextField(
                          label: 'Email',
                          hintText: 'nipuni@email.com',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        // Send reset code Button (rounded-[15px] matching Figma)
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
                                if (_formKey.currentState!.validate()) {
                                  Navigator.pushNamed(
                                    context,
                                    '/forgot-password-email-sent',
                                    arguments: _emailController.text.trim(),
                                  );
                                }
                              },
                              child: const Center(
                                child: Text(
                                  'Send reset link',
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
                        const SizedBox(height: 24),

                        // Footer Link (centered)
                        Center(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                ),
                                children: [
                                  TextSpan(
                                    text: "Remembered your password? ",
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8), // Gull Gray
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Login in',
                                    style: TextStyle(
                                      color: darkGreen,
                                      fontWeight: FontWeight.bold,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    const Color darkGreen = Color(0xFF06402B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: darkGreen,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.black.withValues(alpha: 0.3),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            filled: false,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: Colors.black.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: Colors.black.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: darkGreen,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: Colors.redAccent,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: Colors.redAccent,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter for a stylized key icon in vector lines
class _KeyIconPainter extends CustomPainter {
  final Color color;
  _KeyIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Draw the key head (circle at the top-left or top)
    // Circle centered at (cx, cy - 20) with radius 20
    canvas.drawCircle(Offset(cx, cy - 20), 22, strokePaint);
    canvas.drawCircle(Offset(cx, cy - 20), 8, fillPaint); // inner hole

    // Draw the key shaft (going down)
    final shaftPath = Path();
    shaftPath.moveTo(cx, cy + 2);
    shaftPath.lineTo(cx, cy + 40);
    canvas.drawPath(shaftPath, strokePaint);

    // Draw the key teeth (projecting to the right)
    final teethPath = Path();
    teethPath.moveTo(cx, cy + 16);
    teethPath.lineTo(cx + 14, cy + 16);
    teethPath.moveTo(cx, cy + 30);
    teethPath.lineTo(cx + 14, cy + 30);
    teethPath.lineTo(cx + 14, cy + 22);
    canvas.drawPath(teethPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
