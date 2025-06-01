import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/main_scaffold.dart';
import '../utils/database_helper.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Data pengguna
  String _userName = '';
  String _userEmail = '';
  String _userNim = '';
  String _userProdi = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Fungsi untuk memuat data profil pengguna dari database
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Set email dari Firebase Auth
        _userEmail = currentUser.email ?? '';

        // Load data dari SQLite
        final userProfile = await DatabaseHelper.instance.getUserProfile(currentUser.uid);

        setState(() {
          if (userProfile != null) {
            _userName = userProfile.name;
            _userNim = userProfile.nim;
            _userProdi = userProfile.prodi;
          } else {
            // Jika tidak ada data di SQLite, gunakan data dari Firebase Auth
            _userName = currentUser.displayName ?? 'Pengguna';
            _userNim = '-';
            _userProdi = '-';
          }
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
      // Set nilai default jika gagal memuat data
      setState(() {
        _userName = 'Pengguna';
        _userEmail = 'email@example.com';
        _userNim = '-';
        _userProdi = '-';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 3,
      title: 'Pengaturan',
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.only(bottom: 32),
              children: [
                _buildProfileHeader(),
                SizedBox(height: 24),
                _buildSection(
                  'Profil',
                  [
                    _buildSettingTile(
                      context,
                      icon: Icons.person_outline,
                      title: 'Edit Profil',
                      subtitle: 'Ubah nama, foto, dan informasi lainnya',
                      onTap: () => context.push('/settings/profile'),
                    ),
                    _buildSettingTile(
                      context,
                      icon: Icons.lock_outline,
                      title: 'Ganti Password',
                      subtitle: 'Ubah password akun anda',
                      onTap: () => context.push('/settings/password'),
                    ),
                  ],
                ),
                _buildSection(
                  'Lainnya',
                  [
                    _buildSettingTile(
                      context,
                      icon: Icons.help_outline,
                      title: 'FAQ',
                      subtitle: 'Pertanyaan yang sering ditanyakan',
                      onTap: () => context.push('/faq'),
                    ),
                    _buildSettingTile(
                      context,
                      icon: Icons.info_outline,
                      title: 'Tentang',
                      subtitle: 'Informasi aplikasi',
                      onTap: () => context.push('/settings/about'),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.all(24),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Keluar'),
                          content: Text('Apakah Anda yakin ingin keluar?'),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Batal'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                // Sign out dari Firebase
                                await FirebaseAuth.instance.signOut();
                                context.go('/auth');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF4A7AB9),
                                foregroundColor: Colors.white,
                              ),
                              child: Text('Keluar'),
                            ),
                          ],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4A7AB9),
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: Icon(Icons.logout),
                    label: Text(
                      'Keluar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4A7AB9),
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF4A7AB9).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: Color(0xFF4A7AB9),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    SizedBox(width: 8),
                    trailing,
                  ] else
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[400],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      margin: EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4A7AB9),
            Color(0xFF4A7AB9).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF4A7AB9).withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            backgroundImage: NetworkImage('https://via.placeholder.com/80'),
          ),
          SizedBox(height: 16),
          Text(
            _userName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school_outlined,
                color: Colors.white.withOpacity(0.8),
                size: 14,
              ),
              SizedBox(width: 4),
              Text(
                _userProdi,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.badge_outlined,
                color: Colors.white.withOpacity(0.8),
                size: 14,
              ),
              SizedBox(width: 4),
              Text(
                'NIM: $_userNim',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.email_outlined,
                color: Colors.white.withOpacity(0.8),
                size: 14,
              ),
              SizedBox(width: 4),
              Text(
                _userEmail,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}