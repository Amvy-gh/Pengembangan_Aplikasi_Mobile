import 'package:flutter/material.dart';
import '../widgets/main_scaffold.dart';
import 'jadwal_perkuliahan.dart';
import '../utils/database_helper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeamMember {
  String name;
  String role;
  List<String> availableTimes = [];

  TeamMember({required this.name, required this.role, List<String>? availableTimes}) {
    this.availableTimes = availableTimes ?? [];
  }
}

class TeamSchedule {
  int? id; // Make id optional and non-final so it can be updated
  Schedule schedule;
  List<TeamMember> members;
  String? startTime; // Add start time
  String? endTime; // Add end time

  TeamSchedule({
    this.id, 
    required this.schedule, 
    required this.members,
    this.startTime,
    this.endTime
  });
}

class OptimalSchedule {
  final int? id;
  String day;
  String time;
  String location;
  List<String> members;
  bool isSelected;
  
  OptimalSchedule({
    this.id,
    required this.day,
    required this.time,
    required this.location,
    required this.members,
    this.isSelected = false
  });
}

class JadwalKerjaKelompok extends StatefulWidget {
  const JadwalKerjaKelompok({super.key});

  @override
  State<JadwalKerjaKelompok> createState() => _JadwalKerjaKelompokState();
}

class _JadwalKerjaKelompokState extends State<JadwalKerjaKelompok> {
  final _searchController = TextEditingController();
  List<TeamSchedule> teamSchedules = [];
  List<Schedule> jadwalKuliah = [];
  List<OptimalSchedule> optimalSchedules = [];
  bool showOptimalSchedules = false;
  bool showSelectedSchedule = false; // Flag to show selected schedule section
  OptimalSchedule? selectedOptimalSchedule; // Store the selected optimal schedule
  final _formKey = GlobalKey<FormState>();
  final _memberNameController = TextEditingController();
  final _memberRoleController = TextEditingController();
  // Use Firebase Auth to get the current user's display name or email
  String get currentUser {
    final user = FirebaseAuth.instance.currentUser;
    return user?.displayName ?? user?.email?.split('@')[0] ?? "User";
  }
  
  // Get greeting based on time of day
  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning,';
    } else if (hour < 17) {
      return 'Good Afternoon,';
    } else {
      return 'Good Evening,';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadSelectedOptimalSchedule();
    // No need to initialize jadwalKuliah with sample data anymore
    // This data will come from the jadwal_perkuliahan.dart screen
  }
  
  // Load any previously selected optimal schedule
  Future<void> _loadSelectedOptimalSchedule() async {
    try {
      // Dapatkan user_id dari pengguna yang sedang login
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid;
      
      final selectedSchedule = await DatabaseHelper.instance.getSelectedOptimalSchedule(userId: userId);
      if (selectedSchedule != null) {
        setState(() {
          selectedOptimalSchedule = selectedSchedule;
          showSelectedSchedule = true;
        });
      }
    } catch (e) {
      print('Error loading selected optimal schedule: $e');
      // Don't show error to user, just silently fail
      // This is expected on first run or after database changes
    }
  }
  
  // Hapus jadwal tim terpilih (hasil CSP)
  Future<void> _deleteSelectedOptimalSchedule() async {
    try {
      final db = DatabaseHelper.instance;
      // Dapatkan user_id dari pengguna yang sedang login
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid;
      
      // Hapus jadwal tim terpilih dari database
      await db.deleteSelectedOptimalSchedule(userId: userId);
      
      setState(() {
        selectedOptimalSchedule = null;
        showSelectedSchedule = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Jadwal tim terpilih berhasil dihapus')),
      );
    } catch (e) {
      print('Error deleting selected optimal schedule: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus jadwal tim terpilih')),
      );
    }
  }

  Future<void> _loadData() async {
    try {
      final db = DatabaseHelper.instance;
      // Dapatkan user_id dari pengguna yang sedang login
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid;
      
      print('Loading team schedules for user: ${user?.email} (ID: $userId)');
      
      // Load regular schedules for reference with user_id filter
      final schedules = await db.getAllSchedules(userId: userId);
      // Pastikan jadwal tim juga difilter berdasarkan user_id
      final teamSchedules = await db.getAllTeamSchedules(userId: userId);
      
      print('Loaded ${schedules.length} regular schedules and ${teamSchedules.length} team schedules for user $userId');
      
      setState(() {
        // Only update teamSchedules, don't modify jadwalKuliah here
        this.teamSchedules = teamSchedules;
        
        // Just use the regular schedules for reference without modifying jadwalKuliah
        if (this.jadwalKuliah.isEmpty && schedules.isNotEmpty) {
          this.jadwalKuliah = schedules;
        }
      });
    } catch (e) {
      print('Error loading data: $e');
      // Fallback to default data if database fails
    }
  }

  Future<void> _addTeamSchedule(Schedule schedule, List<TeamMember> members) async {
    try {
      // Dapatkan user_id dari pengguna yang sedang login
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid;
      
      final teamSchedule = TeamSchedule(schedule: schedule, members: members);
      final id = await DatabaseHelper.instance.insertTeamSchedule(teamSchedule, userId: userId);
      await _loadData(); // Reload data from database
    } catch (e) {
      print('Error adding team schedule: $e');
      // Add to local list if database fails
      setState(() {
        teamSchedules.add(TeamSchedule(
          schedule: schedule,
          members: members,
        ));
      });
    }
  }
  
  Future<void> _addTeamScheduleWithTimes(TeamSchedule teamSchedule) async {
    try {
      // Dapatkan user_id dari pengguna yang sedang login
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid;
      
      // Use insertTeamScheduleOnly to avoid affecting jadwal_perkuliahan data
      final id = await DatabaseHelper.instance.insertTeamScheduleOnly(teamSchedule, userId: userId);
      print('Team schedule saved with ID: $id');
      
      // Update the teamSchedule with the assigned ID
      teamSchedule.id = id;
      
      // Add to the local list immediately for UI feedback
      setState(() {
        teamSchedules.add(teamSchedule);
      });
      
      // Also reload from database to ensure consistency
      await _loadTeamSchedulesOnly();
    } catch (e) {
      print('Error adding team schedule with times: $e');
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving team schedule: $e')),
      );
    }
  }
  
  // New method to only load team schedules without affecting jadwalKuliah
  Future<void> _loadTeamSchedulesOnly() async {
    try {
      final db = DatabaseHelper.instance;
      // Dapatkan user_id dari pengguna yang sedang login
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid;
      
      // Load team schedules with user_id filter
      final teamSchedules = await db.getAllTeamSchedules(userId: userId);
      
      setState(() {
        this.teamSchedules = teamSchedules;
      });
    } catch (e) {
      print('Error loading team schedules: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _memberNameController.dispose();
    _memberRoleController.dispose();
    super.dispose();
  }

  void _showAddScheduleDialog() {
    final _mataKuliahController = TextEditingController();
    final _ruanganController = TextEditingController();
    final _dosenController = TextEditingController();
    final _startTimeController = TextEditingController();
    final _endTimeController = TextEditingController();
    TimeOfDay _selectedStartTime = TimeOfDay.now();
    TimeOfDay _selectedEndTime = TimeOfDay(hour: TimeOfDay.now().hour + 1, minute: TimeOfDay.now().minute);
    String _selectedHari = 'Senin';
    List<TeamMember> teamMembers = [];

    final List<String> _hariList = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Tambah Jadwal Tim'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _mataKuliahController,
                    decoration: InputDecoration(
                      labelText: 'Mata Kuliah',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Masukkan mata kuliah';
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedHari,
                    decoration: InputDecoration(
                      labelText: 'Hari',
                      border: OutlineInputBorder(),
                    ),
                    items: _hariList.map((hari) {
                      return DropdownMenuItem(value: hari, child: Text(hari));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedHari = value!;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _startTimeController,
                          decoration: InputDecoration(
                            labelText: 'Waktu Mulai',
                            border: OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.access_time),
                              onPressed: () async {
                                final TimeOfDay? picked = await showTimePicker(
                                  context: context,
                                  initialTime: _selectedStartTime,
                                );
                                if (picked != null) {
                                  setState(() {
                                    _selectedStartTime = picked;
                                    _startTimeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                  });
                                }
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Waktu mulai';
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _endTimeController,
                          decoration: InputDecoration(
                            labelText: 'Waktu Selesai',
                            border: OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.access_time),
                              onPressed: () async {
                                final TimeOfDay? picked = await showTimePicker(
                                  context: context,
                                  initialTime: _selectedEndTime,
                                );
                                if (picked != null) {
                                  setState(() {
                                    _selectedEndTime = picked;
                                    _endTimeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                  });
                                }
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Waktu selesai';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _ruanganController,
                    decoration: InputDecoration(
                      labelText: 'Ruangan',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Masukkan ruangan';
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _dosenController,
                    decoration: InputDecoration(
                      labelText: 'Dosen',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Masukkan nama dosen';
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  // Team Members List
                  ...teamMembers.map((member) => ListTile(
                    title: Text(member.name),
                    subtitle: Text(member.role),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          teamMembers.remove(member);
                        });
                      },
                    ),
                  )).toList(),
                  // Add Member Form
                  TextFormField(
                    controller: _memberNameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Anggota',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _memberRoleController,
                    decoration: InputDecoration(
                      labelText: 'Peran',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_memberNameController.text.isNotEmpty &&
                          _memberRoleController.text.isNotEmpty) {
                        setState(() {
                          teamMembers.add(TeamMember(
                            name: _memberNameController.text,
                            role: _memberRoleController.text,
                          ));
                          _memberNameController.clear();
                          _memberRoleController.clear();
                        });
                      }
                    },
                    child: Text('Tambah Anggota'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate() && teamMembers.isNotEmpty) {
                  // Create a combined time string from start and end times
                  String waktu = '${_startTimeController.text} - ${_endTimeController.text}';
                  
                  final schedule = Schedule(
                    mataKuliah: _mataKuliahController.text,
                    waktu: waktu,
                    startTime: _startTimeController.text,
                    endTime: _endTimeController.text,
                    ruangan: _ruanganController.text,
                    dosen: _dosenController.text,
                    hari: _selectedHari,
                  );
                  
                  // Create TeamSchedule with start and end times
                  final teamSchedule = TeamSchedule(
                    schedule: schedule,
                    members: teamMembers,
                    startTime: _startTimeController.text,
                    endTime: _endTimeController.text
                  );
                  
                  // Add to database or local list
                  _addTeamScheduleWithTimes(teamSchedule);
                  Navigator.pop(context);
                }
              },
              child: Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  // Add these methods to the _JadwalKerjaKelompokState class
  void _editTeamSchedule(TeamSchedule schedule) {
    final _mataKuliahController = TextEditingController(text: schedule.schedule.mataKuliah);
    final _ruanganController = TextEditingController(text: schedule.schedule.ruangan);
    final _dosenController = TextEditingController(text: schedule.schedule.dosen);
    
    // Extract start and end times from the waktu field if available
    String startTime = schedule.startTime ?? '';
    String endTime = schedule.endTime ?? '';
    
    // If start/end times aren't available but waktu has the format "HH:MM - HH:MM"
    if ((startTime.isEmpty || endTime.isEmpty) && schedule.schedule.waktu.contains(' - ')) {
      List<String> timeParts = schedule.schedule.waktu.split(' - ');
      if (timeParts.length == 2) {
        startTime = timeParts[0].trim();
        endTime = timeParts[1].trim();
      }
    }
    
    final _startTimeController = TextEditingController(text: startTime);
    final _endTimeController = TextEditingController(text: endTime);
    
    TimeOfDay _selectedStartTime = TimeOfDay.now();
    if (startTime.isNotEmpty && startTime.contains(':')) {
      List<String> parts = startTime.split(':');
      if (parts.length == 2) {
        _selectedStartTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0
        );
      }
    }
    
    TimeOfDay _selectedEndTime = TimeOfDay(hour: TimeOfDay.now().hour + 1, minute: TimeOfDay.now().minute);
    if (endTime.isNotEmpty && endTime.contains(':')) {
      List<String> parts = endTime.split(':');
      if (parts.length == 2) {
        _selectedEndTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0
        );
      }
    }
    
    String _selectedHari = schedule.schedule.hari;
    final List<String> _hariList = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu',
    ];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit Jadwal Tim'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _mataKuliahController,
                    decoration: InputDecoration(
                      labelText: 'Mata Kuliah',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Masukkan mata kuliah';
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedHari,
                    decoration: InputDecoration(
                      labelText: 'Hari',
                      border: OutlineInputBorder(),
                    ),
                    items: _hariList.map((hari) {
                      return DropdownMenuItem(value: hari, child: Text(hari));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedHari = value!;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _startTimeController,
                          decoration: InputDecoration(
                            labelText: 'Waktu Mulai',
                            border: OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.access_time),
                              onPressed: () async {
                                final TimeOfDay? picked = await showTimePicker(
                                  context: context,
                                  initialTime: _selectedStartTime,
                                );
                                if (picked != null) {
                                  setState(() {
                                    _selectedStartTime = picked;
                                    _startTimeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                  });
                                }
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Waktu mulai';
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _endTimeController,
                          decoration: InputDecoration(
                            labelText: 'Waktu Selesai',
                            border: OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.access_time),
                              onPressed: () async {
                                final TimeOfDay? picked = await showTimePicker(
                                  context: context,
                                  initialTime: _selectedEndTime,
                                );
                                if (picked != null) {
                                  setState(() {
                                    _selectedEndTime = picked;
                                    _endTimeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                  });
                                }
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Waktu selesai';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _ruanganController,
                    decoration: InputDecoration(
                      labelText: 'Ruangan',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Masukkan ruangan';
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _dosenController,
                    decoration: InputDecoration(
                      labelText: 'Dosen',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Display team members (read-only in edit mode)
                  Text('Anggota Tim:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...schedule.members.map((member) => ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: Color(0xFFFFD95A),
                      child: Text(
                        member.name[0],
                        style: TextStyle(color: Color(0xFF4A7AB9)),
                      ),
                    ),
                    title: Text(member.name),
                    subtitle: Text(member.role),
                  )).toList(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Create a combined time string from start and end times
                  String waktu = '${_startTimeController.text} - ${_endTimeController.text}';
                  
                  // Update schedule details
                  schedule.schedule.mataKuliah = _mataKuliahController.text;
                  schedule.schedule.hari = _selectedHari;
                  schedule.schedule.waktu = waktu;
                  schedule.schedule.ruangan = _ruanganController.text;
                  schedule.schedule.dosen = _dosenController.text;
                  
                  // Update start and end times
                  schedule.startTime = _startTimeController.text;
                  schedule.endTime = _endTimeController.text;
                  
                  // Get current user ID
                  final user = FirebaseAuth.instance.currentUser;
                  final userId = user?.uid;
                  
                  // Update in database using the proper updateTeamSchedule method
                  DatabaseHelper.instance.updateTeamSchedule(schedule, userId: userId);
                  
                  // Update the UI
                  setState(() {
                    int index = teamSchedules.indexWhere((ts) => ts.id == schedule.id);
                    if (index != -1) {
                      teamSchedules[index] = schedule;
                    }
                  });
                  
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4A7AB9),
              ),
              child: Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteTeamSchedule(TeamSchedule schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Jadwal'),
        content: Text('Apakah Anda yakin ingin menghapus jadwal ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              // Use the new method that doesn't affect jadwal_perkuliahan
              DatabaseHelper.instance.deleteTeamScheduleOnly(schedule);
              setState(() {
                teamSchedules.removeWhere((ts) => 
                  ts.schedule.mataKuliah == schedule.schedule.mataKuliah);
              });
              Navigator.pop(context);
            },
            child: Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // Methods for editing and deleting team schedules
  void _showEditTeamScheduleDialog(TeamSchedule teamSchedule) {
    // Create controllers with existing values
    final startTimeController = TextEditingController(text: teamSchedule.startTime ?? teamSchedule.schedule.startTime);
    final endTimeController = TextEditingController(text: teamSchedule.endTime ?? teamSchedule.schedule.endTime);
    List<TeamMember> editedMembers = List.from(teamSchedule.members);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit Jadwal Tim', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teamSchedule.schedule.mataKuliah,
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text('Waktu Mulai:', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                TextField(
                  controller: startTimeController,
                  decoration: InputDecoration(
                    hintText: 'Contoh: 08:00',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                Text('Waktu Selesai:', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                TextField(
                  controller: endTimeController,
                  decoration: InputDecoration(
                    hintText: 'Contoh: 10:30',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                Text('Anggota Tim:', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                ...editedMembers.map((member) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('${member.name} (${member.role})'),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            editedMembers.remove(member);
                          });
                        },
                      ),
                    ],
                  ),
                )).toList(),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    final nameController = TextEditingController();
                    final roleController = TextEditingController();
                    
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Tambah Anggota', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: nameController,
                              decoration: InputDecoration(
                                labelText: 'Nama',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: 12),
                            TextField(
                              controller: roleController,
                              decoration: InputDecoration(
                                labelText: 'Peran',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Batal'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (nameController.text.isNotEmpty && roleController.text.isNotEmpty) {
                                setState(() {
                                  editedMembers.add(TeamMember(
                                    name: nameController.text,
                                    role: roleController.text,
                                  ));
                                });
                                Navigator.pop(context);
                              }
                            },
                            child: Text('Tambah'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: Icon(Icons.add),
                  label: Text('Tambah Anggota'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4A7AB9),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Update the team schedule
                teamSchedule.startTime = startTimeController.text;
                teamSchedule.endTime = endTimeController.text;
                teamSchedule.members = editedMembers;
                
                // Save to database
                final db = DatabaseHelper.instance;
                await db.updateTeamSchedule(teamSchedule);
                
                // Refresh the UI
                _loadData();
                Navigator.pop(context);
              },
              child: Text('Simpan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4A7AB9),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showDeleteConfirmationDialog(TeamSchedule teamSchedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Jadwal', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus jadwal tim untuk ${teamSchedule.schedule.mataKuliah}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Delete from database
              final db = DatabaseHelper.instance;
              // Using the correct method that accepts a TeamSchedule object
              await db.deleteTeamScheduleOnly(teamSchedule);
              
              // Refresh the UI
              _loadData();
              Navigator.pop(context);
            },
            child: Text('Hapus'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
  
  // Modify the team schedule card to include edit and delete buttons
  // Update the ListView.builder in the team schedules section:
  Widget _buildTeamScheduleCard(TeamSchedule teamSchedule) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    teamSchedule.schedule.mataKuliah,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditTeamScheduleDialog(teamSchedule);
                    } else if (value == 'delete') {
                      _showDeleteConfirmationDialog(teamSchedule);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Hapus'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  teamSchedule.schedule.hari,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  '${teamSchedule.startTime ?? teamSchedule.schedule.startTime} - ${teamSchedule.endTime ?? teamSchedule.schedule.endTime}',
                  style: GoogleFonts.poppins(color: Colors.grey[700]),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  teamSchedule.schedule.ruangan,
                  style: GoogleFonts.poppins(color: Colors.grey[700]),
                ),
              ],
            ),
            Divider(height: 24),
            Text(
              'Anggota Tim:',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            ...teamSchedule.members.map((member) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              leading: CircleAvatar(
                backgroundColor: Color(0xFFFFD95A),
                child: Text(
                  member.name[0],
                  style: TextStyle(color: Color(0xFF4A7AB9)),
                ),
              ),
              title: Text(member.name),
              subtitle: Text(member.role),
            )).toList(),
          ],
        ),
      ),
    );
  }

  // Modify the _findOptimalSchedules method to show loading and results:
  Future<void> _findOptimalSchedules() async {
    // Show processing dialog first and wait for it to be displayed
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // Start the CSP processing after the dialog is shown
        Future.delayed(Duration(milliseconds: 500), () async {
          try {
            // Define domain for days and time slots
            final List<String> days = ["Senin", "Selasa", "Rabu", "Kamis", "Jumat"];
            final List<List<String>> timeSlots = [
              ["07:30", "09:00"], 
              ["09:30", "12:00"], 
              ["13:00", "15:30"], 
              ["15:30", "17:10"]
            ];
            
            // Get current user ID for filtering
            final user = FirebaseAuth.instance.currentUser;
            final userId = user?.uid;
            
            final db = DatabaseHelper.instance;
            // Get schedules filtered by user ID
            final regularSchedules = await db.getAllSchedules(userId: userId);
            final teamSchedules = await db.getAllTeamSchedules(userId: userId);
            
            // Create a map to store each member's busy schedules
            Map<String, List<Map<String, dynamic>>> memberBusySchedules = {};
            
            // Get all team members and ensure current user is included
            Set<String> allMembers = {currentUser}; // Always include current user
            
            // Add other team members from existing team schedules
            for (var teamSchedule in teamSchedules) {
              for (var member in teamSchedule.members) {
                // Only add actual team members, not professors from regular schedules
                if (member.name != currentUser) {
                  allMembers.add(member.name);
                }
              }
            }
            
            // Initialize busy schedules for all members
            for (var member in allMembers) {
              memberBusySchedules[member] = [];
            }
            
            // Add regular schedules as constraints for current user only
            for (var schedule in regularSchedules) {
              memberBusySchedules[currentUser]!.add({
                'day': schedule.hari,
                'startTime': schedule.startTime,
                'endTime': schedule.endTime,
                'location': schedule.ruangan
              });
            }
            
            // Add team schedules as constraints for all members
            for (var teamSchedule in teamSchedules) {
              for (var member in teamSchedule.members) {
                if (memberBusySchedules.containsKey(member.name)) {
                  memberBusySchedules[member.name]!.add({
                    'day': teamSchedule.schedule.hari,
                    'startTime': teamSchedule.startTime ?? teamSchedule.schedule.startTime,
                    'endTime': teamSchedule.endTime ?? teamSchedule.schedule.endTime,
                    'location': teamSchedule.schedule.ruangan
                  });
                }
              }
            }
            
            // Generate all possible day-time slot combinations
            List<Map<String, dynamic>> allPossibleSlots = [];
            for (var day in days) {
              for (var slot in timeSlots) {
                allPossibleSlots.add({
                  'day': day,
                  'startTime': slot[0],
                  'endTime': slot[1]
                });
              }
            }
            
            // Find available members for each time slot
            List<Map<String, dynamic>> availableSlots = [];
            
            for (var slot in allPossibleSlots) {
              String day = slot['day'];
              String startTime = slot['startTime'];
              String endTime = slot['endTime'];
              int startMinutes = _timeToMinutes(startTime);
              int endMinutes = _timeToMinutes(endTime);
              
              // Track available members and their last known location
              List<String> availableMembers = [];
              Map<String, int> locationFrequency = {};
              
              // Check each member's availability for this slot
              for (var member in allMembers) {
                bool isAvailable = true;
                String? lastLocation;
                
                // Check if this slot conflicts with any of the member's busy schedules
                for (var busySlot in memberBusySchedules[member] ?? []) {
                  if (busySlot['day'] == day) {
                    int busyStartMinutes = _timeToMinutes(busySlot['startTime']);
                    int busyEndMinutes = _timeToMinutes(busySlot['endTime']);
                    
                    // Check for time overlap
                    if (!(busyEndMinutes <= startMinutes || busyStartMinutes >= endMinutes)) {
                      isAvailable = false;
                      break;
                    }
                    
                    // Keep track of last location
                    lastLocation = busySlot['location'];
                  }
                }
                
                if (isAvailable) {
                  availableMembers.add(member);
                  if (lastLocation != null) {
                    locationFrequency[lastLocation] = (locationFrequency[lastLocation] ?? 0) + 1;
                  }
                }
              }
              
              // Find optimal location based on frequency
              String? optimalLocation;
              int maxFrequency = 0;
              locationFrequency.forEach((location, frequency) {
                if (frequency > maxFrequency) {
                  maxFrequency = frequency;
                  optimalLocation = location;
                }
              });
              
              // Only add slots with at least one available member
              if (availableMembers.isNotEmpty) {
                availableSlots.add({
                  'day': day,
                  'time': '$startTime-$endTime',
                  'availableMembers': availableMembers,
                  'memberCount': availableMembers.length,
                  'optimalLocation': optimalLocation ?? 'Lokasi belum ditentukan'
                });
              }
            }
            
            // Sort by number of available members (descending)
            availableSlots.sort((a, b) => b['memberCount'].compareTo(a['memberCount']));
            
            // Convert to OptimalSchedule objects
            List<OptimalSchedule> possibleSchedules = [];
            for (var slot in availableSlots) {
              possibleSchedules.add(OptimalSchedule(
                day: slot['day'],
                time: slot['time'],
                location: slot['optimalLocation'],
                members: List<String>.from(slot['availableMembers']),
              ));
            }
            
            // Close the dialog
            Navigator.of(context).pop();
            
            if (possibleSchedules.isEmpty) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Tidak Ada Jadwal Optimal'),
                    content: Text('Tidak ditemukan jadwal yang cocok untuk semua anggota tim. Coba tambahkan lebih banyak slot waktu atau ubah jadwal anggota.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('OK'),
                      ),
                    ],
                  );
                },
              );
            } else {
              // Show selection dialog for optimal schedules
              _showOptimalScheduleSelectionDialog(possibleSchedules);
            }
          } catch (e) {
            // Close the dialog first
            Navigator.of(context).pop();
            
            // Then show error dialog
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Error'),
                  content: Text('Terjadi kesalahan saat mencari jadwal optimal: $e'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK'),
                    ),
                  ],
                );
              },
            );
          }
        });
        
        // Return the dialog widget
        return AlertDialog(
          title: Text('Memproses CSP'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Sedang mencari jadwal optimal menggunakan algoritma Constraint Satisfaction Problem...'),
            ],
          ),
        );
      },
    );
  }

  // Helper method to convert time string to minutes since midnight
  int _timeToMinutes(String timeStr) {
    List<String> parts = timeStr.split(':');
    int hours = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
  }

  // Helper method for CSP algorithm: Forward checking to generate all possible combinations
  List<List<dynamic>> _forwardChecking(List<String> days, List<List<String>> timeSlots, {int currentDayIdx = 0, List<List<dynamic>>? currentCombination, List<List<dynamic>>? results}) {
    currentCombination ??= [];
    results ??= [];

    // If we've processed all days, add the current combination to results
    if (currentDayIdx == days.length) {
      results.add(List.from(currentCombination));
      return results;
    }

    // For each time slot, add it to the current combination and recurse
    for (var slot in timeSlots) {
      currentCombination.add([days[currentDayIdx], slot]);
      _forwardChecking(days, timeSlots, currentDayIdx: currentDayIdx + 1, currentCombination: currentCombination, results: results);
      currentCombination.removeLast();
    }

    return results;
  }
  
  // This method has been moved to line 1055
  
  // Helper method for CSP algorithm: Find optimal meeting times based on member schedules
  Map<String, Map<String, dynamic>> _findGroupMeetingTimes(
      Map<String, List<List<dynamic>>> schedules, List<List<dynamic>> combinations) {
    
    Map<String, Map<String, dynamic>> freeTimes = {};
    
    for (var combination in combinations) {
      for (var item in combination) {
        final day = item[0] as String;
        final timeSlot = item[1] as List<String>;
        final startSlot = timeSlot[0];
        final endSlot = timeSlot[1];
        
        final startMinutes = _timeToMinutes(startSlot);
        final endMinutes = _timeToMinutes(endSlot);
        
        Map<String, int> locationAvailability = {};
        List<String> membersAvailable = [];
        
        // Check each member if they are available
        for (var entry in schedules.entries) {
          final member = entry.key;
          final memberSchedule = entry.value;
          
          bool isAvailable = true;
          String? lastLocation;
          
          for (var schedule in memberSchedule) {
            final scheduleDay = schedule[0] as String;
            final scheduleTime = schedule[1] as String;
            final scheduleLocation = schedule[2] as String;
            
            if (day == scheduleDay) {
              final timeParts = scheduleTime.split('-');
              if (timeParts.length == 2) {
                final scheduleStart = _timeToMinutes(timeParts[0].trim());
                final scheduleEnd = _timeToMinutes(timeParts[1].trim());
                
                // Check if there's a conflict
                if (!(scheduleEnd <= startMinutes || scheduleStart >= endMinutes)) {
                  isAvailable = false;
                  break;
                }
              }
              
              lastLocation = scheduleLocation;
            }
          }
          
          if (isAvailable) {
            membersAvailable.add(member);
            if (lastLocation != null && lastLocation.isNotEmpty) {
              locationAvailability[lastLocation] = (locationAvailability[lastLocation] ?? 0) + 1;
            }
          }
        }
        
        // Find optimal location based on frequency
        String? optimalLocation;
        int maxCount = 0;
        
        locationAvailability.forEach((location, count) {
          if (count > maxCount) {
            maxCount = count;
            optimalLocation = location;
          }
        });
        
        if (membersAvailable.isNotEmpty) {
          final key = '$day|$startSlot-$endSlot';
          freeTimes[key] = {
            'count': membersAvailable.length,
            'members': membersAvailable,
            'optimal_location': optimalLocation,
          };
        }
      }
    }
    
    return freeTimes;
  }

  void _showOptimalScheduleSelectionDialog(List<OptimalSchedule> possibleSchedules) {
    OptimalSchedule? selectedSchedule;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Hasil Algoritma CSP', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              content: Container(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih jadwal optimal yang ingin digunakan:',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    SizedBox(height: 16),
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: possibleSchedules.length,
                        itemBuilder: (context, index) {
                          final schedule = possibleSchedules[index];
                          return RadioListTile<OptimalSchedule>(
                            title: Text(
                              '${schedule.day}, ${schedule.time}',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${schedule.location} (${schedule.members.length} anggota)',
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                            value: schedule,
                            groupValue: selectedSchedule,
                            activeColor: Color(0xFF4A7AB9),
                            onChanged: (OptimalSchedule? value) {
                              setState(() {
                                selectedSchedule = value;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Batal'),
                ),
                ElevatedButton.icon(
                  onPressed: selectedSchedule == null
                    ? null  // Disable if nothing selected
                    : () {
                        // Close the dialog first to prevent setState issues
                        Navigator.pop(context);
                        
                        try {
                          // Dapatkan user_id dari pengguna yang sedang login
                          final user = FirebaseAuth.instance.currentUser;
                          final userId = user?.uid;
                          
                          // First delete any existing selected schedule to avoid accumulation
                          DatabaseHelper.instance.deleteSelectedOptimalSchedule(userId: userId)
                            .then((_) {
                              // Then save the new selected schedule
                              return DatabaseHelper.instance.saveOptimalSchedule(
                                selectedSchedule!,
                                userId: userId
                              );
                            })
                            .then((id) {
                              // Update the UI after database operations are complete
                              setState(() {
                                showOptimalSchedules = false;
                                showSelectedSchedule = true;
                                selectedOptimalSchedule = OptimalSchedule(
                                  id: id,
                                  day: selectedSchedule!.day,
                                  time: selectedSchedule!.time,
                                  location: selectedSchedule!.location,
                                  members: List<String>.from(selectedSchedule!.members), // Create a new list to avoid reference issues
                                  isSelected: true
                                );
                              });
                              
                              print('Successfully saved optimal schedule with ID: $id for user: $userId');
                            })
                            .catchError((error) {
                              print('Error saving optimal schedule: $error');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error saving schedule: $error'))
                              );
                            });
                        } catch (e) {
                          print('Error in schedule selection: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('An error occurred. Please try again.'))
                          );
                        }
                      },
                  icon: Icon(Icons.check_circle),
                  label: Text('Pilih Jadwal Ini', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4A7AB9),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 2,
      body: SafeArea(
        top: true,
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with user greeting - made responsive
              LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 32,
                            height: 32,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            greeting, // Using the real-time greeting function
                            style: GoogleFonts.poppins(
                              fontSize: constraints.maxWidth < 300 ? 10 : 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '$currentUser!',
                            style: GoogleFonts.poppins(
                              fontSize: constraints.maxWidth < 300 ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }
              ),
              SizedBox(height: 24),
              
              // Blue section with title and academic year badge - made responsive
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFF4A7AB9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Text(
                              'Jadwal Kerja Kelompok',
                              style: GoogleFonts.poppins(
                                fontSize: constraints.maxWidth < 300 ? 16 : 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            );
                          }
                        ),
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(0xFFFFD95A),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Tahun Ajaran 2025/2026',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4A7AB9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              
              // Header section with schedule cards
              Container(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: jadwalKuliah.length,
                  itemBuilder: (context, index) {
                    final schedule = jadwalKuliah[index];
                    return Container(
                      width: 180,
                      margin: EdgeInsets.all(8),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF4F7DBF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            schedule.hari,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            schedule.mataKuliah,
                            style: TextStyle(color: Colors.white),
                          ),
                          Text(
                            '${schedule.waktu} - ${schedule.ruangan}',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              // Team Schedules Section
              Container(
                width: double.infinity,
                child: showOptimalSchedules 
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hasil Algoritma CSP',
                          style: GoogleFonts.poppins(
                            fontSize: 20, 
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A7AB9),
                          ),
                        ),
                        SizedBox(height: 16),
                        ...optimalSchedules.map((schedule) => Card(
                          elevation: 3,
                          margin: EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  schedule.day, 
                                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.people, size: 16, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Text(
                                      "${schedule.members.length} Anggota",
                                      style: GoogleFonts.poppins(color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 16, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Text(
                                      'Jam: ${schedule.time}', 
                                      style: GoogleFonts.poppins(color: Colors.grey[700])
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF4A7AB9).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      schedule.location,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF4A7AB9),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )).toList(),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Jadwal Tim Kelompok',
                              style: GoogleFonts.poppins(
                                fontSize: 20, 
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A7AB9),
                              ),
                            ),
                            if (teamSchedules.isNotEmpty)
                              ElevatedButton.icon(
                                onPressed: _showAddScheduleDialog,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF4A7AB9),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                icon: Icon(Icons.add, color: Colors.white, size: 16),
                                label: Text('Tambah', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)),
                              ),
                          ],
                        ),
                        SizedBox(height: 16),
                        if (teamSchedules.isEmpty)
                          Center(
                            child: Column(
                              children: [
                                SizedBox(height: 20),
                                Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
                                SizedBox(height: 16),
                                Text(
                                  'Belum Ada Jadwal!',
                                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
                                ),
                                SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: _showAddScheduleDialog,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF4A7AB9),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  ),
                                  icon: Icon(Icons.add_circle, color: Colors.white),
                                  label: Text('TAMBAHKAN JADWAL TIM', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          )
                        else
                          ...teamSchedules.map((teamSchedule) => _buildTeamScheduleCard(teamSchedule)).toList(),
                      ],
                    ),
              ),
              
              // Button to find optimal schedules
              if (!showOptimalSchedules && !showSelectedSchedule && teamSchedules.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: _findOptimalSchedules,
                  icon: Icon(Icons.search),
                  label: Text('Cari Jadwal Kerkom!', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4A7AB9),
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              
              // Selected optimal schedule section
              if (showSelectedSchedule && selectedOptimalSchedule != null)
                Container(
                  margin: EdgeInsets.only(top: 24),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFD95A),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Color(0xFF4A7AB9)),
                            SizedBox(width: 8),
                            Text(
                              'Hasil Jadwal Tim Terpilih',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A7AB9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Column(
                          children: [
                                  SizedBox(height: 20),
                                  Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
                                  SizedBox(height: 16),
                                  Text(
                                    'Belum Ada Jadwal!',
                                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
                                  ),
                                  SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: _showAddScheduleDialog,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF4A7AB9),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    ),
                                    icon: Icon(Icons.add_circle, color: Colors.white),
                                    label: Text('TAMBAHKAN JADWAL TIM', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          if (!showOptimalSchedules)
                            ...teamSchedules.map((teamSchedule) => 
                              Card(
                                elevation: 3,
                                margin: EdgeInsets.only(bottom: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              teamSchedule.schedule.mataKuliah,
                                              style: GoogleFonts.poppins(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            icon: Icon(Icons.more_vert),
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                _showEditTeamScheduleDialog(teamSchedule);
                                              } else if (value == 'delete') {
                                                _showDeleteConfirmationDialog(teamSchedule);
                                              }
                                            },
                                            itemBuilder: (BuildContext context) => [
                                              PopupMenuItem<String>(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit, color: Colors.blue),
                                                    SizedBox(width: 8),
                                                    Text('Edit'),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuItem<String>(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete, color: Colors.red),
                                                    SizedBox(width: 8),
                                                    Text('Hapus'),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                          SizedBox(width: 4),
                                          Text(
                                            teamSchedule.schedule.hari,
                                            style: GoogleFonts.poppins(
                                              color: Colors.grey[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.access_time, size: 16, color: Colors.grey),
                                          SizedBox(width: 4),
                                          Text(
                                            '${teamSchedule.startTime ?? teamSchedule.schedule.startTime} - ${teamSchedule.endTime ?? teamSchedule.schedule.endTime}',
                                            style: GoogleFonts.poppins(color: Colors.grey[700]),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on, size: 16, color: Colors.grey),
                                          SizedBox(width: 4),
                                          Text(
                                            teamSchedule.schedule.ruangan,
                                            style: GoogleFonts.poppins(color: Colors.grey[700]),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'Anggota Tim:',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: teamSchedule.members.map((member) {
                                          return Container(
                                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Color(0xFFE8F1FF),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: Color(0xFF4A7AB9), width: 1),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                CircleAvatar(
                                                  radius: 10,
                                                  backgroundColor: Color(0xFF4A7AB9),
                                                  child: Text(
                                                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 6),
                                                Text(
                                                  '${member.name} (${member.role})',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF4A7AB9),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ).toList(),
                        ],
                      ),
                ),
                
                // Button to find optimal schedules
                if (!showOptimalSchedules && !showSelectedSchedule && teamSchedules.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: _findOptimalSchedules,
                    icon: Icon(Icons.search),
                    label: Text('Cari Jadwal Kerkom!', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4A7AB9),
                      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                
                // Selected optimal schedule section
                if (showSelectedSchedule && selectedOptimalSchedule != null)
                  Container(
                    margin: EdgeInsets.only(top: 24),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Color(0xFFFFD95A),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Color(0xFF4A7AB9)),
                              SizedBox(width: 8),
                              Text(
                                'Hasil Jadwal Tim Terpilih',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4A7AB9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Color(0xFFFFD95A)),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 18, color: Color(0xFF4A7AB9)),
                                      SizedBox(width: 8),
                                      Text(
                                        selectedOptimalSchedule!.day,
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF4A7AB9).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.access_time, size: 16, color: Color(0xFF4A7AB9)),
                                        SizedBox(width: 4),
                                        Text(
                                          selectedOptimalSchedule!.time,
                                          style: TextStyle(color: Color(0xFF4A7AB9), fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Color(0xFFF5F7FA),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Lokasi:',
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on, size: 16, color: Colors.red),
                                        SizedBox(width: 4),
                                        Text(
                                          selectedOptimalSchedule!.location,
                                          style: GoogleFonts.poppins(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Anggota Tim (${selectedOptimalSchedule!.members.length}):',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                              ),
                              SizedBox(height: 8),
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Color(0xFFF5F7FA),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: selectedOptimalSchedule!.members.map((member) => Padding(
                                    padding: EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor: Color(0xFFFFD95A),
                                          child: Text(
                                            member[0],
                                            style: TextStyle(color: Color(0xFF4A7AB9), fontSize: 12),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(member, style: GoogleFonts.poppins()),
                                      ],
                                    ),
                                  )).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _deleteSelectedOptimalSchedule,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.delete),
                              SizedBox(width: 8),
                              Text('Hapus Jadwal', style: GoogleFonts.poppins()),
                            ],
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Button to go back to team schedules
              if (showOptimalSchedules)
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      showOptimalSchedules = false;
                    });
                  },
                  icon: Icon(Icons.arrow_back),
                  label: Text('Kembali ke Jadwal Tim', style: GoogleFonts.poppins()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4A7AB9),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}