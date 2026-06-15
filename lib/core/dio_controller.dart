import 'dart:io';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';


final dioProvider = FutureProvider<Dio>((ref) async {
  final dio = Dio(BaseOptions(
    baseUrl: 'http://10.0.2.2:8000/api/',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  final appDocDir = await getApplicationDocumentsDirectory();
  final String dirPath = "${appDocDir.path}/.cookies/";
  await Directory(dirPath).create(recursive: true);
  final persistCookieJar = PersistCookieJar(
    storage: FileStorage(dirPath),
    ignoreExpires: false,
  );
  dio.interceptors.add(CookieManager(persistCookieJar));
  print('💾 Persistent CookieJar linked successfully.');
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) => handler.next(options),
    onError: (DioException e, handler) async {
      if (e.response?.statusCode == 401) {
        print('401 error from dio controller: Cookie missing or expired.');
        if (e.requestOptions.path.contains('auth/refresh')) {
          print('kittlaa mone');
          return handler.next(e);
        }

        try {
          print('🔄 Attempting to refresh session cookies...');
          final refreshDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
          refreshDio.interceptors.add(CookieManager(persistCookieJar));
          final response = await refreshDio.post('auth/refresh');
          print(response);
          if (response.statusCode == 200) {
            print('✅ Session extended successfully. Retrying original request...');
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
            return handler.resolve(retryResponse);
          }
        } catch (refreshError) {
          print(refreshError);
          print('❌ Token refresh failed.');
          print('kittlaa mone');
          return handler.next(e);
        }
      }

      return handler.next(e);
    },
  ));

  return dio;
});

final logoutProvider = AutoDisposeFutureProvider<void>((ref) async {
  final dio = await ref.read(dioProvider.future);
  try {
    final response = await dio.post('auth/logout');
    print('👋 Backend session terminated successfully.');
  } catch (e) {
    print('⚠️ Backend logout request failed: $e');
  } finally {
    final appDocDir = await getApplicationDocumentsDirectory();
    final String dirPath = "${appDocDir.path}/.cookies/";
    final persistCookieJar = PersistCookieJar(storage: FileStorage(dirPath));
    await persistCookieJar.deleteAll();
    print('🧹 Local cookies wiped clean.');
  }
});

