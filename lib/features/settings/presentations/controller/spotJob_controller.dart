import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interviewer/core/dio_controller.dart';

class SpotJobState {
  final AsyncValue<bool> is_toggled;
  final AsyncValue<List<dynamic>> invitations; // For viewing all spot jobs invitations

  const SpotJobState({
    required this.is_toggled,
    required this.invitations,
  });

  SpotJobState copyWith({
    AsyncValue<bool>? is_toggled,
    AsyncValue<List<dynamic>>? invitations,
  }) {
    return SpotJobState(
      is_toggled: is_toggled ?? this.is_toggled,
      invitations: invitations ?? this.invitations,
    );
  }
}

class SpotJobController extends StateNotifier<SpotJobState> {
  final Ref _ref;

  SpotJobController(this._ref)
      : super(const SpotJobState(
    is_toggled: AsyncValue.loading(),
    invitations: AsyncValue.loading(),
  )) {
    // Automatically fetch state data on creation
    fetchSpotJobStatus();
    fetchJobSeekerInvitations();
  }

  Future<Dio> _getDio() async {
    return await _ref.read(dioProvider.future);
  }

  /// 1. Query database to fetch the initial switch state matching backend logic
  Future<void> fetchSpotJobStatus() async {
    try {
      state = state.copyWith(is_toggled: const AsyncValue.loading());
      final dio = await _getDio();

      // Matches: router.get('/spot-jobs/toggle-status', ...)
      final response = await dio.get('jobseeker/spot-jobs/toggle-status');

      if (response.data != null && response.data['success'] == true) {
        final bool isEnabled = response.data['isSpotJobEnabled'] ?? false;
        state = state.copyWith(is_toggled: AsyncValue.data(isEnabled));
      } else {
        state = state.copyWith(is_toggled: const AsyncValue.data(false));
      }
    } catch (error, stackTrace) {
      state = state.copyWith(is_toggled: AsyncValue.error(error, stackTrace));
    }
  }

  /// 2. Mutates the status in the database depending on the switch value
  Future<void> spotJobStatusUpdate(bool targetValue) async {
    try {
      final dio = await _getDio();

      // Matches: router.patch('/spot-jobs/toggle-status', ...)
      final response = await dio.patch(
        'jobseeker/spot-jobs/toggle-status',
        data: {'enabled': targetValue},
      );

      if (response.data != null && response.data['success'] == true) {
        final bool isEnabled = response.data['isSpotJobEnabled'] ?? targetValue;
        state = state.copyWith(is_toggled: AsyncValue.data(isEnabled));
      }
    } catch (error, stackTrace) {
      state = state.copyWith(is_toggled: AsyncValue.error(error, stackTrace));
    }
  }

  /// 3. View all received spot job invitations / other user status notifications
  Future<void> fetchJobSeekerInvitations() async {
    try {
      state = state.copyWith(invitations: const AsyncValue.loading());
      final dio = await _getDio();

      // Matches: router.get('/spot-jobs/invitations', ...)
      final response = await dio.get('jobseeker/spot-jobs/invitations');

      if (response.data != null && response.data['success'] == true) {
        final List<dynamic> list = response.data['data'] ?? [];
        state = state.copyWith(invitations: AsyncValue.data(list));
      } else {
        state = state.copyWith(invitations: const AsyncValue.data([]));
      }
    } catch (error, stackTrace) {
      state = state.copyWith(invitations: AsyncValue.error(error, stackTrace));
    }
  }

  /// 4. Respond to a pending spot job invitation booking (ACCEPT / DECLINE)
  Future<bool> respondToInvitation(String bookingId, String action) async {
    try {
      final dio = await _getDio();

      // Matches: router.patch('/spot-jobs/respond/:bookingId', ...)
      final response = await dio.patch(
        'jobseeker/spot-jobs/respond/$bookingId',
        data: {'action': action}, // action expected as 'ACCEPT' or 'DECLINE'
      );

      if (response.data != null && response.data['success'] == true) {
        fetchJobSeekerInvitations(); // Refresh invitations view layout pool context
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 5. Sends the device token to the server to get push notifications
  Future<void> sendNotificationToken(String token) async {
    try {
      final dio = await _getDio();

      // Matches exactly: router.post('/notification/token', saveNotificationToken);
      await dio.post(
        'jobseeker/notification/token',
        data: {'token': token},
      );
    } catch (error) {
      // Quietly log token synchronization registration errors
      print("Error synchronizing device registration notification token: $error");
    }
  }
}

// Global provider declaration
final spotJobProvider = StateNotifierProvider<SpotJobController, SpotJobState>((ref) {
  return SpotJobController(ref);
});