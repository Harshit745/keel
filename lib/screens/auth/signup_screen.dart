import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../home_screen.dart';
import '../onboarding_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  static const Color _backgroundColor = Color(0xFF0D0D0D);
  static const Color _cardColor = Color(0xFF1A1A1A);
  static const Color _purple = Color(0xFF6C63FF);
  static const Color _amber = Color(0xFFF5A623);
  static const Color _green = Color(0xFF1DB954);
  static const Color _red = Color(0xFFE53935);
  static const Color _mutedWhite = Color(0x80FFFFFF);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  Timer? _errorTimer;
  final Set<String> _touchedFields = <String>{};

  @override
  void initState() {
    super.initState();
    _attachTouchListeners();
  }

  void _attachTouchListeners() {
    _nameFocusNode.addListener(() => _markTouched('name', _nameFocusNode));
    _emailFocusNode.addListener(() => _markTouched('email', _emailFocusNode));
    _passwordFocusNode.addListener(
      () => _markTouched('password', _passwordFocusNode),
    );
    _confirmPasswordFocusNode.addListener(
      () => _markTouched('confirm', _confirmPasswordFocusNode),
    );
  }

  void _markTouched(String key, FocusNode focusNode) {
    if (!focusNode.hasFocus && mounted) {
      setState(() {
        _touchedFields.add(key);
      });
    }
  }

  @override
  void dispose() {
    _errorTimer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _showError(String message) {
    _errorTimer?.cancel();
    setState(() {
      _errorMessage = message;
    });
    _errorTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _errorMessage = null;
        });
      }
    });
  }

  String? _fieldError(String key, String? value) {
    if (!_touchedFields.contains(key)) {
      return null;
    }
    switch (key) {
      case 'name':
        return value == null || value.trim().length < 2
            ? 'Please enter your full name.'
            : null;
      case 'email':
        return value == null || !value.contains('@') || !value.contains('.')
            ? 'Enter a valid email address.'
            : null;
      case 'password':
        return value == null || value.length < 6
            ? 'Password must be at least 6 characters.'
            : null;
      case 'confirm':
        return value != _passwordController.text
            ? 'Passwords do not match.'
            : null;
      default:
        return null;
    }
  }

  ({Color color, double factor}) _passwordStrength() {
    final String password = _passwordController.text;
    if (password.length < 8) {
      return (color: _red, factor: 0.33);
    }
    final bool hasComplexity = RegExp(
      r'[0-9!@#\$%^&*(),.?":{}|<>]',
    ).hasMatch(password);
    if (!hasComplexity) {
      return (color: _amber, factor: 0.66);
    }
    return (color: _green, factor: 1.0);
  }

  Future<void> _routeAfterAuth() async {
    final bool onboarded = await UserService.isOnboarded();
    if (!mounted) {
      return;
    }
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            onboarded ? const HomeScreen() : const OnboardingScreen(),
      ),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _createAccount() async {
    setState(() {
      _touchedFields.addAll(<String>['name', 'email', 'password', 'confirm']);
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signUpWithEmail(
        _emailController.text,
        _passwordController.text,
      );
      await FirebaseAuth.instance.currentUser?.updateDisplayName(
        _nameController.text.trim(),
      );
      await _routeAfterAuth();
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final Object? result = await _authService.signInWithGoogle();
      if (result == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }
      await _routeAfterAuth();
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _appleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithApple();
      await _routeAfterAuth();
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration({
    required IconData icon,
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: _cardColor,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
      prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.4)),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _purple, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _red, width: 1),
      ),
    );
  }

  Widget _buildSocialButton({
    required VoidCallback? onTap,
    required Widget leading,
    required String label,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor, width: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            leading,
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(fontSize: 15, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ({Color color, double factor}) strength = _passwordStrength();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _backgroundColor,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 18),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Create account',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join thousands improving their LifeScore',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      icon: Icons.person_outline,
                      hint: 'Full name',
                    ),
                    validator: (String? value) {
                      return _fieldError('name', value);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      icon: Icons.email_outlined,
                      hint: 'Email address',
                    ),
                    validator: (String? value) {
                      return _fieldError('email', value);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      icon: Icons.lock_outline,
                      hint: 'Password',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (String? value) {
                      return _fieldError('password', value);
                    },
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          return Container(
                            width: constraints.maxWidth,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                width: constraints.maxWidth * strength.factor,
                                decoration: BoxDecoration(
                                  color: strength.color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          );
                        },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocusNode,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      icon: Icons.lock_outline,
                      hint: 'Confirm password',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    validator: (String? value) {
                      return _fieldError('confirm', value);
                    },
                    onFieldSubmitted: (_) => _createAccount(),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _purple,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _purple.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Create account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _errorMessage == null
                        ? const SizedBox.shrink()
                        : Row(
                            key: ValueKey<String>(_errorMessage!),
                            children: <Widget>[
                              const Icon(
                                Icons.error_outline,
                                color: _red,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: _red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Divider(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSocialButton(
                    onTap: _isLoading ? null : _googleSignIn,
                    leading: const Text(
                      'G',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDB4437),
                      ),
                    ),
                    label: 'Continue with Google',
                    backgroundColor: _cardColor,
                    borderColor: Colors.white24,
                  ),
                  if (Platform.isIOS) ...<Widget>[
                    const SizedBox(height: 12),
                    _buildSocialButton(
                      onTap: _isLoading ? null : _appleSignIn,
                      leading: const Icon(
                        Icons.apple,
                        size: 22,
                        color: Colors.white,
                      ),
                      label: 'Continue with Apple',
                      backgroundColor: Colors.black,
                      borderColor: Colors.white24,
                    ),
                  ],
                  const SizedBox(height: 28),
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: RichText(
                        text: const TextSpan(
                          text: 'Already have an account? ',
                          style: TextStyle(fontSize: 14, color: _mutedWhite),
                          children: <InlineSpan>[
                            TextSpan(
                              text: 'Sign in',
                              style: TextStyle(
                                color: _purple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
