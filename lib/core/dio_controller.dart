import 'dart:io';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

// FutureProvider ensures the storage path is initialized before Dio is used
final dioProvider = FutureProvider<Dio>((ref) async {
  final dio = Dio(BaseOptions(
    baseUrl: 'http://10.0.2.2:8000/api/',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  // 1. Setup Persistent Cookie Storage
  final appDocDir = await getApplicationDocumentsDirectory();
  final String dirPath = "${appDocDir.path}/.cookies/";

  // Create directory if it doesn't exist
  await Directory(dirPath).create(recursive: true);

  final persistCookieJar = PersistCookieJar(
    storage: FileStorage(dirPath),
    ignoreExpires: false, // Respect cookie expiration times
  );

  // Add Cookie Manager Interceptor
  dio.interceptors.add(CookieManager(persistCookieJar));
  print('💾 Persistent CookieJar linked successfully.');

  // 2. Refresh Token & Retry Interceptor
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) => handler.next(options),
    onError: (DioException e, handler) async {
      // Check if unauthorized (401)
      if (e.response?.statusCode == 401) {
        print('401 error from dio controller: Cookie missing or expired.');

        // Avoid infinite loops if the refresh request itself fails with 401
        if (e.requestOptions.path.contains('auth/refresh')) {
          print('kittlaa mone'); // Triggered if even refresh token failed
          return handler.next(e);
        }

        try {
          print('🔄 Attempting to refresh session cookies...');

          // Create an isolated Dio instance for the refresh call
          // to avoid circular dependency loops with the interceptor.
          final refreshDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
          refreshDio.interceptors.add(CookieManager(persistCookieJar));

          // Call your Express backend refresh endpoint
          // Cookies (refreshToken) are attached automatically by the cookie manager
          final response = await refreshDio.get('auth/refresh');
          print(response);
          if (response.statusCode == 200) {
            print('✅ Session extended successfully. Retrying original request...');

            // Re-execute the original locked request with updated cookies
            final opts = e.requestOptions;
            final retryResponse = await dio.request(
              opts.path,
              data: opts.data,
              queryParameters: opts.queryParameters,
              options: Options(
                method: opts.method,
                headers: opts.headers,
              ),
            );

            // Return the successful retried response back to the application pipeline
            return handler.resolve(retryResponse);
          }
        } catch (refreshError) {
          print('❌ Token refresh failed.');
          print('kittlaa mone'); // Printed if refresh fails/network issues during refresh
          return handler.next(e);
        }
      }

      return handler.next(e);
    },
  ));

  return dio;
});