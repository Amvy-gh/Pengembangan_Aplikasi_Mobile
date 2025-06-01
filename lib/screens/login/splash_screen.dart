import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // Cek status autentikasi setelah animasi selesai
    Future.delayed(Duration(seconds: 3), () {
      _checkAuthAndNavigate();
    });
  }
  
  // Fungsi untuk memeriksa status autentikasi dan mengarahkan pengguna
  Future<void> _checkAuthAndNavigate() async {
    try {
      // Memuat ulang data pengguna untuk memastikan status terbaru
      await AuthService.reloadUser();
      
      final user = FirebaseAuth.instance.currentUser;
      
      if (mounted) {
        if (user != null) {
          print('User terautentikasi: ${user.email}');
          // Jika sudah login, langsung ke homepage
          context.go('/homepage');
        } else {
          print('Tidak ada user yang login');
          // Jika belum login, ke welcome screen
          context.go('/welcome');
        }
      }
    } catch (e) {
      print('Error saat memeriksa autentikasi: $e');
      // Jika terjadi error, arahkan ke welcome screen
      if (mounted) {
        context.go('/welcome');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo container
                    Container(
                      width: 150,
                      height: 150,
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Color(0xFF4A7AB9).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        'assets/images/logo.png', // Path to your logo image
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'EduTime',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A7AB9),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Atur Waktumu dengan Mudah',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
