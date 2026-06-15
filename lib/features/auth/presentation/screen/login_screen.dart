import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interviewer/features/auth/presentation/screen/otp_screen.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final TextEditingController _inputController;
  final _formKey = GlobalKey<FormState>();

  // Timer state for managing the 45 seconds cooldown
  Timer? _cooldownTimer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _inputController.dispose();
    super.dispose();
  }

  void _startCooldownTimer() {
    setState(() {
      _secondsRemaining = 45;
    });
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 1) {
        setState(() {
          _secondsRemaining = 0;
        });
        timer.cancel();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // Guard against submissions if accidental button hits bypass standard state
    if (_secondsRemaining > 0) return;

    // Dismiss keyboard smoothly before triggering authentication state mutations
    FocusManager.instance.primaryFocus?.unfocus();

    final success = await ref
        .read(authControllerProvider.notifier)
        .sentMobileNumber(_inputController.text.trim());

    if (success && mounted) {
      _startCooldownTimer(); // Lock window upon success
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OtpScreen()),
      );
    } else if (mounted) {
      final authState = ref.read(authControllerProvider);
      if (authState.message.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authState.message),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final bool isButtonDisabled = authState.isLoading || _secondsRemaining > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Form(
                key: _formKey,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Top Spacing / Branding Title
                      Column(
                        children: [
                          const SizedBox(height: 40),
                          Text(
                            "INTERVIEWER",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),

                      // Centered Content & Input Section
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Text(
                              'Enter your WhatsApp number below to receive a secure login verification code.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 36),

                          // Centered Phone Number Input Field
                          TextFormField(
                            controller: _inputController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            enabled: !authState.isLoading,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                              letterSpacing: 1.0,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            decoration: InputDecoration(
                              hintText: '00000 00000',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade300,
                                fontWeight: FontWeight.normal,
                                letterSpacing: 1.0,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                              filled: true,
                              fillColor: const Color(0xFFF8F9FA),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFF1A1A1A), width: 1.8),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Colors.redAccent),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your phone number';
                              }
                              if (value.trim().length < 10) {
                                return 'Phone number must be 10 digits';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => isButtonDisabled ? null : _handleLogin(),
                          ),
                        ],
                      ),

                      // Execution Footer Trigger with dynamic resend feedback
                      Padding(
                        padding: const EdgeInsets.only(bottom: 32.0, top: 20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A1A1A),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey.shade200,
                                  disabledForegroundColor: Colors.grey.shade500,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: isButtonDisabled ? null : _handleLogin,
                                child: authState.isLoading
                                    ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                                    : Text(
                                  _secondsRemaining > 0
                                      ? 'Resend Code in ${_secondsRemaining}s'
                                      : 'Get Verification Code',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.2,
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
          },
        ),
      ),
    );
  }
}