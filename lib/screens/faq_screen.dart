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
      question: 'Bagaimana cara melihat jadwal perkuliahan?',
      answer:
          'Untuk melihat jadwal perkuliahan:\n'
          '1. Buka tab "Jadwal Perkuliahan" di menu utama\n'
          '2. Anda akan melihat daftar jadwal kuliah yang telah ditambahkan\n'
          '3. Jadwal dikelompokkan berdasarkan hari untuk memudahkan pencarian',
    ),
    FAQItem(
      question: 'Bagaimana cara melihat jadwal kerja kelompok?',
      answer:
          'Untuk melihat jadwal kerja kelompok:\n'
          '1. Buka tab "Jadwal Kelompok" di menu utama\n'
          '2. Anda akan melihat daftar jadwal kerja kelompok yang telah dibuat\n'
          '3. Jadwal dikelompokkan berdasarkan mata kuliah dan tanggal',
    ),
    FAQItem(
      question: 'Bagaimana cara mengubah password?',
      answer:
          'Untuk mengubah password:\n'
          '1. Buka menu "Pengaturan"\n'
          '2. Tap opsi "Ganti Password"\n'
          '3. Masukkan password saat ini\n'
          '4. Masukkan password baru dan konfirmasi\n'
          '5. Tap "Simpan" untuk mengubah password',
    ),
    FAQItem(
      question: 'Bagaimana cara mengubah informasi profil?',
      answer:
          'Untuk mengubah informasi profil:\n'
          '1. Buka menu "Pengaturan"\n'
          '2. Tap opsi "Edit Profil"\n'
          '3. Ubah informasi yang diinginkan (nama, NIM, program studi)\n'
          '4. Tap tombol "Simpan Perubahan" untuk menyimpan',
    ),
    FAQItem(
      question: 'Bagaimana cara keluar dari aplikasi?',
      answer:
          'Untuk keluar dari aplikasi:\n'
          '1. Buka menu "Pengaturan"\n'
          '2. Scroll ke bawah dan tap tombol "Keluar"\n'
          '3. Konfirmasi untuk keluar dari akun Anda',
    ),
    FAQItem(
      question: 'Apakah data saya aman?',
      answer:
          'Ya, aplikasi ini mengutamakan keamanan data pengguna:\n'
          '• Data disimpan dengan aman menggunakan Firebase Authentication\n'
          '• Informasi pribadi tidak dibagikan kepada pihak ketiga\n'
          '• Kami menggunakan enkripsi untuk melindungi data sensitif',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'FAQ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF4A7AB9),
        elevation: 0,
        shadowColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A7AB9).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.help_outline,
                          color: Color(0xFF4A7AB9),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pertanyaan yang Sering Ditanyakan',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3748),
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Temukan jawaban untuk pertanyaan umum tentang EduTime',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // FAQ List Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _faqList.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ExpansionTile(
                            initiallyExpanded: _faqList[index].isExpanded,
                            onExpansionChanged: (expanded) {
                              setState(() {
                                _faqList[index].isExpanded = expanded;
                              });
                            },
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 20, 
                              vertical: 8,
                            ),
                            childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            expandedCrossAxisAlignment: CrossAxisAlignment.start,
                            iconColor: const Color(0xFF4A7AB9),
                            collapsedIconColor: Colors.grey[600],
                            title: Text(
                              _faqList[index].question,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Color(0xFF2D3748),
                                height: 1.3,
                              ),
                            ),
                            children: [
                              const Divider(
                                height: 20,
                                thickness: 1,
                                color: Color(0xFFE2E8F0),
                              ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4A7AB9).withOpacity(0.03),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF4A7AB9).withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _faqList[index].answer,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.6,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Support Contact Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF4A7AB9),
                          const Color(0xFF4A7AB9).withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4A7AB9).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.support_agent,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Masih ada pertanyaan?',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Kami siap membantu Anda',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'support@edutime.com',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
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
          ],
        ),
      ),
    );
  }
}