import 'package:flutter/material.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'routes/app_routes.dart';

void main() {
  runApp(const HrmsMobileApp());
}

class HrmsMobileApp extends StatelessWidget {
  const HrmsMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFFBE5A36);

    return MaterialApp(
      title: 'Sowaka Connect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Plus Jakarta Sans',
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F2EC),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE7DED5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE7DED5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: seedColor, width: 1.5),
          ),
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
      routes: AppRoutes.routes,
    );
  }
}
