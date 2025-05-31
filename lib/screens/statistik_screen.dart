import 'package:flutter/material.dart';
import '../widgets/main_scaffold.dart';

class StatistikScreen extends StatelessWidget {
  const StatistikScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 2,
      title: 'Statistik',
      body: Center(
        child: Text(
          'Statistik jadwal dan aktivitas kamu akan muncul di sini',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
