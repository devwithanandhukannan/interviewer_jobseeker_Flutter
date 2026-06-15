import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interviewer/features/settings/presentations/controller/spotJob_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    // Watch the live state indices from your provider
    final spotJobState = ref.watch(spotJobProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Spot JOB',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          spotJobState.is_toggled.when(
            // Data received successfully: render the functional interactive toggle switch
            data: (bool isToggled) => CupertinoSwitch(
              value: isToggled,
              activeColor: const Color(0xFF007AFF), // Apple Blue
              trackColor: const Color(0xFFE5E5EA),  // Off state gray
              onChanged: (bool value) async {
                // Instantly trigger mutation flow on backend schema
                await ref.read(spotJobProvider.notifier).spotJobStatusUpdate(value);
              },
            ),
            // UI state while performing network transactions
            loading: () => const SizedBox(
              width: 40,
              height: 20,
              child: CupertinoActivityIndicator(radius: 8),
            ),
            // Fallback UI or retry trigger if API context throws an error
            error: (err, stack) => IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20, color: Colors.redAccent),
              onPressed: () {
                ref.read(spotJobProvider.notifier).fetchSpotJobStatus();
              },
            ),
          ),
        ],
      ),
    );
  }
}