import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interviewer/features/auth/data/models/user_model.dart';
import 'package:hive_flutter/hive_flutter.dart';
// Make sure this points to your updated file with the FutureProvider
import 'package:interviewer/core/dio_controller.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

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

  /// Helper method to safely retrieve the Dio instance from the FutureProvider
  Future<Dio> _getDio() async {
    // dioProvider is now a FutureProvider, so we use future to wait for its initialization
    return await _ref.read(dioProvider.future);
  }

  Future<void> checkCurrentUserSession() async {
    try {
      print('Checking authentication status...');
      final dio = await _getDio();

      final response = await dio.get('auth/me'); // baseUrl already set in Dio
      print('Status code received: ${response.statusCode}');

      if (response.statusCode == 200) {
        state = state.copyWith(status: AuthStatus.authenticated);
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
      if (response.statusCode == 200 && response.data != null) {
        final user = UserModel.fromJson(response.data as Map<String, dynamic>);
        final box = Hive.box('userBox');
        await box.put('fullName', user.fullName);
        await box.put('phoneNumber', user.phoneNumber);
        await box.put('email', user.email);
        state = state.copyWith(
          isLoading: false,
          status: AuthStatus.authenticated,
          message: 'Login complete',
        );
        return true;
      }
      state = state.copyWith(isLoading: false, message: 'Invalid OTP code.');
      return false;
    } catch (error) {
      state = state.copyWith(isLoading: false, message: 'Failed to verify OTP');
      return false;
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});