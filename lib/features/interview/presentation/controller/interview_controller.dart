import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interviewer/core/dio_controller.dart';

class InterviewState {
  final AsyncValue<dynamic> interviewData;
  final bool isSubmitting;

  // Assigned default false fallback assignment strictly to prevent null-leak evaluation
  const InterviewState({
    required this.interviewData,
    this.isSubmitting = false,
  });

  InterviewState copyWith({
    AsyncValue<dynamic>? interviewData,
    bool? isSubmitting,
  }) {
    return InterviewState(
      interviewData: interviewData ?? this.interviewData,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}
class InterviewController extends StateNotifier<InterviewState> {
  final Ref _ref;

  InterviewController(this._ref) : super(const InterviewState(interviewData: AsyncValue.loading())) {
    fetchData();
  }

  Future<Dio> _getDio() async {
    return await _ref.read(dioProvider.future);
  }

  Future<void> fetchData() async {
    try {
      final dio = await _getDio();
      final response = await dio.get('jobseeker/interviews');

      if (mounted) {
        state = state.copyWith(
          interviewData: AsyncValue.data(response.data),
          isSubmitting: false,
        );
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = state.copyWith(
          interviewData: AsyncValue.error(error, stackTrace),
          isSubmitting: false,
        );
      }
    }
  }

  /// POST: /jobseeker/interviews/:id/confirm
  Future<bool> confirmInterview(String interviewId) async {
    print(interviewId.toString());
    try {
      state = state.copyWith(isSubmitting: true);
      final dio = await _getDio();

      final response = await dio.post('jobseeker/interviews/$interviewId/confirm');

      if (response.data['success'] == true) {
        await fetchData(); // Force synchronization layout update
        return true;
      }
      state = state.copyWith(isSubmitting: false);
      return false;
    } catch (e) {
      state = state.copyWith(isSubmitting: false);
      return false;
    }
  }

  /// POST: /jobseeker/interviews/:id/reschedule
  Future<bool> requestReschedule({
    required String interviewId,
    required DateTime proposedTime,
    String? note,
  }) async {
    print(interviewId.toString());
    print(proposedTime.toString());
    print(note.toString());
    try {
      state = state.copyWith(isSubmitting: true);
      final dio = await _getDio();

      final response = await dio.post(
        'jobseeker/interviews/$interviewId/reschedule',
        data: {
          'proposedTime': proposedTime.toIso8601String(),
          'candidateNote': note ?? '',
        },
      );

      if (response.data['success'] == true) {
        await fetchData();
        return true;
      }
      state = state.copyWith(isSubmitting: false);
      return false;
    } catch (e) {
      state = state.copyWith(isSubmitting: false);
      return false;
    }
  }
}

final interviewControllerProvider = StateNotifierProvider<InterviewController, InterviewState>((ref) {
  return InterviewController(ref);
});