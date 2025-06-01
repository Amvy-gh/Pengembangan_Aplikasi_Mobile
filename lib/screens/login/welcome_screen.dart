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
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Top blue section with half-oval bottom
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: screenHeight * 0.55, // Reduced to 50% of screen height
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF3B6AA0),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(screenWidth * 0.5),
                    bottomRight: Radius.circular(screenWidth * 0.5),
                  ),
                ),
              ),
            ),
            
            // Content
            SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenHeight,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top section content
                    Column(
                      children: [
                        SizedBox(height: screenHeight * 0.2), // Reduced spacing from top
                        Text(
                          'EduTime',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFFD95A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Aplikasi Pengatur Jadwal',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20), // Reduced spacing
                        SizedBox(
                          width: 120, // Reduced size
                          height: 120, // Reduced size
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                    
                    // Bottom white section - full width
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                      child: Column(
                        children: [
                          Text(
                            'Selamat Datang ke Atur Jadwal',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 22, // Slightly smaller
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF3B6AA0),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Atur Jadwal dan kegiatan kerja kelompokmu otomatis sekarang Juga! minimalisir kegiatan yang kurang penting',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 30), // Reduced spacing
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => context.go('/auth'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B6AA0),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 2,
                                textStyle: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: const Text('Mulai Sekarang'),
                            ),
                          ),
                          const SizedBox(height: 20), // Bottom padding
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
