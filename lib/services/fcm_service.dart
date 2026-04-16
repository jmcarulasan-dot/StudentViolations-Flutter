import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Global plugin instance needed for background handler
final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

// ---------------------------------------------------------
// BACKGROUND HANDLER (Fixed: Will show notification when app is killed)
// ---------------------------------------------------------
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await _localNotifications.initialize(initializationSettings);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'violations_channel',
    'Violation Notifications',
    importance: Importance.high,
  );

  await _localNotifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  final notification = message.notification;
  if (notification != null) {
    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'violations_channel',
          'Violation Notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// MAIN SERVICE CLASS
// ---------------------------------------------------------
class FCMService {
  // Make sure this IP matches your backend
  static const String _baseUrl = 'http://192.168.254.148:5277';

  static Future<void> initialize() async {
    // 1. Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. Request permissions
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. Setup local notifications for FOREGROUND
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);

    // 4. Create Channel (Android)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'violations_channel',
      'Violation Notifications',
      description: 'Notifications for student violations',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 5. Listen to messages while app is OPEN (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'violations_channel',
              'Violation Notifications',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });

    // 6. Get and Save Token immediately on startup
    await _saveTokenToBackend();

    // 7. Listen for token refreshes
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await _sendTokenToBackend(newToken);
    });
  }

  static Future<void> _saveTokenToBackend() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      
      // ============================================
      // THIS PRINTS YOUR TOKEN TO THE CONSOLE
      // ============================================
      print("==========================================");
      print("YOUR FCM TOKEN IS: $token");
      print("==========================================");

      if (token != null) {
        await _sendTokenToBackend(token);
      }
    } catch (e) {
      print('FCM token error: $e');
    }
  }

  static Future<void> _sendTokenToBackend(String fcmToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwt_token');
      
      if (jwtToken == null) {
        print("Cannot save token: User not logged in (JWT missing)");
        return; 
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/notifications/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({'fcmToken': fcmToken}),
      );

      if (response.statusCode == 200) {
        print("Token saved to backend successfully!");
      } else {
        print("Failed to save token. Status: ${response.statusCode}");
      }
    } catch (e) {
      print('Failed to send FCM token to backend: $e');
    }
  }

  // Call this after login if you want to be extra sure the token is sent
  static Future<void> registerTokenAfterLogin() async {
    await _saveTokenToBackend();
  }
}