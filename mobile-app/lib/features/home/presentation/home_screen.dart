import 'package:flutter/material.dart';

import '../../auth/data/auth_models.dart';
import '../../auth/presentation/login_screen.dart';
import '../../manager/presentation/manager_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.session});

  final AuthSession? session;

  @override
  Widget build(BuildContext context) {
    final activeSession = session ?? ModalRoute.of(context)?.settings.arguments;
    if (activeSession is! AuthSession) return const LoginScreen();
    return ManagerScreen(session: activeSession);
  }
}
