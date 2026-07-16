import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../services/api_config.dart';
import '../../../services/notification_service.dart';
import '../../auth/data/auth_models.dart';

class NotificationInboxScreen extends StatefulWidget {
  const NotificationInboxScreen({super.key, required this.session});
  final AuthSession session;
  @override
  State<NotificationInboxScreen> createState() =>
      _NotificationInboxScreenState();
}

class _NotificationInboxScreenState extends State<NotificationInboxScreen> {
  late final Future<List<Map<String, dynamic>>> _items = _load();
  Map<String, String> get headers => {
    'Authorization': 'Bearer ${widget.session.token}',
    'Content-Type': 'application/json',
  };
  Future<List<Map<String, dynamic>>> _load() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/notifications'),
      headers: headers,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Could not load notifications');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return (json['notifications'] as List<dynamic>? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> _open(Map<String, dynamic> item) async {
    await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/notifications/${item['id']}/read'),
      headers: headers,
    );
    if (!mounted) return;
    Navigator.pop(context);
    AppNotificationService.instance.openDestination(
      Map<String, dynamic>.from(item['data'] as Map? ?? const {}),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notifications')),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _items,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data!;
        if (items.isEmpty) {
          return const Center(child: Text('No notifications yet'));
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, index) {
            final item = items[index];
            final unread = item['readAt'] == null;
            return ListTile(
              onTap: () => _open(item),
              leading: CircleAvatar(
                backgroundColor: unread
                    ? const Color(0xFFF6E5DB)
                    : const Color(0xFFF1EEE9),
                child: const Icon(Icons.notifications_rounded),
              ),
              title: Text(
                '${item['title']}',
                style: TextStyle(
                  fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
              subtitle: Text('${item['body']}'),
              trailing: unread
                  ? const Icon(Icons.circle, size: 9, color: Color(0xFFBE5A36))
                  : null,
            );
          },
        );
      },
    ),
  );
}
