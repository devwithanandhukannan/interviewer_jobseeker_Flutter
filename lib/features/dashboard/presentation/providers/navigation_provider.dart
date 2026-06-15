import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DashboardTab { home, applied, browse, interview, profile }

final dashboardIndexProvider = StateProvider<DashboardTab>((ref) {
  return DashboardTab.home;
});