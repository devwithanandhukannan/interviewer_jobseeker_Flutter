import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
  }

  @override
  void dispose() {
    _inputController.dispose(); // Prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(authState.message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                TextField(
                  controller: _inputController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Enter your phone number',
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: authState.isLoading
                      ? null
                      : () async {
                    // Dismiss keyboard smoothly before tracking transitions
                    FocusManager.instance.primaryFocus?.unfocus();

                    final success = await ref
                        .read(authControllerProvider.notifier)
                        .sentMobileNumber(_inputController.text.trim());

                    if (success && context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OtpScreen()),
                      );
                    }
                  },
                  child: authState.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Send OTP'),
                )
              ],
            ),
          ),
        )
    );
  }
}