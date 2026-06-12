import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interviewer/features/interview/presentation/screen/viewApplication_screen.dart';
import 'package:interviewer/features/profile/presentation/screen/profile_screen.dart';
import 'package:interviewer/features/interview/presentation/screen/interview_screen.dart';
import '../../presentation/providers/navigation_provider.dart';
import './job_screen.dart';
import './dashboard_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // Order mapped directly to the BottomNavigationBar items below
  static const List<Widget> _pages = [
    DashboardScreen(),           // 0: Home
    ViewapplicationScreen(),     // 1: Applied
    JobListScreen(),             // 2: Browse
    InterviewScreen(),           // 3: Interview
    ProfileScreen(),             // 4: Profile
  ];

  // Securely converts your exact enum state to the UI index integer
  int _getSafeIndex(DashboardTab tab) {
    // Dynamic matching by string name downcase to bypass any case-mismatch compiler blocks
    final String tabName = tab.name.toLowerCase();

    if (tabName == 'home') return 0;
    if (tabName == 'applied') return 1;
    if (tabName == 'browse') return 2;
    if (tabName.contains('interview')) return 3;
    if (tabName == 'profile') return 4;
    return 0; // Default safety net
  }

  // Updates the enum cleanly based on tap index
  DashboardTab _getTabFromIndex(int index) {
    final values = DashboardTab.values;

    switch (index) {
      case 0:
        return values.firstWhere((e) => e.name.toLowerCase() == 'home', orElse: () => values[0]);
      case 1:
        return values.firstWhere((e) => e.name.toLowerCase() == 'applied', orElse: () => values[0]);
      case 2:
        return values.firstWhere((e) => e.name.toLowerCase() == 'browse', orElse: () => values[0]);
      case 3:
        return values.firstWhere((e) => e.name.toLowerCase().contains('interview'), orElse: () => values[0]);
      case 4:
        return values.firstWhere((e) => e.name.toLowerCase() == 'profile', orElse: () => values[0]);
      default:
        return values[0];
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(dashboardIndexProvider);

    // Fallback safe index calculation
    final int currentIndex = _getSafeIndex(currentTab);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: IndexedStack(
          index: currentIndex < _pages.length ? currentIndex : 0,
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
            currentIndex: currentIndex,
            onTap: (index) {
              ref.read(dashboardIndexProvider.notifier).state = _getTabFromIndex(index);
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
                  child: Icon(Icons.assignment_turned_in_outlined, size: 22),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.assignment_turned_in, size: 22),
                ),
                label: 'Applied',
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
                label: 'Interview',
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