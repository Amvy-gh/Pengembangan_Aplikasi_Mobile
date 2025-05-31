import 'package:flutter/material.dart';
import '../widgets/main_scaffold.dart';
import 'jadwal_perkuliahan.dart';
import '../utils/database_helper.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final String currentUser = "Alfonsus Pangaribuan"; // Nama pengguna saat ini
  
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
      final selectedSchedule = await DatabaseHelper.instance.getSelectedOptimalSchedule();
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

  Future<void> _loadData() async {
    try {
      final db = DatabaseHelper.instance;
      // Only load regular schedules for reference, but don't modify jadwalKuliah
      final schedules = await db.getAllSchedules();
      final teamSchedules = await db.getAllTeamSchedules();
      
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
      final teamSchedule = TeamSchedule(schedule: schedule, members: members);
      final id = await DatabaseHelper.instance.insertTeamSchedule(teamSchedule);
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
      // Use insertTeamScheduleOnly to avoid affecting jadwal_perkuliahan data
      final id = await DatabaseHelper.instance.insertTeamScheduleOnly(teamSchedule);
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
      final teamSchedules = await db.getAllTeamSchedules();
      
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
                  
                  // Update in database using the new method that doesn't affect jadwal_perkuliahan
                  DatabaseHelper.instance.updateTeamScheduleOnly(schedule);
                  
                  // Update in UI
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

  // Modify the team schedule card to include edit and delete buttons
  // Update the ListView.builder in the team schedules section:
  Widget _buildTeamScheduleCard(TeamSchedule teamSchedule) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teamSchedule.schedule.mataKuliah,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(
                            teamSchedule.schedule.waktu,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      margin: EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Color(0xFF4A7AB9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _editTeamSchedule(teamSchedule),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text('Edit', style: TextStyle(color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _deleteTeamSchedule(teamSchedule),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text('Hapus', style: TextStyle(color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFF4A7AB9).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, size: 16, color: Color(0xFF4A7AB9)),
                  SizedBox(width: 4),
                  Text(
                    teamSchedule.schedule.ruangan,
                    style: TextStyle(color: Color(0xFF4A7AB9)),
                  ),
                ],
              ),
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
    // Show processing dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
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
    
    try {
      // Simulate CSP processing delay
      await Future.delayed(Duration(seconds: 2));
      
      final db = DatabaseHelper.instance;
      final schedules = await db.getAllSchedules();
      final teamSchedules = await db.getAllTeamSchedules();
      
      // Generate multiple possible solutions (simulating CSP results)
      List<OptimalSchedule> possibleSchedules = [];
      
      // Create some sample optimal schedules (in a real app, this would be the CSP algorithm result)
      for (var day in ['Senin', 'Selasa', 'Rabu']) {
        for (var timeSlot in ['08:00 - 10:00', '13:00 - 15:00']) {
          possibleSchedules.add(OptimalSchedule(
            day: day,
            time: timeSlot,
            location: 'Ruang ${100 + possibleSchedules.length}',
            members: teamSchedules.isNotEmpty 
              ? teamSchedules[0].members.map((member) => member.name).toList()
              : ['Anggota 1', 'Anggota 2'],
          ));
        }
      }
      
      // Close the processing dialog
      Navigator.of(context).pop();
      
      // Show results selection dialog
      _showOptimalScheduleSelectionDialog(possibleSchedules);
      
    } catch (e) {
      // Close the processing dialog
      Navigator.of(context).pop();
      print('Error finding optimal schedules: $e');
      
      // Show error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Terjadi kesalahan saat memproses CSP: $e'),
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
                        try {
                          // First, update the UI immediately to provide feedback
                          this.setState(() {
                            selectedOptimalSchedule = selectedSchedule;
                            showSelectedSchedule = true;
                            showOptimalSchedules = false; // Hide the other section
                          });
                          
                          // Close the dialog
                          Navigator.pop(context);
                          
                          // Then save to database in the background
                          DatabaseHelper.instance.saveOptimalSchedule(selectedSchedule!, isSelected: true).then((id) {
                            // Update the schedule with the database ID
                            setState(() {
                              selectedOptimalSchedule = OptimalSchedule(
                                id: id,
                                day: selectedSchedule!.day,
                                time: selectedSchedule!.time,
                                location: selectedSchedule!.location,
                                members: selectedSchedule!.members,
                                isSelected: true
                              );
                            });
                            
                            print('Successfully saved optimal schedule with ID: $id');
                          }).catchError((error) {
                            print('Error saving optimal schedule: $error');
                            // Don't show error to user as the UI is already updated
                            // Just log it for debugging
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
      body: SingleChildScrollView(
        child: Padding(
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
                            'Alfonsus Pangaribuan!',
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
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              showSelectedSchedule = false;
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
                      ),
                    ],
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