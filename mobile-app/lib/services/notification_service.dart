import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../features/auth/data/auth_models.dart';
import '../firebase_options.dart';
import 'api_config.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class AppNotificationService {
  AppNotificationService._();
  static final instance = AppNotificationService._();

  final _opened = StreamController<Map<String, dynamic>>.broadcast();
  final _local = FlutterLocalNotificationsPlugin();
  Stream<Map<String, dynamic>> get opened => _opened.stream;
  Map<String, dynamic>? pendingDestination;
  AuthSession? _session;

  Future<void> initialize() async {
    try {
      await _initializeFirebase();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      if (!kIsWeb) await _initializeLocalNotifications();
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      FirebaseMessaging.onMessage.listen(_showForeground);
      FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => _emit(message.data),
      );
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        pendingDestination = Map<String, dynamic>.from(initial.data);
      }
      FirebaseMessaging.instance.onTokenRefresh.listen(
        (token) => _register(token),
      );
    } catch (_) {
      // Firebase native configuration may not be installed in local builds yet.
    }
  }

  Future<void> _initializeLocalNotifications() async {
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          _emit(jsonDecode(response.payload!) as Map<String, dynamic>);
        }
      },
    );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'sowaka_notifications',
            'Sowaka notifications',
            description: 'Company activity, approvals and reminders',
            importance: Importance.high,
          ),
        );
  }

  Future<void> _initializeFirebase() async {
    if (Firebase.apps.isNotEmpty) return;
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  Future<void> attachSession(AuthSession session) async {
    _session = session;
    try {
      const webVapidKey = String.fromEnvironment(
        'FIREBASE_WEB_VAPID_KEY',
        defaultValue:
            'BHqyJO-motjY5x1ouLWFjMGNdLp-nLTQRNUPa0XynKJxQ_XpMUla_IcUE9qeqNdPwCoOjwYj88Ag1ebVmwfWRvM',
      );
      final token = await FirebaseMessaging.instance.getToken(
        vapidKey: kIsWeb && webVapidKey.isNotEmpty ? webVapidKey : null,
      );
      if (token != null) await _register(token);
    } catch (_) {}
  }

  void consumePending() {
    final pending = pendingDestination;
    pendingDestination = null;
    if (pending != null) _opened.add(pending);
  }

  void openDestination(Map<String, dynamic> data) => _emit(data);

  void _emit(Map<String, dynamic> data) {
    pendingDestination = Map<String, dynamic>.from(data);
    _opened.add(Map<String, dynamic>.from(data));
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    if (kIsWeb) return;
    await _local.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'sowaka_notifications',
          'Sowaka notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  Future<void> _register(String token) async {
    final session = _session;
    if (session == null) return;
    await http.post(
      Uri.parse('${ApiConfig.baseUrl}/notifications/devices'),
      headers: {
        'Authorization': 'Bearer ${session.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'token': token,
        'platform': kIsWeb
            ? 'web'
            : defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android',
      }),
    );
  }
}
