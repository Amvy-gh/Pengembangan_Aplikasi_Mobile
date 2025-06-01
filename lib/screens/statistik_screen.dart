import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/database_helper.dart';
import '../widgets/main_scaffold.dart';

class StatistikScreen extends StatefulWidget {
  const StatistikScreen({Key? key}) : super(key: key);

  @override
  _StatistikScreenState createState() => _StatistikScreenState();
}

class _StatistikScreenState extends State<StatistikScreen> {
  int totalJadwalKuliah = 0;
  int totalJadwalKelompok = 0;
  Map<String, int> jadwalPerHari = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistik();
  }

  Future<void> _loadStatistik() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Dapatkan user_id dari pengguna yang sedang login
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid;
      
      if (userId == null) {
        print('User tidak login, tidak dapat memuat statistik');
        setState(() {
          isLoading = false;
        });
        return;
      }

      print('Memuat statistik untuk user: ${user.email} (ID: $userId)');
      
      final db = DatabaseHelper.instance;
      
      // Muat jadwal dengan filter user_id
      final schedules = await db.getAllSchedules(userId: userId);
      final teamSchedules = await db.getAllTeamSchedules(userId: userId);
      
      // Hitung jadwal per hari
      final Map<String, int> hariCount = {
        'Senin': 0, 'Selasa': 0, 'Rabu': 0, 
        'Kamis': 0, 'Jumat': 0, 'Sabtu': 0, 'Minggu': 0
      };
      
      for (var schedule in schedules) {
        if (hariCount.containsKey(schedule.hari)) {
          hariCount[schedule.hari] = (hariCount[schedule.hari] ?? 0) + 1;
        }
      }
      
      setState(() {
        totalJadwalKuliah = schedules.length;
        totalJadwalKelompok = teamSchedules.length;
        jadwalPerHari = hariCount;
        isLoading = false;
      });
    } catch (e) {
      print('Error memuat statistik: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Statistik',
      body: isLoading 
        ? Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadStatistik,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserInfo(),
                  SizedBox(height: 24),
                  _buildStatistikCard(),
                  SizedBox(height: 24),
                  _buildJadwalPerHariCard(),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildUserInfo() {
    final user = FirebaseAuth.instance.currentUser;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Icon(Icons.person, color: Colors.white),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? user?.email?.split('@')[0] ?? "User",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user?.email ?? "",
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistikCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ringkasan Jadwal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    Icons.school,
                    totalJadwalKuliah.toString(),
                    'Jadwal Kuliah',
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    Icons.group,
                    totalJadwalKelompok.toString(),
                    'Jadwal Kelompok',
                    Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    Icons.calendar_today,
                    (totalJadwalKuliah + totalJadwalKelompok).toString(),
                    'Total Jadwal',
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJadwalPerHariCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jadwal Per Hari',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ...jadwalPerHari.entries.map((entry) => _buildHariItem(
              entry.key,
              entry.value,
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildHariItem(String hari, int jumlah) {
    final double percentage = totalJadwalKuliah > 0 
      ? jumlah / totalJadwalKuliah 
      : 0;
    
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(hari, style: TextStyle(fontWeight: FontWeight.w500)),
              Text('$jumlah jadwal'),
            ],
          ),
          SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              _getColorForDay(hari),
            ),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Color _getColorForDay(String day) {
    switch (day) {
      case 'Senin': return Colors.blue;
      case 'Selasa': return Colors.green;
      case 'Rabu': return Colors.orange;
      case 'Kamis': return Colors.purple;
      case 'Jumat': return Colors.teal;
      case 'Sabtu': return Colors.red;
      case 'Minggu': return Colors.indigo;
      default: return Colors.grey;
    }
  }
}
