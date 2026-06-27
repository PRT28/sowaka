import 'package:flutter/material.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/home/presentation/home_screen.dart';

class AppRoutes {
  static const login = '/login';
  static const home = '/home';

  static Map<String, WidgetBuilder> get routes {
    return {login: (_) => const LoginScreen(), home: (_) => const HomeScreen()};
  }
}
