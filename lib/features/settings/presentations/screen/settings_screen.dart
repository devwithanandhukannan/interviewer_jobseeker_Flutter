import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interviewer/core/dio_controller.dart';
import 'package:interviewer/features/auth/presentation/screen/login_screen.dart';
import 'package:interviewer/features/settings/presentations/controller/spotJob_controller.dart';
import 'package:interviewer/features/settings/presentations/screen/resume_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _bg = Color(0xFFFAFAFA);
  static const _surface = Colors.white;
  static const _border = BorderSide(color: Color(0xFFE5E5EA), width: 0.5);
  static const _textPrimary = Color(0xFF000000);
  static const _textSecondary = Color(0xFF6E6E73);
  static const _destructiveRed = Color(0xFFFF3B30);
  Future<void> _handleLogout() async {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CupertinoActivityIndicator(radius: 12),
      ),
    );

    try {
      await ref.read(logoutProvider.future);

      if (mounted) {
        Navigator.pop(context);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to clear session safely. Please try again.'),
            backgroundColor: Colors.black87,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final spotJobState = ref.watch(spotJobProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textPrimary, letterSpacing: -0.4),
        ),
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.fromBorderSide(_border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Spot JOB',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                spotJobState.is_toggled.when(
                  data: (bool isToggled) => CupertinoSwitch(
                    value: isToggled,
                    activeColor: const Color(0xFF007AFF),
                    trackColor: const Color(0xFFE5E5EA),
                    onChanged: (bool value) async {
                      await ref.read(spotJobProvider.notifier).spotJobStatusUpdate(value);
                    },
                  ),
                  loading: () => const SizedBox(
                    width: 40,
                    height: 20,
                    child: CupertinoActivityIndicator(radius: 8),
                  ),
                  error: (err, stack) => IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20, color: Colors.redAccent),
                    onPressed: () {
                      ref.read(spotJobProvider.notifier).fetchSpotJobStatus();
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Row Option 2: Document Index Management Redirection Hook
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ResumeListScreen(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.fromBorderSide(_border),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Manage Resumes',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: _textSecondary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: _handleLogout,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.fromBorderSide(_border),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.logout_rounded,
                    size: 18,
                    color: _destructiveRed,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Log Out',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _destructiveRed,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}