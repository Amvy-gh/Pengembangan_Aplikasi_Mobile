import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive layout
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Top blue section with half-oval bottom
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.55, // 55% of screen height
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFF3B6AA0),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(screenWidth * 0.5),
                  bottomRight: Radius.circular(screenWidth * 0.5),
                ),
              ),
            ),
          ),
          
          // Content
          SingleChildScrollView(
            child: Column(
              children: [
                // Top section content
                SizedBox(height: screenHeight * 0.1), // Spacing from top
                Text(
                  'EduTime',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFFD95A),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Aplikasi Pengatur Jadwal',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 40),
                Container(
                  width: 150,
                  height: 150,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: screenHeight * 0.08), // Space before white content
                
                // Bottom white section - full width
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        'Selamat Datang ke Atur Jadwal',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3B6AA0),
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Atur Jadwal dan kegiatan kerja kelompokmu otomatis sekarang Juga! minimalisir kegiatan yang kurang penting',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 40),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: ElevatedButton(
                          onPressed: () => context.go('/auth'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF3B6AA0),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            textStyle: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: Text('Mulai Sekarang'),
                        ),
                      ),
                      SizedBox(height: 24), // Bottom padding
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
