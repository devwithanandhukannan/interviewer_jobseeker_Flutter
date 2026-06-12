import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interviewer/features/auth/presentation/screen/login_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:interviewer/features/auth/presentation/controllers/auth_controller.dart';
import 'package:interviewer/features/dashboard/presentation/screen/dashboard_screen.dart';
import 'package:interviewer/features/dashboard/presentation/screen/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('userBox');

  runApp(
    const ProviderScope(
      child: MyApp(), // Clean root entry point
    ),
  );
}

// Global configuration wrapper for your entire application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: "Interview App",
      home: HomePage(), // Switches screens dynamically underneath the single MaterialApp
    );
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    print('----------');
    print('Current Auth Status: ${authState.status}');
    print('----------');

    // 1. Fixed: Added explicit handling for the initial checking state
    return switch (authState.status) {
      AuthStatus.checking => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(), // Shows while running auth/me
        ),
      ),
      AuthStatus.authenticated => const HomeScreen(),
      AuthStatus.unauthenticated => const LandingPage(),
    };
  }
}

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'lib/assets/images/logo.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 10),
            const Text(
              'Interviewer',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text('A complete JOB application tool'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // 2. Fixed: Context navigation works flawlessly now that nested MaterialApp is removed
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
              child: const Text('Continue...'),
            ),
          ],
        ),
      ),
    );
  }
}
