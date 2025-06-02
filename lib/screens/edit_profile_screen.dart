import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/database_helper.dart';
import '../models/user_profile.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nimController = TextEditingController();
  final _prodiController = TextEditingController();
  final _emailController = TextEditingController();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }
  
  Future<void> _loadUserProfile() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final currentUser = _auth.currentUser;
      
      if (currentUser != null) {
        // Set email dari Firebase Auth
        _emailController.text = currentUser.email ?? '';
        
        // Load data dari SQLite
        final userProfile = await DatabaseHelper.instance.getUserProfile(currentUser.uid);
        
        if (userProfile != null) {
          setState(() {
            _nameController.text = userProfile.displayName ?? '';
            _nimController.text = userProfile.studentId ?? '';
            _prodiController.text = userProfile.department ?? '';
          });
        } else {
          // Jika tidak ada data di SQLite, gunakan data dari Firebase Auth
          setState(() {
            _nameController.text = currentUser.displayName ?? '';
          });
        }
      }
    } catch (e) {
      print('Error loading user profile: $e');
      setState(() {
        errorMessage = 'Gagal memuat data profil';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  
  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isSaving = true;
        errorMessage = null;
      });
      
      try {
        final currentUser = _auth.currentUser;
        
        if (currentUser != null) {
          // Update display name di Firebase Auth
          await currentUser.updateDisplayName(_nameController.text.trim());
          
          // Update data di SQLite
          final updatedProfile = UserProfile(
            uid: currentUser.uid,
            displayName: _nameController.text.trim(),
            email: currentUser.email ?? '',
            studentId: _nimController.text.trim(),
            department: _prodiController.text.trim(),
          );
          
          await DatabaseHelper.instance.saveUserProfile(updatedProfile);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Profil berhasil diperbarui'),
                backgroundColor: Colors.green,
              ),
            );
            context.pop();
          }
        } else {
          throw Exception('User tidak ditemukan');
        }
      } catch (e) {
        print('Error saving profile: $e');
        setState(() {
          errorMessage = 'Terjadi kesalahan saat menyimpan profil';
        });
      } finally {
        if (mounted) {
          setState(() {
            isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profil'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Color(0xFF4A7AB9).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
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
                    
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Lengkap',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Nama tidak boleh kosong' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      enabled: false, // Email tidak bisa diubah langsung di sini
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        helperText: 'Email tidak dapat diubah di sini',
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _nimController,
                      decoration: InputDecoration(
                        labelText: 'NIM',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'NIM tidak boleh kosong' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _prodiController,
                      decoration: InputDecoration(
                        labelText: 'Program Studi',
                        prefixIcon: Icon(Icons.school_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Program Studi tidak boleh kosong' : null,
                    ),
                    SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSaving
                          ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text('Simpan Perubahan'),
                    ),                    
                  ],
                ),
              ),
            ),
    );  
                      
                    
  }

  @override

  void dispose() {
    _nameController.dispose();
    _nimController.dispose();
    _prodiController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}