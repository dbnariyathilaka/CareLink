import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class ForgotPasswordStep2Screen extends StatefulWidget {
  const ForgotPasswordStep2Screen({super.key});

  @override
  State<ForgotPasswordStep2Screen> createState() =>
      _ForgotPasswordStep2ScreenState();
}

class _ForgotPasswordStep2ScreenState extends State<ForgotPasswordStep2Screen> {
  final _formKey = GlobalKey<FormState>();

  final List<TextEditingController> _codeControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _codeFocusNodes = List.generate(6, (_) => FocusNode());

  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final FocusNode _newPasswordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  Timer? _timer;
  int _secondsRemaining = 48;

  @override
  void initState() {
    super.initState();
    _startTimer();

    // Listen to focus changes to rebuild borders
    _newPasswordFocus.addListener(() => setState(() {}));
    _confirmPasswordFocus.addListener(() => setState(() {}));

    for (int i = 0; i < 6; i++) {
      _codeFocusNodes[i].addListener(() => setState(() {}));
      _codeControllers[i].addListener(() {
        if (_codeControllers[i].text.length == 1 && i < 5) {
          _codeFocusNodes[i + 1].requestFocus();
        }
      });
    }
  }

  void _startTimer() {
    _secondsRemaining = 48;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _codeFocusNodes) {
      node.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _newPasswordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final email =
        (ModalRoute.of(context)?.settings.arguments as String?) ??
            'nipuni@email.com';

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top back button
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
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

            // Scrollable form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      const Text(
                        'Check your email',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Envelope icon with circle background
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.email_outlined,
                            color: AppTheme.primaryGreen,
                            size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Verification info label
                      Text.rich(
                        TextSpan(
                          text: 'We sent a 6-digit code to ',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            TextSpan(
                              text: email,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // 6-digit code inputs
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (i) {
                          final controller = _codeControllers[i];
                          final focusNode = _codeFocusNodes[i];
                          final hasValue = controller.text.isNotEmpty;
                          final isFocused = focusNode.hasFocus;

                          return Container(
                            width: 44,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppTheme.inputBackground,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isFocused || hasValue
                                    ? AppTheme.primaryGreen
                                    : const Color(0xFF334155),
                                width: 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: KeyboardListener(
                              focusNode: FocusNode(), // Dummy node for key events
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
                                  color: AppTheme.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
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
                      const SizedBox(height: 14),

                      // Resend Code timer / option
                      GestureDetector(
                        onTap: _secondsRemaining == 0 ? _startTimer : null,
                        child: Text.rich(
                          TextSpan(
                            text: "Didn't get it? ",
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            children: [
                              TextSpan(
                                text: 'Resend code',
                                style: TextStyle(
                                  color: _secondsRemaining == 0
                                      ? AppTheme.primaryGreen
                                      : AppTheme.primaryGreen.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (_secondsRemaining > 0)
                                TextSpan(
                                  text: ' in ${_formatDuration(_secondsRemaining)}',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // New Password Label & Field
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'New password',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: AppTheme.inputBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _newPasswordFocus.hasFocus
                                ? AppTheme.primaryGreen
                                : const Color(0xFF334155),
                            width: 1,
                          ),
                        ),
                        child: TextFormField(
                          controller: _newPasswordController,
                          focusNode: _newPasswordFocus,
                          obscureText: _obscureNewPassword,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 17, vertical: 16),
                            isDense: true,
                            hintText: 'Enter new password',
                            hintStyle: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 15,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureNewPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF94A3B8),
                                size: 19,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureNewPassword = !_obscureNewPassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a new password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password Label & Field
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Confirm new password',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: AppTheme.inputBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _confirmPasswordFocus.hasFocus
                                ? AppTheme.primaryGreen
                                : const Color(0xFF334155),
                            width: 1,
                          ),
                        ),
                        child: TextFormField(
                          controller: _confirmPasswordController,
                          focusNode: _confirmPasswordFocus,
                          obscureText: _obscureConfirmPassword,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 17, vertical: 16),
                            isDense: true,
                            hintText: 'Confirm new password',
                            hintStyle: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 15,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF94A3B8),
                                size: 19,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your new password';
                            }
                            if (value != _newPasswordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Button: Reset Password
                      SizedBox(
                        width: double.infinity,
                        child: Material(
                          color: AppTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
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
                              if (_formKey.currentState!.validate()) {
                                Navigator.pushNamed(
                                  context,
                                  '/forgot-password-step3',
                                );
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                'Reset password',
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
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
