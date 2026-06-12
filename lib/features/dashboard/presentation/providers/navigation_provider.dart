import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DashboardTab { home,Browse, Applied, profile }

final dashboardIndexProvider = StateProvider<DashboardTab>((ref) {
  return DashboardTab.home;
});
