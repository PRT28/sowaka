import 'package:flutter/material.dart';

import '../../home/presentation/home_screen.dart';
import '../data/auth_models.dart';
import '../data/auth_api_service.dart';
import '../data/auth_session_store.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<AuthSession?> _session = _restoreSession();

  Future<AuthSession?> _restoreSession() async {
    final store = AuthSessionStore();
    final cached = await store.read();
    if (cached == null) return null;

    try {
      final user = await AuthApiService().fetchCurrentUser(cached.token);
      final refreshed = AuthSession(token: cached.token, user: user);
      await store.save(refreshed);
      return refreshed;
    } on AuthApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await store.clear();
        return null;
      }
      return cached;
    } catch (_) {
      return cached;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthSession?>(
      future: _session,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data;
        return session == null
            ? const LoginScreen()
            : HomeScreen(session: session);
      },
    );
  }
}
