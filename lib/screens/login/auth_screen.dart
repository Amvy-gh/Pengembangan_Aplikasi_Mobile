import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/database_helper.dart';
import '../../models/user_profile.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool isLoading = false;
  bool obscurePassword = true;
  String? errorMessage;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _nimController = TextEditingController(); // Tambahan untuk NIM
  final _prodiController = TextEditingController(); // Tambahan untuk Prodi
  
  // Firebase instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    if (!value.contains('@')) {
      return 'Email tidak valid';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  String? _validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    return null;
  }

  Future<void> _submitForm() async {
    // Clear any previous error messages
    setState(() {
      errorMessage = null;
    });
    
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      
      try {
        if (isLogin) {
          // Handle Login
          UserCredential userCredential = await _auth.signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
          
          // Navigate to homepage if auth is successful
          if (mounted) {
            context.go('/homepage');
          }
        } else {
          // Handle Registration
          UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
          
          // Update display name
          await userCredential.user!.updateDisplayName(_nameController.text.trim());
          
          // Save user profile to SQLite
          final newProfile = UserProfile(
            uid: userCredential.user!.uid,
            displayName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            studentId: _nimController.text.trim(),
            department: _prodiController.text.trim(),
          );
          
          await DatabaseHelper.instance.saveUserProfile(newProfile);
          
          // Navigate to homepage if auth is successful
          if (mounted) {
            context.go('/homepage');
          }
        }
      } on FirebaseAuthException catch (e) {
        // Handle Firebase Auth specific errors
        setState(() {
          print('Firebase Error Code: ${e.code}'); // Untuk debugging
          
          switch (e.code) {
            case 'user-not-found':
              errorMessage = 'Email tidak terdaftar';
              break;
            case 'wrong-password':
              errorMessage = 'Password salah';
              break;
            case 'invalid-credential':
              errorMessage = 'Email atau password salah';
              break;
            case 'invalid-login-credentials':
              errorMessage = 'Email atau password salah';
              break;
            case 'invalid-email':
              errorMessage = 'Format email tidak valid';
              break;
            case 'email-already-in-use':
              errorMessage = 'Email sudah digunakan';
              break;
            case 'weak-password':
              errorMessage = 'Password terlalu lemah';
              break;
            case 'user-disabled':
              errorMessage = 'Akun dinonaktifkan';
              break;
            case 'too-many-requests':
              errorMessage = 'Terlalu banyak percobaan, coba lagi nanti';
              break;
            case 'network-request-failed':
              errorMessage = 'Masalah koneksi jaringan';
              break;
            case 'operation-not-allowed':
              errorMessage = 'Operasi tidak diizinkan';
              break;
            default:
              errorMessage = 'Terjadi kesalahan saat login';
              // Log error untuk debugging tanpa menampilkan ke user
              print('Unhandled Firebase Auth Error: ${e.code} - ${e.message}');
          }
        });
      } catch (e) {
        // Handle other errors
        setState(() {
          errorMessage = 'Terjadi kesalahan saat menghubungi server';
          // Log error untuk debugging tanpa menampilkan ke user
          print('Unexpected error during auth: $e');
        });
      } finally {
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 40),
                Container(
                  width: 100,
                  height: 100,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  isLogin ? 'Selamat Datang Kembali!' : 'Buat Akun Baru',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3B6AA0),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  isLogin 
                    ? 'Masuk untuk melanjutkan'
                    : 'Daftar untuk mulai mengatur jadwal',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                
                // Display error message if any
                if (errorMessage != null) ...[
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: GoogleFonts.poppins(color: Colors.red[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                ],
                
                if (!isLogin) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Lengkap',
                      labelStyle: GoogleFonts.poppins(),
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    style: GoogleFonts.poppins(),
                    validator: (value) => _validateNotEmpty(value, 'Nama'),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _nimController,
                    decoration: InputDecoration(
                      labelText: 'NIM',
                      labelStyle: GoogleFonts.poppins(),
                      prefixIcon: Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    style: GoogleFonts.poppins(),
                    validator: (value) => _validateNotEmpty(value, 'NIM'),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _prodiController,
                    decoration: InputDecoration(
                      labelText: 'Program Studi',
                      labelStyle: GoogleFonts.poppins(),
                      prefixIcon: Icon(Icons.school_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    style: GoogleFonts.poppins(),
                    validator: (value) => _validateNotEmpty(value, 'Program Studi'),
                  ),
                ],
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: GoogleFonts.poppins(),
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  style: GoogleFonts.poppins(),
                  validator: _validateEmail,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: GoogleFonts.poppins(),
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  style: GoogleFonts.poppins(),
                  validator: _validatePassword,
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B6AA0),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    minimumSize: Size(double.infinity, 48),
                  ),
                  onPressed: isLoading ? null : _submitForm,
                  child: isLoading
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isLogin ? 'Masuk' : 'Daftar',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLogin ? 'Belum punya akun?' : 'Sudah punya akun?',
                      style: GoogleFonts.poppins(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          isLogin = !isLogin;
                          errorMessage = null; // Clear error when switching modes
                        });
                      },
                      child: Text(
                        isLogin ? 'Daftar' : 'Masuk',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF3B6AA0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Add password reset option
                if (isLogin) ...[
                  TextButton(
                    onPressed: () => _showResetPasswordDialog(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      padding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(
                      'Lupa password?',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Password reset dialog
  Future<void> _showResetPasswordDialog() async {
    final resetEmailController = TextEditingController();
    String? resetError;
    bool resetSent = false;
    bool isResetting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Reset Password', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!resetSent) ...[
                Text(
                  'Masukkan email Anda untuk menerima link reset password',
                  style: GoogleFonts.poppins(),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: resetEmailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: GoogleFonts.poppins(),
                  keyboardType: TextInputType.emailAddress,
                ),
                if (resetError != null) ...[
                  SizedBox(height: 12),
                  Text(
                    resetError!,
                    style: GoogleFonts.poppins(color: Colors.red),
                  ),
                ],
              ] else ...[
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 48,
                ),
                SizedBox(height: 16),
                Text(
                  'Email reset password telah dikirim ke ${resetEmailController.text}',
                  style: GoogleFonts.poppins(),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
          actions: [
            if (!resetSent) ...[
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Batal', style: GoogleFonts.poppins()),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B6AA0),
                  textStyle: GoogleFonts.poppins(),
                ),
                onPressed: isResetting ? null : () async {
                  if (resetEmailController.text.isEmpty) {
                    setDialogState(() {
                      resetError = 'Email tidak boleh kosong';
                    });
                    return;
                  }
                  
                  setDialogState(() {
                    isResetting = true;
                    resetError = null;
                  });
                  
                  try {
                    await _auth.sendPasswordResetEmail(
                      email: resetEmailController.text.trim(),
                    );
                    setDialogState(() {
                      resetSent = true;
                      isResetting = false;
                    });
                  } on FirebaseAuthException catch (e) {
                    String message = 'Terjadi kesalahan';
                    if (e.code == 'user-not-found') {
                      message = 'Email tidak terdaftar';
                    } else if (e.code == 'invalid-email') {
                      message = 'Email tidak valid';
                    }
                    setDialogState(() {
                      resetError = message;
                      isResetting = false;
                    });
                  } catch (e) {
                    setDialogState(() {
                      resetError = 'Terjadi kesalahan: $e';
                      isResetting = false;
                    });
                  }
                },
                child: isResetting 
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Kirim', style: GoogleFonts.poppins()),
              ),
            ] else ...[
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Tutup', style: GoogleFonts.poppins()),
              ),
            ],
          ],
        ),
      ),
    );
    
    resetEmailController.dispose();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _nimController.dispose();
    _prodiController.dispose();
    super.dispose();
  }
}