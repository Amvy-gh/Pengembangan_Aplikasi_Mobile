import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool isLoading = false;
  String? errorMessage;
  late String currentEmail;

  @override
  void initState() {
    super.initState();
    // Get current user email
    final user = _auth.currentUser;
    currentEmail = user?.email ?? 'Tidak ada email';
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    if (!value.contains('@')) {
      return 'Email tidak valid';
    }
    if (value == currentEmail) {
      return 'Email baru tidak boleh sama dengan email saat ini';
    }
    return null;
  }

  Future<void> _updateEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      try {
        // Get current user
        final user = _auth.currentUser;
        
        if (user == null) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'Pengguna tidak ditemukan. Silakan login kembali.',
          );
        }

        // Re-authenticate user before changing email
        AuthCredential credential = EmailAuthProvider.credential(
          email: currentEmail,
          password: _passwordController.text.trim(),
        );
        
        await user.reauthenticateWithCredential(credential);
        
        // Update email
        await user.updateEmail(_newEmailController.text.trim());
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Email berhasil diperbarui'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          switch (e.code) {
            case 'user-not-found':
              errorMessage = 'Pengguna tidak ditemukan. Silakan login kembali.';
              break;
            case 'wrong-password':
              errorMessage = 'Password salah';
              break;
            case 'invalid-email':
              errorMessage = 'Email tidak valid';
              break;
            case 'user-disabled':
              errorMessage = 'Akun dinonaktifkan';
              break;
            case 'requires-recent-login':
              errorMessage = 'Silakan login ulang untuk mengubah email';
              break;
            case 'email-already-in-use':
              errorMessage = 'Email sudah digunakan oleh akun lain';
              break;
            case 'network-request-failed':
              errorMessage = 'Masalah koneksi jaringan';
              break;
            default:
              errorMessage = 'Terjadi kesalahan: ${e.message}';
          }
        });
      } catch (e) {
        setState(() {
          errorMessage = 'Terjadi kesalahan: $e';
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
      appBar: AppBar(
        title: Text('Ganti Email'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Email saat ini:',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                initialValue: currentEmail,
                enabled: false,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 24),
              
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
              
              TextFormField(
                controller: _newEmailController,
                decoration: InputDecoration(
                  labelText: 'Email Baru',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password Saat Ini',
                  helperText: 'Diperlukan untuk verifikasi',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: true,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Password tidak boleh kosong' : null,
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: isLoading ? null : _updateEmail,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _newEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}