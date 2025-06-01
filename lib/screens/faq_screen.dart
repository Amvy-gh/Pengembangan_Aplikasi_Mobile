import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FAQItem {
  final String question;
  final String answer;
  bool isExpanded;

  FAQItem({
    required this.question, 
    required this.answer, 
    this.isExpanded = false
  });
}

class FAQScreen extends StatefulWidget {
  const FAQScreen({Key? key}) : super(key: key);

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final List<FAQItem> _faqList = [
    FAQItem(
      question: 'Bagaimana cara menambahkan jadwal kuliah baru?',
      answer:
          'Untuk menambahkan jadwal kuliah baru:\n'
          '1. Buka tab Jadwal Perkuliahan\n'
          '2. Tap tombol + di pojok kanan bawah\n'
          '3. Isi informasi yang diperlukan (mata kuliah, hari, waktu, ruangan)\n'
          '4. Tap Simpan untuk menyimpan jadwal',
    ),
    FAQItem(
      question: 'Bagaimana cara membuat jadwal kerja kelompok?',
      answer:
          'Untuk membuat jadwal kerja kelompok:\n'
          '1. Buka tab Jadwal Kelompok\n'
          '2. Tap tombol + di pojok kanan bawah\n'
          '3. Pilih mata kuliah dan anggota kelompok\n'
          '4. Tentukan waktu dan tempat pertemuan\n'
          '5. Tap Simpan untuk menyimpan jadwal kelompok',
    ),
    FAQItem(
      question: 'Bagaimana cara mengubah password?',
      answer:
          'Untuk mengubah password:\n'
          '1. Buka menu Pengaturan\n'
          '2. Tap opsi "Ganti Password"\n'
          '3. Masukkan password saat ini\n'
          '4. Masukkan password baru dan konfirmasi\n'
          '5. Tap Simpan untuk mengubah password',
    ),
    FAQItem(
      question: 'Bagaimana cara melihat statistik kehadiran?',
      answer:
          'Untuk melihat statistik kehadiran:\n'
          '1. Buka tab Statistik\n'
          '2. Di sini Anda dapat melihat ringkasan kehadiran untuk semua mata kuliah\n'
          '3. Tap pada mata kuliah tertentu untuk melihat detail kehadiran',
    ),
    FAQItem(
      question: 'Apakah saya bisa mengatur pengingat untuk jadwal?',
      answer:
          'Ya, Anda bisa mengatur pengingat untuk jadwal kuliah dan kelompok:\n'
          '1. Saat membuat atau mengedit jadwal, aktifkan opsi "Pengingat"\n'
          '2. Pilih waktu pengingat (misalnya 15 menit, 30 menit, atau 1 jam sebelum jadwal)\n'
          '3. Sistem akan mengirimkan notifikasi pada waktu yang ditentukan',
    ),
    FAQItem(
      question: 'Bagaimana cara keluar dari aplikasi?',
      answer:
          'Untuk keluar dari aplikasi:\n'
          '1. Buka menu Pengaturan\n'
          '2. Scroll ke bawah dan tap tombol "Keluar"\n'
          '3. Konfirmasi untuk keluar dari akun Anda',
    ),
    FAQItem(
      question: 'Apakah data saya aman?',
      answer:
          'Ya, EduTime mengutamakan keamanan data pengguna:\n'
          '• Data disimpan dengan aman menggunakan Firebase Authentication\n'
          '• Informasi pribadi tidak dibagikan kepada pihak ketiga\n'
          '• Kami menggunakan enkripsi untuk melindungi data sensitif',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF4A7AB9),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pertanyaan yang Sering Ditanyakan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A7AB9),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Temukan jawaban untuk pertanyaan umum tentang aplikasi EduTime',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 24),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _faqList.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: ExpansionTile(
                      initiallyExpanded: _faqList[index].isExpanded,
                      onExpansionChanged: (expanded) {
                        setState(() {
                          _faqList[index].isExpanded = expanded;
                        });
                      },
                      title: Text(
                        _faqList[index].question,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      childrenPadding: EdgeInsets.all(16),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _faqList[index].answer,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 24),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF4A7AB9).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.support_agent,
                      color: Color(0xFF4A7AB9),
                      size: 32,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Masih memiliki pertanyaan?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Hubungi kami di support@edutime.com',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
