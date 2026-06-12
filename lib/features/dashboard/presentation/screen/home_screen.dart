import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interviewer/features/interview/presentation/screen/viewApplication_screen.dart';
import '../../presentation/providers/navigation_provider.dart';
import './job_screen.dart';
import 'package:interviewer/features/profile/presentation/screen/profile_screen.dart';
import './dashboard_screen.dart';
import 'package:interviewer/features/interview/presentation/screen/interview_screen.dart';
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const List<Widget> _pages = [
    DashboardScreen(),
    ViewapplicationScreen(),
    InterviewScreen(),
    ProfileScreen()
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(dashboardIndexProvider);

    // Safely read the current index without crashing if the enum doesn't map to 3
    int safeIndex = 0;
    try {
      safeIndex = currentTab.index;
    } catch (_) {
      // Fallback fallback to profile if index bound gets confused
      safeIndex = 3;
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: IndexedStack(
          index: safeIndex < _pages.length ? safeIndex : 0,
          children: _pages,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Colors.grey.withOpacity(0.2),
                width: 0.5,
              ),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: safeIndex < 4 ? safeIndex : 0,
            onTap: (index) {
              // SAFE CONVERSION: Maps bottom layout indices explicitly to your enum values
              if (index == 0) {
                ref.read(dashboardIndexProvider.notifier).state = DashboardTab.values[0]; // Home
              } else if (index == 1) {
                ref.read(dashboardIndexProvider.notifier).state = DashboardTab.values[1]; // Browse
              } else if (index == 2) {
                ref.read(dashboardIndexProvider.notifier).state = DashboardTab.values[2]; // Applied
              } else if (index == 3) {
                // If your enum doesn't have item 3 yet, fall back to index 2 to prevent crash
                if (DashboardTab.values.length > 3) {
                  ref.read(dashboardIndexProvider.notifier).state = DashboardTab.values[3];
                } else {
                  ref.read(dashboardIndexProvider.notifier).state = DashboardTab.values[2];
                }
              }
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedItemColor: Colors.black,
            unselectedItemColor: const Color(0xFF8E8E93),
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: '.SF Pro Text',
              letterSpacing: -0.2,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              fontFamily: '.SF Pro Text',
              letterSpacing: -0.2,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.space_dashboard_outlined, size: 22),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.space_dashboard, size: 22),
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.search_rounded, size: 22),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.search_rounded, size: 22),
                ),
                label: 'Browse',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.archive_outlined, size: 22),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.archive, size: 22),
                ),
                label: 'Applied',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.person_outline_sharp, size: 22),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.person_sharp, size: 22),
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}