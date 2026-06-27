import 'package:flutter/material.dart';

import '../../manager/presentation/manager_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy role routing for now: logged-in users land on the manager app.
    return const ManagerScreen();
  }
}
