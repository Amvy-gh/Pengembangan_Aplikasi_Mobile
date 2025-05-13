import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HelpCenterScreen extends StatelessWidget {
  final List<FAQItem> _faqList = [
    FAQItem(
      question: 'Bagaimana cara menambah jadwal kuliah?',
      answer: 'Untuk menambah jadwal kuliah:'
          '\n1. Buka menu Jadwal Perkuliahan'
          '\n2. Tekan tombol + di pojok kanan atas'
          '\n3. Isi detail jadwal yang diperlukan'
          '\n4. Tekan tombol Simpan',
    ),
    FAQItem(
      question: 'Bagaimana cara mengimpor jadwal dari file?',
      answer: 'Untuk mengimpor jadwal:'
          '\n1. Buka menu Jadwal Perkuliahan'
          '\n2. Scroll ke bagian "Import Jadwal"'
          '\n3. Tekan tombol "Pilih File"'
          '\n4. Pilih file PDF atau Excel yang berisi jadwal'
          '\n5. Sistem akan otomatis mengimpor jadwal',
    ),
    FAQItem(
      question: 'Apakah saya akan mendapat notifikasi pengingat?',
      answer: 'Ya, Anda akan mendapat notifikasi pengingat sesuai pengaturan di menu Notifikasi. '
          'Anda dapat mengatur waktu pengingat dan jenis notifikasi yang ingin diterima.',
    ),
    FAQItem(
      question: 'Bagaimana cara mengubah bahasa aplikasi?',
      answer: 'Untuk mengubah bahasa:'
          '\n1. Buka menu Pengaturan'
          '\n2. Pilih opsi Bahasa'
          '\n3. Pilih bahasa yang diinginkan (Indonesia/English)',
    ),
    FAQItem(
      question: 'Bagaimana cara mengganti password?',
      answer: 'Untuk mengganti password:'
          '\n1. Buka menu Pengaturan'
          '\n2. Pilih opsi Ganti Password'
          '\n3. Masukkan password lama'
          '\n4. Masukkan dan konfirmasi password baru'
          '\n5. Tekan tombol Simpan',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pusat Bantuan'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
              child: Column(
                children: [
                  Text(
                    'Ada yang bisa kami bantu?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Temukan jawaban untuk pertanyaan umum di bawah ini',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            ExpansionPanelList.radio(
              children: _faqList
                  .map((faq) => ExpansionPanelRadio(
                        value: faq.question,
                        headerBuilder: (context, isExpanded) => ListTile(
                          title: Text(
                            faq.question,
                            style: TextStyle(
                              fontWeight: isExpanded ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        body: Padding(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Text(
                            faq.answer,
                            style: TextStyle(
                              height: 1.5,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Masih butuh bantuan?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Hubungi kami di support@edutime.com',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({
    required this.question,
    required this.answer,
  });
}
