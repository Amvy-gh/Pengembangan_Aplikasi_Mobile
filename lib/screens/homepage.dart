import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../widgets/main_scaffold.dart';
import '../utils/database_helper.dart';
import 'jadwal_perkuliahan.dart';
import 'jadwal_kerja_kelompok.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> with WidgetsBindingObserver {
  List<Map<String, dynamic>> todaySchedule = [];
  List<Map<String, dynamic>> todayTeamSchedule = [];
  List<Map<String, dynamic>> todayOptimalSchedule = [];
  // Use Firebase Auth to get the current user's display name or email
  String get currentUser {
    final user = FirebaseAuth.instance.currentUser;
    return user?.displayName ?? user?.email?.split('@')[0] ?? "User";
  }
  late DateTime _currentDate;
  late String _greeting;
  late Timer _timer;
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateDateTime();
    _loadTodaySchedules();
    _isInitialized = true;
    
    // Update time every minute
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      _updateDateTime();
    });
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isInitialized) {
      // Reload data when app is resumed (e.g., coming back from another screen)
      print('Homepage resumed - reloading data');
      _loadTodaySchedules();
    }
  }
  
  void _updateDateTime() {
    setState(() {
      _currentDate = DateTime.now();
      _greeting = _getGreeting(_currentDate.hour);
    });
  }
  
  String _getGreeting(int hour) {
    if (hour < 12) {
      return 'Good Morning,';
    } else if (hour < 17) {
      return 'Good Afternoon,';
    } else {
      return 'Good Evening,';
    }
  }

  Future<void> _loadTodaySchedules() async {
    try {
      final db = DatabaseHelper.instance;
      final schedules = await db.getAllSchedules();
      final teamSchedules = await db.getAllTeamSchedules();
      final optimalSchedules = await db.getAllOptimalSchedules();
      final today = DateTime.now();
      final dayName = _getDayName(today.weekday);
      
      print('Loaded ${schedules.length} regular schedules, ${teamSchedules.length} team schedules, and ${optimalSchedules.length} optimal schedules');
      
      setState(() {
        // Filter jadwal kuliah untuk user saat ini
        todaySchedule = schedules
          .where((schedule) => schedule.hari == dayName)
          .map((schedule) => {
            'title': schedule.mataKuliah,
            'time': '${schedule.startTime} - ${schedule.endTime}',
            'location': schedule.ruangan,
            'icon': _getIconForCourse(schedule.mataKuliah),
            'color': _getColorForCourse(schedule.mataKuliah),
          })
          .toList();

        // Filter jadwal kelompok biasa untuk hari ini
        todayTeamSchedule = teamSchedules
          .where((teamSchedule) => 
            teamSchedule.schedule.hari == dayName && 
            teamSchedule.members.any((member) => member.name == currentUser))
          .map((teamSchedule) => {
            'title': "${teamSchedule.schedule.mataKuliah} (Kelompok)",
            'time': teamSchedule.startTime != null && teamSchedule.endTime != null
                ? '${teamSchedule.startTime} - ${teamSchedule.endTime}'
                : teamSchedule.schedule.waktu,
            'location': teamSchedule.schedule.ruangan,
            'icon': Icons.group,
            'color': Colors.purple,
            'members': teamSchedule.members.map((m) => m.name).toList(),
          })
          .toList();
          
        // Add optimal schedules for today
        final selectedOptimalSchedules = optimalSchedules
          .where((schedule) => schedule.isSelected && schedule.day == dayName)
          .map((schedule) => {
            'title': "Jadwal Optimal (CSP)",
            'time': schedule.time,
            'location': schedule.location,
            'icon': Icons.group_work,
            'color': Colors.indigo,
            'members': schedule.members,
          })
          .toList();
          
        // Combine regular team schedules with optimal schedules
        todayTeamSchedule = [...todayTeamSchedule, ...selectedOptimalSchedules];
      });
    } catch (e) {
      print('Error loading schedules: $e');
    }
  }

  String _getDayName(int weekday) {
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return days[weekday - 1];
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, VoidCallback onPressed) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: IconButton(
            icon: Icon(icon, color: Theme.of(context).primaryColor),
            onPressed: onPressed,
          ),
        ),
        SizedBox(height: 8),
        Text(label),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selamat Datang!',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Text(
          'Kelola jadwal perkuliahan Anda',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(
          context,
          'Jadwal',
          Icons.calendar_today,
          () => context.go('/jadwal-perkuliahan'),
        ),
        _buildActionButton(
          context,
          'Kelompok',
          Icons.group,
          () => context.go('/jadwal-kerja-kelompok'),
        ),
        _buildActionButton(
          context,
          'Statistik',
          Icons.bar_chart,
          () => context.go('/statistik'),
        ),
      ],
    );
  }

  Widget _buildScheduleCard(BuildContext context, String title, String time,
      String location, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                    SizedBox(width: 4),
                    Text(
                      time,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                    SizedBox(width: 4),
                    Text(
                      location,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to determine icon based on course name
  IconData _getIconForCourse(String courseName) {
    if (courseName.toLowerCase().contains('mobile')) return Icons.phone_android;
    if (courseName.toLowerCase().contains('data')) return Icons.storage;
    if (courseName.toLowerCase().contains('ai') || 
        courseName.toLowerCase().contains('kecerdasan')) return Icons.psychology;
    if (courseName.toLowerCase().contains('kelompok')) return Icons.group;
    return Icons.book;
  }

  // Helper function to determine color based on course name
  Color _getColorForCourse(String courseName) {
    if (courseName.toLowerCase().contains('mobile')) return Colors.blue;
    if (courseName.toLowerCase().contains('data')) return Colors.orange;
    if (courseName.toLowerCase().contains('ai') || 
        courseName.toLowerCase().contains('kecerdasan')) return Colors.green;
    if (courseName.toLowerCase().contains('kelompok')) return Colors.purple;
    return Colors.teal;
  }

  @override
  Widget build(BuildContext context) {
    // Format the current date
    final formattedDate = DateFormat('d MMMM yyyy').format(_currentDate);
    final dayName = _getDayName(_currentDate.weekday);
    final scheduleCount = todaySchedule.length;
    
    return MainScaffold(
      currentIndex: 0,
      body: SafeArea(
        top: true,
        bottom: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with profile and greeting
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Profile image/logo
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(4),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 40,
                          height: 40,
                        ),
                      ),
                    ),
                    
                    // Greeting and name
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _greeting,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        Text(
                          currentUser + '!',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                SizedBox(height: 24),
                
                // Blue date section
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0xFF4A7AB9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dayName + ',',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            formattedDate,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 12),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Color(0xFFFFD95A),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              scheduleCount > 0 
                                ? 'Hari ini ada $scheduleCount kelas perkuliahan'
                                : 'Hari ini tidak ada kelas perkuliahan',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Today's Schedule Section
                Row(
                  children: [
                    Text(
                      'Jadwal Hari Ini',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      formattedDate,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                
                // Schedule content or empty state
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: todaySchedule.isEmpty
                    ? Column(
                        children: [
                          Text(
                            'Belum Ada Jadwal !',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade900,
                            ),
                          ),
                          SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => context.go('/jadwal-perkuliahan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF4A7AB9),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            ),
                            child: Text(
                              'TAMBAHKAN JADWAL',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          ...todaySchedule.map((schedule) =>
                            _buildScheduleCard(
                              context,
                              schedule['title'],
                              schedule['time'],
                              schedule['location'],
                              schedule['icon'],
                              schedule['color'],
                            ),
                          ),
                        ],
                      ),
                ),
                
                SizedBox(height: 24),
                
                // Team Schedule Section
                Row(
                  children: [
                    Text(
                      'Jadwal Kerkom Hari Ini',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      formattedDate,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                
                // Team schedule content or empty state
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: todayTeamSchedule.isEmpty
                    ? Column(
                        children: [
                          Text(
                            'Belum Ada Jadwal Kerja Kelompok!',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade900,
                            ),
                          ),
                          SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => context.go('/jadwal-kerja-kelompok'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF4A7AB9),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            ),
                            child: Text(
                              'TAMBAHKAN JADWAL KELOMPOK',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...todayTeamSchedule.map((schedule) =>
                            _buildTeamScheduleCard(
                              context,
                              schedule['title'],
                              schedule['time'],
                              schedule['location'],
                              schedule['members'],
                            ),
                          ),
                        ],
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamScheduleCard(BuildContext context, String title, String time,
      String location, List<dynamic> members) {
    // Determine if this is an optimal schedule by checking the title
    bool isOptimalSchedule = title.contains('Optimal') || title.contains('CSP');
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isOptimalSchedule ? Colors.indigo.withOpacity(0.2) : Colors.purple.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOptimalSchedule ? Icons.group_work : Icons.group, 
              color: isOptimalSchedule ? Colors.indigo : Colors.purple, 
              size: 20
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                    SizedBox(width: 4),
                    Text(
                      time,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                    SizedBox(width: 4),
                    Text(
                      location,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Anggota:',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
                SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: members.map((member) {
                    // Handle both String members (from optimal schedules) and TeamMember objects
                    String memberName = member is String ? member : (member is TeamMember ? member.name : 'Unknown');
                    
                    return Chip(
                      label: Text(
                        memberName,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      backgroundColor: isOptimalSchedule ? Colors.indigo.shade50 : Colors.grey.shade100,
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
