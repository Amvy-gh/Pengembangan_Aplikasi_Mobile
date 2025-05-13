import 'package:flutter/material.dart';
import 'routes/app_router.dart';

void main() {
  runApp(EduTimeApp());
}

class EduTimeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EduTime',
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: Colors.green,
        fontFamily: 'Roboto',
        useMaterial3: true,
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.green,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      routerConfig: AppRouter.router,
    );
  }
}
