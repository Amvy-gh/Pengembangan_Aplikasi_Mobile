import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _perkuliahanNotif = true;
  bool _kerjaKelompokNotif = true;
  bool _deadlineNotif = true;
  int _reminderTime = 30; // minutes

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pengaturan Notifikasi'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text('Jadwal Perkuliahan'),
            subtitle: Text('Notifikasi untuk jadwal kuliah'),
            value: _perkuliahanNotif,
            onChanged: (value) => setState(() => _perkuliahanNotif = value),
          ),
          SwitchListTile(
            title: Text('Kerja Kelompok'),
            subtitle: Text('Notifikasi untuk jadwal kerja kelompok'),
            value: _kerjaKelompokNotif,
            onChanged: (value) => setState(() => _kerjaKelompokNotif = value),
          ),
          SwitchListTile(
            title: Text('Deadline Tugas'),
            subtitle: Text('Notifikasi untuk deadline tugas'),
            value: _deadlineNotif,
            onChanged: (value) => setState(() => _deadlineNotif = value),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Waktu Pengingat',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 8),
                Text(
                  'Berapa menit sebelum jadwal dimulai',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _reminderTime,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(value: 15, child: Text('15 menit')),
                    DropdownMenuItem(value: 30, child: Text('30 menit')),
                    DropdownMenuItem(value: 60, child: Text('1 jam')),
                    DropdownMenuItem(value: 120, child: Text('2 jam')),
                  ],
                  onChanged: (value) => setState(() => _reminderTime = value!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
