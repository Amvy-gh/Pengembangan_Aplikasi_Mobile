import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  // Perbaikan error handling di metode _submitForm()

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
          await _auth.signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
        } else {
          // Handle Registration
          UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
          
          // Update display name
          await userCredential.user!.updateDisplayName(_nameController.text.trim());
        }
        
        // Navigate to homepage if auth is successful
        if (mounted) {
          context.go('/homepage');
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
                Icon(
                  Icons.schedule,
                  size: 64,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(height: 24),
                Text(
                  isLogin ? 'Selamat Datang Kembali!' : 'Buat Akun Baru',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  isLogin 
                    ? 'Masuk untuk melanjutkan'
                    : 'Daftar untuk mulai mengatur jadwal',
                  style: TextStyle(
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
                            style: TextStyle(
                              color: Colors.red.shade800,
                            ),
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
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    validator: (value) => 
                      value?.isEmpty ?? true ? 'Nama tidak boleh kosong' : null,
                  ),
                  SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword 
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => 
                        obscurePassword = !obscurePassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  obscureText: obscurePassword,
                  validator: _validatePassword,
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() => isLogin = !isLogin),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    isLogin
                      ? 'Belum punya akun? Daftar'
                      : 'Sudah punya akun? Masuk',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
                      style: TextStyle(
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
          title: Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!resetSent) ...[
                Text('Masukkan email Anda untuk menerima link reset password'),
                SizedBox(height: 16),
                TextField(
                  controller: resetEmailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                if (resetError != null) ...[
                  SizedBox(height: 12),
                  Text(
                    resetError!,
                    style: TextStyle(color: Colors.red),
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
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
          actions: [
            if (!resetSent) ...[
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Batal'),
              ),
              ElevatedButton(
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
                  : Text('Kirim'),
              ),
            ] else ...[
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Tutup'),
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
    super.dispose();
  }
}