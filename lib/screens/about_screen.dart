import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tentang'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF4A7AB9),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule,
              size: 72,
              color: Color(0xFF4A7AB9),
            ),
            SizedBox(height: 16),
            Text(
              'EduTime',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Versi 1.0.0',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 32),
            _buildInfoSection(
              'Tentang Aplikasi',
              'EduTime adalah aplikasi manajemen jadwal kuliah dan kerja kelompok yang dirancang khusus untuk membantu mahasiswa mengatur waktu mereka dengan lebih efisien.',
            ),
            SizedBox(height: 24),
            _buildInfoSection(
              'Fitur Utama',
              '• Manajemen jadwal kuliah\n'
              '• Pengaturan jadwal kerja kelompok\n'
              '• Pengingat otomatis\n'
              '• Import jadwal dari PDF/Excel\n'
              '• Statistik kehadiran',
            ),
            SizedBox(height: 24),
            _buildInfoSection(
              'Kontak',
              'Email: support@edutime.com\n'
              'Website: www.edutime.com',
            ),
            SizedBox(height: 24),
            _buildInfoSection(
              'Hak Cipta',
              '© 2025 EduTime. Seluruh hak cipta dilindungi.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
