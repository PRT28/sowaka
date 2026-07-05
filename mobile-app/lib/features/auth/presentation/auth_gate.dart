import 'package:flutter/material.dart';

import '../../home/presentation/home_screen.dart';
import '../data/auth_models.dart';
import '../data/auth_session_store.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<AuthSession?> _session = AuthSessionStore().read();

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
