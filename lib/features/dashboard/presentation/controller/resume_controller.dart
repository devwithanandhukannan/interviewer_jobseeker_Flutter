import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interviewer/core/dio_controller.dart';

class ResumeState {
  final AsyncValue<dynamic> resumeData;

  const ResumeState({required this.resumeData});

  ResumeState copyWith({
    AsyncValue<dynamic>? resumeData,
  }) {
    return ResumeState(
      resumeData: resumeData ?? this.resumeData,
    );
  }
}

class ResumeController extends StateNotifier<ResumeState> {
  final Ref _ref;

  ResumeController(this._ref) : super(const ResumeState(resumeData: AsyncValue.loading()));

  Future<Dio> _getDio() async {
    return await _ref.read(dioProvider.future);
  }

  Future<void> FetchResumes() async {
    try {
      final _dio = await _getDio();
      final response = await _dio.post('/jobseeker/resumes');
      if (mounted) {
        state = state.copyWith(resumeData: AsyncValue.data(response.data));
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = state.copyWith(resumeData: AsyncValue.error(error, stackTrace));
      }
    }
  }

  Future<void> fetchResumeById(String resumeId) async {
    try {
      print(resumeId);
      state = state.copyWith(resumeData: const AsyncValue.loading());
      final dio = await _getDio();

      // Corresponds directly to route app.use('/api/jobseeker', ...) + /resumes/:id
      final response = await dio.get('jobseeker/resumes/$resumeId');
      print(response);

      if (mounted) {
        state = state.copyWith(resumeData: AsyncValue.data(response.data));
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = state.copyWith(resumeData: AsyncValue.error(error, stackTrace));
      }
    }
  }
}

// Global hook reference token
final resumeControllerProvider = StateNotifierProvider<ResumeController, ResumeState>((ref) {
  return ResumeController(ref);
});