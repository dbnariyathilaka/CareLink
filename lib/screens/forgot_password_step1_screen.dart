import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/no_underline_text_editing_controller.dart';
import '../widgets/status_bar.dart';

class ForgotPasswordStep1Screen extends StatefulWidget {
  const ForgotPasswordStep1Screen({super.key});

  @override
  State<ForgotPasswordStep1Screen> createState() =>
      _ForgotPasswordStep1ScreenState();
}

class _ForgotPasswordStep1ScreenState extends State<ForgotPasswordStep1Screen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = NoUnderlineTextEditingController();
  bool _sending = false;

  static final RegExp _emailFormat = RegExp(r'^[\w\.\-\+]+@[\w\-]+\.[\w\-\.]+$');

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  static const Color darkGreen = Color(0xFF06402B);
  static const Color creamBg = Color(0xFFF6F0E2);
  static const Color borderColor = Color.fromRGBO(0, 0, 0, 0.3);
  static const Color hintColor = Color.fromRGBO(0, 0, 0, 0.38);
  static const Color labelColor = Color.fromRGBO(0, 0, 0, 0.85);
  static const Color mutedColor = Color.fromRGBO(0, 0, 0, 0.5);

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
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

  // Order matches what's asked for: Form.validate() already runs the
  // TextFormField's validator top-to-bottom (empty check, then format
  // check) and refuses to proceed past either. The registered-or-not check
  // then goes through AuthService.isEmailRegistered (a Firestore existence
  // index — see its doc comment) rather than relying on
  // sendPasswordResetEmail's own error, which this Firebase project's
  // email-enumeration-protection setting makes unreliable: it succeeds
  // silently for unregistered addresses too.
  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate() || _sending) return;
    final email = _emailController.text.trim();
    setState(() => _sending = true);
    try {
      final registered = await AuthService.isEmailRegistered(email);
      if (!mounted) return;
      if (!registered) {
        await _showNotRegisteredDialog(email);
        return;
      }
      await AuthService.sendPasswordResetEmail(email);
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        '/forgot-password-email-sent',
        arguments: email,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'user-not-found') {
        await _showNotRegisteredDialog(email);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthService.messageForPasswordResetError(e))),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send the reset email. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // "Not registered" is surfaced as a popup (not a snackbar) per what was
  // asked — Firebase only reports this when the project's email-enumeration
  // protection is off; if it's on, Firebase always reports success instead
  // (a deliberate security tradeoff made at the Firebase-project level, not
  // something this client code can see or override).
  Future<void> _showNotRegisteredDialog(String email) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.mail_outline_rounded, color: darkGreen, size: 52),
              const SizedBox(height: 16),
              const Text(
                'Email not registered',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: darkGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "We couldn't find an account for $email. Double-check the address, or create a new account.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: mutedColor,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: darkGreen,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.pop(dialogCtx),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        'OK',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: creamBg,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
              // Back Button
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
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
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
                            fontFamily: 'Quattrocento Sans',
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                            color: darkGreen,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Ornate key illustration
                        Center(
                          child: Image.asset(
                            'assets/images/forgot_password_key.png',
                            width: 260,
                            height: 254,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Subtitle
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            "Enter the email linked to your account and we'll send you a link to reset your password.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 17,
                              fontWeight: FontWeight.normal,
                              color: darkGreen,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Email Field
                        _buildTextField(
                          label: 'Email',
                          hintText: 'nipuni@email.com',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            final trimmed = value?.trim() ?? '';
                            if (trimmed.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!_emailFormat.hasMatch(trimmed)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        // Send reset code Button
                        Container(
                          width: double.infinity,
                          height: 58,
                          decoration: BoxDecoration(
                            color: darkGreen,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: darkGreen.withValues(alpha: 0.5),
                                blurRadius: 2,
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(15),
                              onTap: _sending ? null : _sendResetEmail,
                              child: Center(
                                child: _sending
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: creamBg,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text(
                                        'Send reset link',
                                        style: TextStyle(
                                          color: creamBg,
                                          fontSize: 18,
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
                                    text: 'Remembered your password? ',
                                    style: TextStyle(
                                      color: mutedColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Login',
                                    style: TextStyle(
                                      color: darkGreen,
                                      fontWeight: FontWeight.w600,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: labelColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            fontFamily: 'Inter',
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: hintColor,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              fontFamily: 'Inter',
            ),
            filled: false,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 17,
              vertical: 17,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: borderColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: borderColor, width: 1),
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
