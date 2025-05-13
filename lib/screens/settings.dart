import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/main_scaffold.dart';

class SettingsPage extends StatefulWidget {
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedLanguage = 'Indonesia';
  String _selectedTheme = 'Terang';

  void _showLanguageBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Pilih Bahasa',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(
                _selectedLanguage == 'Indonesia' 
                    ? Icons.radio_button_checked 
                    : Icons.radio_button_unchecked,
                color: Theme.of(context).primaryColor,
              ),
              title: Text('Indonesia'),
              onTap: () {
                setState(() => _selectedLanguage = 'Indonesia');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                _selectedLanguage == 'English' 
                    ? Icons.radio_button_checked 
                    : Icons.radio_button_unchecked,
                color: Theme.of(context).primaryColor,
              ),
              title: Text('English'),
              onTap: () {
                setState(() => _selectedLanguage = 'English');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Pilih Tema',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(
                _selectedTheme == 'Terang' 
                    ? Icons.radio_button_checked 
                    : Icons.radio_button_unchecked,
                color: Theme.of(context).primaryColor,
              ),
              title: Text('Terang'),
              onTap: () {
                setState(() => _selectedTheme = 'Terang');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                _selectedTheme == 'Gelap' 
                    ? Icons.radio_button_checked 
                    : Icons.radio_button_unchecked,
                color: Theme.of(context).primaryColor,
              ),
              title: Text('Gelap'),
              onTap: () {
                setState(() => _selectedTheme = 'Gelap');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                _selectedTheme == 'Sistem' 
                    ? Icons.radio_button_checked 
                    : Icons.radio_button_unchecked,
                color: Theme.of(context).primaryColor,
              ),
              title: Text('Sistem'),
              onTap: () {
                setState(() => _selectedTheme = 'Sistem');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 3,
      title: 'Pengaturan',
      body: ListView(
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
                icon: Icons.email_outlined,
                title: 'Ganti Email',
                subtitle: 'Ubah alamat email yang terdaftar',
                onTap: () => context.push('/settings/email'),
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
            'Aplikasi',
            [
              _buildSettingTile(
                context,
                icon: Icons.notifications_outlined,
                title: 'Notifikasi',
                subtitle: 'Atur pengingat jadwal',
                onTap: () => context.push('/settings/notifications'),
              ),
              _buildSettingTile(
                context,
                icon: Icons.language_outlined,
                title: 'Bahasa',
                subtitle: 'Pilih bahasa aplikasi',
                trailing: Text(_selectedLanguage),
                onTap: _showLanguageBottomSheet,
              ),
              _buildSettingTile(
                context,
                icon: Icons.palette_outlined,
                title: 'Tema',
                subtitle: 'Ubah tampilan aplikasi',
                trailing: Text(_selectedTheme),
                onTap: _showThemeBottomSheet,
              ),
            ],
          ),
          _buildSection(
            'Lainnya',
            [
              _buildSettingTile(
                context,
                icon: Icons.help_outline,
                title: 'Bantuan',
                subtitle: 'Pusat bantuan dan FAQ',
                onTap: () => context.push('/settings/help'),
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
                        onPressed: () {
                          Navigator.pop(context);
                          context.go('/auth');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Keluar'),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
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
              color: Colors.grey[600],
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
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: Theme.of(context).primaryColor,
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
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
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
            'John Doe',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Teknik Informatika',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'john.doe@example.com',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
