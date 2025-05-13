import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 80, color: Colors.green),
            SizedBox(height: 24),
            Text("Selamat Datang di EduTime",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text(
              "Asisten pintar untuk mengatur jadwal kuliah dan kerja kelompokmu.",
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),            ElevatedButton(
              onPressed: () => context.go('/auth'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16)),
              child: Text(
                "Mulai Sekarang",
                style: TextStyle(
                  color: Colors.white, // Mengubah warna text
                  fontSize: 16, // Menambah ukuran font
                  fontWeight: FontWeight.bold, // Membuat text bold
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
