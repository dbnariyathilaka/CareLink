import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../app_state.dart';
import '../services/auth_service.dart';
import '../widgets/no_underline_text_editing_controller.dart';
import '../widgets/status_bar.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = NoUnderlineTextEditingController();
  final _emailController = NoUnderlineTextEditingController();
  final _phoneController = NoUnderlineTextEditingController();
  final _passwordController = NoUnderlineTextEditingController();
  final _confirmPasswordController = NoUnderlineTextEditingController();

  bool _googleSignedIn = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
  String? _role;
  String? _careRecipient;
  UserCredential? _googleUserCredential;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  static final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

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
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // If welcome screen passed triggerGoogle: true, auto-trigger sign-in
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['role'] is String) {
      _role = args['role'] as String;
    }
    if (args is Map && args['careRecipient'] is String) {
      _careRecipient = args['careRecipient'] as String;
    }
    if (args is Map && args['triggerGoogle'] == true && !_googleSignedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleGoogleSignIn());
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Google Sign-In ────────────────────────────────────────
  Future<void> _handleGoogleSignIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return;

      final googleAuth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential =
          await AuthService.signInWithGoogleCredential(credential);

      if (mounted) {
        setState(() {
          _googleSignedIn = true;
          _googleUserCredential = userCredential;
          _fullNameController.text = account.displayName ?? '';
          _emailController.text = account.email;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signed in as ${account.displayName}'),
            backgroundColor: const Color(0xFF06402B),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AuthService.messageForRegisterError(e)),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign-in failed: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  // ── Submit (email/password or finalize Google account) ────
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    // Tracks whether *this* call minted a brand-new email/password Auth
    // account, so a later failure can roll just that back — a
    // pre-existing Google account should never be deleted just because
    // the Firestore profile write that follows it failed.
    String? newAccountUid;
    try {
      final String uid;
      if (_googleSignedIn && _googleUserCredential != null) {
        uid = _googleUserCredential!.user!.uid;
      } else {
        final credential = await AuthService.registerWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );
        uid = credential.user!.uid;
        newAccountUid = uid;
      }

      await AuthService.saveUserProfile(
        uid: uid,
        name: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        role: _role,
      );

      // Patient onboarding no longer asks for the name again (Figma node
      // 123-418 dropped that field since it's already collected here) — so
      // seed it into AppState now, the only place it was ever written from.
      if (_role == 'patient') {
        AppState.patientName.value = _fullNameController.text.trim();
      }

      if (mounted) {
        Navigator.pushNamed(
          context,
          '/account-created',
          arguments: {
            'name': _fullNameController.text,
            'role': _role,
            'careRecipient': _careRecipient,
          },
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AuthService.messageForRegisterError(e)),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      // Something after the Auth account was created failed (e.g. the
      // Firestore profile write) — roll the new account back rather than
      // leaving it half-created, which would otherwise permanently block
      // retrying with the same email ("already exists") with no real
      // profile behind it.
      if (newAccountUid != null) {
        final email = _emailController.text.trim();
        try {
          await FirebaseAuth.instance.currentUser?.delete();
        } catch (_) {
          // best effort — don't let a failed rollback mask the real error
        }
        await AuthService.deleteUserProfile(newAccountUid, email);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not create your account: $e'),
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
    const Color creamBg = Color(0xFFF6F0E2);
    const Color darkGreen = Color(0xFF06402B);
    const Color titleGreen = Color(0xFF033724);

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
                padding: const EdgeInsets.only(left: 16, top: 8),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: darkGreen,
                    size: 22,
                  ),
                  onPressed: () => Navigator.pop(context),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),

              // Form — sized to fit in one frame, but scrollable as a
              // safety net so it doesn't overflow when the keyboard opens.
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 6, 24, 16),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Hands cradling a heart — CareLink brand icon
                        Center(
                          child: Image.asset(
                            'assets/images/login_icon.png',
                            width: 76,
                            height: 76,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Title: Create New Account
                        const Text(
                          'Create New Account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Quattrocento Sans',
                            fontSize: 27,
                            fontWeight: FontWeight.w700,
                            color: titleGreen,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Full Name Field
                        _buildTextField(
                          label: 'Full Name',
                          hintText: 'Nipuni Ariyathilaka',
                          controller: _fullNameController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your full name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

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
                        const SizedBox(height: 12),

                        // Phone Field
                        _buildTextField(
                          label: 'Phone number',
                          hintText: '71 185 6936',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          prefixText: '+94',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Password Fields (hidden when authenticated via Google)
                        if (!_googleSignedIn) ...[
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
                                  return 'Please enter a password';
                              }
                              if (value.length < 8) {
                                return 'Password must be at least 8 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            label: 'Confirm password',
                            hintText: '••••••••',
                            controller: _confirmPasswordController,
                            isPassword: true,
                            obscureText: _obscureConfirmPassword,
                            onToggleObscure: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ] else ...[
                          // Google sign-in pill indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: darkGreen.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: darkGreen.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: darkGreen, size: 20),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Authenticated via Google · password not required',
                                    style: TextStyle(
                                      color: darkGreen,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),

                        // Register Button (named 'Sign in' in Figma, rounded 15px)
                        Container(
                          width: double.infinity,
                          height: 52,
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
                              onTap: _isSubmitting ? null : _handleSubmit,
                              child: Center(
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  creamBg),
                                        ),
                                      )
                                    : const Text(
                                        'Sign in',
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
                        const SizedBox(height: 14),

                        // Footer Link (centered)
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushReplacementNamed(
                                context,
                                '/login',
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
                                    text: "Already have an account? ",
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8), // Gull Gray
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Login',
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
    String? prefixText,
  }) {
    const Color darkGreen = Color(0xFF06402B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: darkGreen,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: isPassword && obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.black.withValues(alpha: 0.38),
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            filled: false,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 13,
            ),
            prefixIcon: prefixText != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 18, right: 10),
                    child: Text(
                      prefixText,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                      ),
                    ),
                  )
                : null,
            prefixIconConstraints: prefixText != null
                ? const BoxConstraints(minWidth: 0, minHeight: 0)
                : null,
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
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.black.withValues(alpha: 0.4),
                      size: 22,
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
