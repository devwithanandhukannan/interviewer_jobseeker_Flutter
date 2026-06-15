import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interviewer/core/dio_controller.dart';
import 'package:interviewer/core/notification_service.dart';

enum AuthStatus { checking, authenticated, fillInitalData, unauthenticated }

class AuthState {
  final String message;
  final String phoneNumber;
  final bool isLoading;
  final AuthStatus status;

  const AuthState({
    this.phoneNumber = '',
    this.isLoading = false,
    this.status = AuthStatus.checking,
    this.message = 'Enter phoneNumber',
  });

  AuthState copyWith({
    String? message,
    String? phoneNumber,
    bool? isLoading,
    AuthStatus? status,
  }) {
    return AuthState(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isLoading: isLoading ?? this.isLoading,
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthController(this._ref) : super(const AuthState()) {
    checkCurrentUserSession();
  }

  Future<Dio> _getDio() async {
    return await _ref.read(dioProvider.future);
  }

  Future<void> checkCurrentUserSession() async {
    try {
      print('Checking authentication status...');
      final dio = await _getDio();

      final response = await dio.get('auth/me');
      print('Status code received: ${response.statusCode}');

      if (response.statusCode == 200) {
        state = state.copyWith(status: AuthStatus.authenticated);

        // Synchronize notification token on valid persistent session auto-login
        _ref.read(notificationServiceProvider).syncTokenWithBackend();
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } on DioException catch (e) {
      print('Dio caught session check exception: ${e.message}');
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } catch (e) {
      print('Unknown session check exception: $e');
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> sentMobileNumber(String phonenumber) async {
    state = state.copyWith(isLoading: true, message: "Sending request...", phoneNumber: phonenumber);
    try {
      final dio = await _getDio();
      final response = await dio.post(
        'auth/send-otp',
        data: {'mobileNumber': phonenumber},
      );
      state = state.copyWith(isLoading: false, message: 'OTP Sent successfully.');
      return response.statusCode == 200;
    } catch (error) {
      state = state.copyWith(isLoading: false, message: 'Failed to send phone number');
      return false;
    }
  }

  Future<bool> verifyOTP(String otp) async {
    state = state.copyWith(isLoading: true, message: 'Verifying OTP...');
    try {
      final dio = await _getDio();
      final response = await dio.post(
        'auth/verify-otp',
        data: {'mobileNumber': state.phoneNumber, 'otp': otp},
      );

      final userData = response.data['user'];
      if (response.statusCode == 200 && userData != null) {
        final bool hasEmail = userData['hasEmail'] ?? false;
        final bool hasFullName = userData['hasFullName'] ?? false;

        print('Has Email: $hasEmail');
        print('Has Full Name: $hasFullName');

        // Redirect to initial data setup workflow if parameters are missing
        if (!hasEmail || !hasFullName) {
          state = state.copyWith(
            isLoading: false,
            status: AuthStatus.fillInitalData,
            message: 'Please complete your registration profile.',
          );
          return true;
        }

        state = state.copyWith(
          isLoading: false,
          status: AuthStatus.authenticated,
          message: 'Login complete',
        );

        // Synchronize notification token on successful OTP verification (If already profile-complete)
        _ref.read(notificationServiceProvider).syncTokenWithBackend();
        return true;
      }
      state = state.copyWith(isLoading: false, message: 'Invalid OTP code.');
      return false;
    } catch (error) {
      state = state.copyWith(isLoading: false, message: 'Failed to verify OTP');
      return false;
    }
  }

  Future<String?> saveInitialProfile({required String email, required String fullName}) async {
    state = state.copyWith(isLoading: true, message: 'Saving profile...');
    try {
      final dio = await _getDio();
      final response = await dio.put(
        'jobseeker/profile',
        data: {
          'profileData': '{"email":"$email","fullName":"$fullName"}',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        state = state.copyWith(
          isLoading: false,
          status: AuthStatus.authenticated,
          message: 'Profile updated successfully',
        );

        // Synchronize notification token immediately following registration update
        _ref.read(notificationServiceProvider).syncTokenWithBackend();
        return null;
      }

      state = state.copyWith(isLoading: false, message: 'Failed to update profile.');
      return 'Failed to update profile.';
    } on DioException catch (e) {
      print('Dio Exception caught: ${e.response?.data}');

      // Extract precise validation message ("email already existed") sent back from backend API
      final backendMessage = e.response?.data?['message'] ?? e.response?.data?['error'];
      final errorMessage = backendMessage?.toString() ?? 'Error updating profile details.';

      state = state.copyWith(isLoading: false, message: errorMessage);
      return errorMessage;
    } catch (e) {
      print('Exception saving profile sequence: $e');
      state = state.copyWith(isLoading: false, message: 'Error updating profile details.');
      return 'Error updating profile details.';
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});