import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_state.dart';
import '../services/auth_service.dart';
import '../widgets/no_underline_text_editing_controller.dart';
import '../widgets/status_bar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = NoUnderlineTextEditingController();
  final _passwordController = NoUnderlineTextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  static const Color bgColor = Color(0xFFF5EEDE);
  static const Color titleColor = Color(0xFF033724);
  static const Color darkGreen = Color(0xFF06402B);
  static const Color buttonTextColor = Color(0xFFF6F0E2);
  static const Color labelColor = Color.fromRGBO(0, 0, 0, 0.85);
  static const Color borderColor = Color.fromRGBO(0, 0, 0, 0.3);
  static const Color hintColor = Color.fromRGBO(0, 0, 0, 0.38);

  @override
  void initState() {
    super.initState();
    setStatusBarStyle(Brightness.dark);
    AppState.reset();
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
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final inputEmail = _emailController.text.trim().toLowerCase();
    final inputPassword = _passwordController.text;

    // Admin shortcut — this still has to establish a REAL Firebase Auth
    // session (not just navigate straight to the dashboard the way this
    // used to work), because every Firestore security rule requires
    // request.auth to be non-null, and the admin screens now run real
    // queries against those rules. Self-provisions the admin account +
    // users/{uid}.role = 'admin' on first use if it doesn't exist yet, and
    // re-asserts the role on every login so it can never drift.
    if (inputEmail == 'admin@gmail.com' && inputPassword == 'admin1234') {
      setState(() => _isSubmitting = true);
      try {
        UserCredential credential;
        try {
          credential = await AuthService.signInWithEmail(email: inputEmail, password: inputPassword);
        } on FirebaseAuthException catch (e) {
          // Modern Firebase projects have email-enumeration protection on
          // by default, which makes "no such account" return the same
          // invalid-credential code as "wrong password" — not the older
          // user-not-found — so both are treated as "try creating it" here.
          // If the account genuinely exists with a different password,
          // registerWithEmail below fails with email-already-in-use and
          // that real error is what gets shown, not a silent misfire.
          if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
            try {
              credential = await AuthService.registerWithEmail(email: inputEmail, password: inputPassword);
            } on FirebaseAuthException catch (registerError) {
              if (registerError.code == 'email-already-in-use') {
                throw FirebaseAuthException(
                  code: 'wrong-password',
                  message: 'This admin account already exists with a different password.',
                );
              }
              rethrow;
            }
          } else {
            rethrow;
          }
        }
        final uid = credential.user!.uid;
        await AuthService.saveUserProfile(uid: uid, name: 'Admin', email: inputEmail, role: 'admin');
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/admin-dashboard', (route) => false);
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AuthService.messageForSignInError(e)), backgroundColor: Colors.red.shade700),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Admin login failed: $e'), backgroundColor: Colors.red.shade700),
          );
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      AppState.reset();
      final credential = await AuthService.signInWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );
      final uid = credential.user!.uid;
      final profile = await AuthService.getUserProfile(uid);
      final role = profile?['role'] as String?;

      if (!mounted) return;

      if (role == 'admin') {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/admin-dashboard',
          (route) => false,
        );
      } else if (role == 'caregiver') {
        // A caregiver who never finished onboarding still gets into their
        // dashboard — their account is no longer deleted on login. What
        // they can't do (accept a job) is gated at that specific action
        // instead, via ensureCaregiverProfileComplete (profile_gate.dart),
        // which explains what's missing rather than wiping their account.
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/caregiver-dashboard',
          (route) => false,
        );
      } else if (role == 'patient') {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/patient-dashboard',
          (route) => false,
        );
      } else {
        // Account exists but hasn't finished choosing a role yet.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Your account setup is incomplete. Please choose a role to continue.'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/role-selection',
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AuthService.messageForSignInError(e)),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
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
                  padding: const EdgeInsets.fromLTRB(23, 0, 23, 30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Hands + heart CareLink icon
                        Center(
                          child: Image.asset(
                            'assets/images/login_icon.png',
                            width: 150,
                            height: 159,
                          ),
                        ),
                        const SizedBox(height: 17),

                        // Title: Welcome Back !
                        const Text(
                          'Welcome Back !',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Quattrocento Sans',
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 39),

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
                        const SizedBox(height: 17),

                        // Password Field
                        _buildTextField(
                          label: 'Password',
                          hintText: '••••••••',
                          controller: _passwordController,
                          isPassword: true,
                          obscureText: _obscurePassword,
                          onToggleObscure: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Forgot Password Link (right-aligned)
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/forgot-password');
                            },
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: labelColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 61),

                        // Login Button
                        Container(
                          width: double.infinity,
                          height: 59,
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
                              onTap: _isSubmitting ? null : _handleLogin,
                              child: Center(
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  buttonTextColor),
                                        ),
                                      )
                                    : const Text(
                                        'Login',
                                        style: TextStyle(
                                          fontFamily: 'Quattrocento Sans',
                                          color: buttonTextColor,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Footer Link (centered)
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushReplacementNamed(
                                context,
                                '/role-selection',
                              );
                            },
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                ),
                                children: [
                                  TextSpan(
                                    text: "Don't have an account? ",
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8), // Gull Gray
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Sign in',
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
    bool isPassword = false,
    bool obscureText = true,
    VoidCallback? onToggleObscure,
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
          obscureText: isPassword && obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            fontFamily: 'Inter',
            letterSpacing: 3,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: hintColor,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              fontFamily: 'Inter',
              letterSpacing: 3,
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
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: borderColor,
                      size: 20,
                    ),
                    onPressed: onToggleObscure,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
