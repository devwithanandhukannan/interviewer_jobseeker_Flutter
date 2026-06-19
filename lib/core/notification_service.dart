import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interviewer/core/dio_controller.dart';

// 1. Declare the global key here so any file can access it by importing this service
final GlobalKey<ScaffoldMessengerState> notificationScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});

class NotificationService {
  final Ref _ref;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  NotificationService(this._ref);

  /// Initializes notification permissions and sets up lifecycle listeners
  Future<void> initializeNotificationPipeline() async {
    // 1. Request OS permission (Crucial for iOS & Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permissions.');
    }

    // 2. Handle foreground messages when application is open
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground notification message: ${message.notification?.title}');

      final String? title = message.notification?.title;
      final String? body = message.notification?.body;

      if (title != null) {
        _showForegroundBanner(title, body);
      }
    });

    // 3. Monitor token refreshes automatically over time
    _fcm.onTokenRefresh.listen((newToken) async {
      print('FCM Token refreshed naturally: $newToken');
      await syncTokenWithBackend(newToken);
    });
  }

  /// Displays an elegant minimal snackbar on top of the current screen context
  void _showForegroundBanner(String title, String? body) {
    // Uses the self-contained key safely
    notificationScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    notificationScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        backgroundColor: const Color(0xFF1A1A1A),
        duration: const Duration(seconds: 4),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2.0, right: 10.0),
              child: Icon(Icons.notifications_active, color: Colors.white, size: 20),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.0,
                      color: Colors.white,
                    ),
                  ),
                  if (body != null) ...[
                    const SizedBox(height: 2.0),
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 12.0,
                        color: Colors.grey.shade300,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sends the FCM device token to the POST /notification/token endpoint
  Future<void> syncTokenWithBackend([String? explicitToken]) async {
    try {
      final token = explicitToken ?? await _fcm.getToken();
      if (token == null) {
        print('FCM token generation yielded null value.');
        return;
      }

      print('Syncing FCM device token with backend: $token');
      final dio = await _ref.read(dioProvider.future);

      final response = await dio.post(
        'jobseeker/notification/token',
        data: {'token': token},
      );

      if (response.statusCode == 200) {
        print('Backend synchronized FCM registration successfully.');
      }
    } on DioException catch (e) {
      print('Dio failed to synchronize notification config: ${e.message}');
    } catch (e) {
      print('Unhandled exception during token upload sequence: $e');
    }
  }
}