import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interviewer/features/auth/presentation/controllers/auth_controller.dart';

class DashboardScreen extends ConsumerWidget{
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final JobState = ref.watch(authControllerProvider);
    print(JobState);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Home screen')
          ],
        ),
      ),
    );
  }
}