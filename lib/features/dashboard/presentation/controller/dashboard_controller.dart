import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interviewer/core/dio_controller.dart';

// 1. Repository Provider now explicitly returns a nullable DashboardRepository?
final dashboardRepositoryProvider = Provider<DashboardRepository?>((ref) {
  final dioAsync = ref.watch(dioProvider);

  return dioAsync.when(
    data: (dioInstance) => DashboardRepository(dioInstance),
    loading: () => null,
    error: (_, __) => null,
  );
});

class DashboardRepository {
  final Dio _dio;

  DashboardRepository(this._dio);

  Future<Map<String, dynamic>> getJobSeekerDashboard() async {
    try {
      final response = await _dio.get('jobseeker/dashboard');

      if (response.data != null && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }

      throw Exception(response.data['message'] ?? 'Failed to parse dashboard payload validation tokens.');
    } on DioException catch (dioError) {
      final errorMessage = dioError.response?.data?['message'] ?? dioError.message ?? 'Network transport failure';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Fatal serialization error: $e');
    }
  }
}

class DashboardState {
  final bool isLoading;
  final Map<String, dynamic>? dashboardData;
  final String errorMessage;

  DashboardState({
    this.isLoading = true,
    this.dashboardData,
    this.errorMessage = '',
  });

  DashboardState copyWith({
    bool? isLoading,
    Map<String, dynamic>? dashboardData,
    String? errorMessage,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      dashboardData: dashboardData ?? this.dashboardData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardRepository? _repository;

  // 2. Accept nullable repository and conditionally kick-off loading operations
  DashboardNotifier(this._repository) : super(DashboardState(isLoading: true)) {
    if (_repository != null) {
      fetchDashboardPayload();
    } else {
      // Hold state in a silent loading block until Dio registers data
      state = state.copyWith(isLoading: true, errorMessage: '');
    }
  }

  Future<void> fetchDashboardPayload() async {
    if (_repository == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Network client context initialization pending.',
      );
      return;
    }

    try {
      state = state.copyWith(isLoading: true, errorMessage: '');

      final realData = await _repository!.getJobSeekerDashboard();

      state = state.copyWith(
        isLoading: false,
        dashboardData: realData,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

final dashboardControllerProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final repo = ref.watch(dashboardRepositoryProvider);
  return DashboardNotifier(repo);
});