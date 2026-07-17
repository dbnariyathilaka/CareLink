import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';

class AccountDetailsScreen extends StatefulWidget {
  const AccountDetailsScreen({super.key});

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController    = TextEditingController();
  final _emailController       = TextEditingController();
  final _phoneController       = TextEditingController();
  final _passwordController    = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _googleSignedIn = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  static final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
      if (account != null && mounted) {
        setState(() {
          _googleSignedIn = true;
          // Auto-fill name and email from Google account
          _fullNameController.text = account.displayName ?? '';
          _emailController.text    = account.email;
          // Google does not expose phone — leave field empty for user to fill
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signed in as ${account.displayName}'),
            backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.9),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
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
            children: [
              // Back button
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 5),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppTheme.textPrimary,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 34,
                      minHeight: 34,
                    ),
                  ),
                ),
              ),

              Expanded(
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          const Text(
                            'Account details',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),

                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Scrollable form
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Full name (auto-filled from Google)
                              CustomTextField(
                                label: 'Full name',
                                hintText: 'e.g. Nipuni Ariyathilaka',
                                controller: _fullNameController,
                                labelFontSize: 12,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your full name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 13),

                              // Email (auto-filled from Google)
                              CustomTextField(
                                label: 'Email',
                                hintText: 'you@email.com',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                labelFontSize: 12,
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
                              const SizedBox(height: 13),

                              // Phone (manual – Google doesn't expose this)
                              Stack(
                                children: [
                                  CustomTextField(
                                    label: 'Phone',
                                    hintText: '77 123 4567',
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    labelFontSize: 12,
                                    prefixText: '+94',
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your phone number';
                                      }
                                      return null;
                                    },
                                  ),
                                  if (_googleSignedIn)
                                    Positioned(
                                      right: 12,
                                      top: 0,
                                      bottom: 0,
                                      child: Center(
                                        child: Text(
                                          'Enter manually',
                                          style: TextStyle(
                                            color: AppTheme.textSecondary
                                                .withValues(alpha: 0.6),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 13),

                              // Password — hidden when signed in via Google
                              if (!_googleSignedIn) ...[
                                CustomTextField(
                                  label: 'Password',
                                  hintText: 'At least 8 characters',
                                  controller: _passwordController,
                                  isPassword: true,
                                  labelFontSize: 12,
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
                                const SizedBox(height: 13),
                                CustomTextField(
                                  label: 'Confirm password',
                                  hintText: 'Repeat password',
                                  controller: _confirmPasswordController,
                                  isPassword: true,
                                  labelFontSize: 12,
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
                                      horizontal: 14, vertical: 11),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppTheme.primaryGreen
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded,
                                          color: AppTheme.primaryGreen,
                                          size: 18),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Authenticated via Google · password not required',
                                          style: TextStyle(
                                            color: AppTheme.primaryGreen
                                                .withValues(alpha: 0.9),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Continue button pinned at bottom
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(28, 18, 28, 36),
                      child: SizedBox(
                        width: double.infinity,
                        child: Material(
                          color: AppTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              if (_formKey.currentState!.validate()) {
                                // Go to account created screen, passing the name
                                Navigator.pushNamed(
                                  context,
                                  '/account-created',
                                  arguments: {'name': _fullNameController.text},
                                );
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                'Continue',
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


}
