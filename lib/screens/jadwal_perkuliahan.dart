import 'package:flutter/material.dart';
import '../widgets/main_scaffold.dart';
import '../utils/database_helper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Schedule {
  int? id;
  String mataKuliah;
  String waktu;
  String startTime; // Added start time
  String endTime;   // Added end time
  String ruangan;
  String dosen;
  String hari;

  Schedule({
    this.id,
    required this.mataKuliah,
    required this.waktu,
    required this.startTime,
    required this.endTime,
    required this.ruangan,
    required this.dosen,
    required this.hari,
  });
}

class JadwalPerkuliahan extends StatefulWidget {
  const JadwalPerkuliahan({super.key});

  @override
  State<JadwalPerkuliahan> createState() => _JadwalPerkuliahanState();
}

class _JadwalPerkuliahanState extends State<JadwalPerkuliahan> {
  final _formKey = GlobalKey<FormState>();
  final _mataKuliahController = TextEditingController();
  final _ruanganController = TextEditingController();
  final _dosenController = TextEditingController();
  final _waktuController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  TimeOfDay _selectedStartTime = TimeOfDay.now();
  TimeOfDay _selectedEndTime = TimeOfDay(hour: TimeOfDay.now().hour + 1, minute: TimeOfDay.now().minute);
  String _selectedHari = 'Senin';
  bool _isEditing = false;
  int? _editingIndex;
  
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

  final List<String> _hariList = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
  ];

  List<Schedule> jadwalKuliah = [];
  
  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }
  
  Future<void> _loadSchedules() async {
    try {
      final db = DatabaseHelper.instance;
      // Ambil jadwal berdasarkan user_id dari pengguna yang sedang login
      final user = FirebaseAuth.instance.currentUser;
      final schedules = await db.getAllSchedules(userId: user?.uid);
      setState(() {
        jadwalKuliah = schedules;
      });
    } catch (e) {
      print('Error loading schedules: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat jadwal: $e')),
      );
    }
  }
  
  // Modifikasi fungsi _saveSchedule
  void _saveSchedule() {
    if (_formKey.currentState!.validate()) {
      final schedule = Schedule(
        mataKuliah: _mataKuliahController.text,
        waktu: "${_startTimeController.text} - ${_endTimeController.text}",
        startTime: _startTimeController.text,
        endTime: _endTimeController.text,
        ruangan: _ruanganController.text,
        dosen: _dosenController.text,
        hari: _selectedHari,
      );
      
      // Dapatkan user_id dari pengguna yang sedang login
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid;
  
      if (_isEditing && _editingIndex != null) {
        // Update di database
        // Dapatkan user_id dari pengguna yang sedang login
        final user = FirebaseAuth.instance.currentUser;
        final userId = user?.uid;
        
        // Catatan: Perlu menambahkan fungsi updateSchedule di DatabaseHelper
        DatabaseHelper.instance.updateSchedule(jadwalKuliah[_editingIndex!].id!, schedule, userId: userId).then((_) {
          setState(() {
            jadwalKuliah[_editingIndex!] = schedule;
            _resetForm();
            Navigator.pop(context);
          });
        });
      } else {
        // Simpan ke database dengan user_id
        DatabaseHelper.instance.insertSchedule(schedule, userId: userId).then((id) {
          schedule.id = id; // Tambahkan id ke objek schedule
          setState(() {
            jadwalKuliah.add(schedule);
            _resetForm();
            Navigator.pop(context);
          });
        });
      }
    }
  }
  
  // Fungsi delete dengan konfirmasi dialog
  void _deleteSchedule(Schedule schedule) {
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
              // Hapus dari database
              if (schedule.id != null) {
                DatabaseHelper.instance.deleteSchedule(schedule.id!);
              }
              setState(() {
                jadwalKuliah.removeWhere((j) => 
                  j.mataKuliah == schedule.mataKuliah && 
                  j.hari == schedule.hari && 
                  j.startTime == schedule.startTime);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Jadwal berhasil dihapus'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog({Schedule? schedule, int? index}) {
    if (schedule != null) {
      _mataKuliahController.text = schedule.mataKuliah;
      _ruanganController.text = schedule.ruangan;
      _dosenController.text = schedule.dosen;
      _selectedHari = schedule.hari;
      _waktuController.text = schedule.waktu;
      _startTimeController.text = schedule.startTime;
      _endTimeController.text = schedule.endTime;
      _isEditing = true;
      _editingIndex = index;
    } else {
      _resetForm();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isEditing ? 'Edit Jadwal' : 'Tambah Jadwal'),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Mata kuliah tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedHari,
                  decoration: InputDecoration(
                    labelText: 'Hari',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _hariList.map((String hari) {
                    return DropdownMenuItem(
                      value: hari,
                      child: Text(hari),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      _selectedHari = value!;
                    });
                  },
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectStartTime(context),
                        child: IgnorePointer(
                          child: TextFormField(
                            controller: _startTimeController,
                            decoration: InputDecoration(
                              labelText: 'Waktu Mulai',
                              hintText: 'Klik untuk memilih',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(Icons.access_time),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Waktu mulai harus diisi';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectEndTime(context),
                        child: IgnorePointer(
                          child: TextFormField(
                            controller: _endTimeController,
                            decoration: InputDecoration(
                              labelText: 'Waktu Selesai',
                              hintText: 'Klik untuk memilih',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(Icons.access_time),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Waktu selesai harus diisi';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _ruanganController,
                  decoration: InputDecoration(
                    labelText: 'Ruangan',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ruangan tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _dosenController,
                  decoration: InputDecoration(
                    labelText: 'Dosen',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama dosen tidak boleh kosong';
                    }
                    return null;
                  },
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
            onPressed: _saveSchedule,
            child: Text(_isEditing ? 'Update' : 'Simpan'),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _mataKuliahController.clear();
    _ruanganController.clear();
    _dosenController.clear();
    _waktuController.clear();
    _startTimeController.clear();
    _endTimeController.clear();
    _selectedHari = 'Senin';
    _isEditing = false;
    _editingIndex = null;
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 1,
      body: SafeArea(
        bottom: false, // Don't add safe area at bottom since MainScaffold handles that
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User greeting section
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
                          greeting,
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
              },
            ),
            SizedBox(height: 24),
            
            // Blue section with title and academic year badge
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
                            'Jadwal Perkuliahan',
                            style: GoogleFonts.poppins(
                              fontSize: constraints.maxWidth < 300 ? 16 : 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          );
                        },
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
            
            // Day filter chips
            Container(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _hariList.length,
                itemBuilder: (context, index) {
                  final hari = _hariList[index];
                  final isSelected = _selectedHari == hari;
                  return Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(
                        hari,
                        style: GoogleFonts.poppins(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedHari = selected ? hari : 'Senin';
                        });
                      },
                      selectedColor: Color(0xFF4A7AB9).withOpacity(0.2),
                      checkmarkColor: Color(0xFF4A7AB9),
                      backgroundColor: Colors.grey.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? Color(0xFF4A7AB9) : Colors.grey[600],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            
            // Schedule list section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Jadwal Minggu Ini',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A7AB9),
                  ),
                ),
                if (jadwalKuliah.where((j) => j.hari == _selectedHari).isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditDialog(),
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
            
            // Center button when no schedules are available
            if (jadwalKuliah.where((j) => j.hari == _selectedHari).isEmpty)
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
                      onPressed: () => _showAddEditDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4A7AB9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      icon: Icon(Icons.add_circle, color: Colors.white),
                      label: Text('TAMBAHKAN JADWAL', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 16),
            
            // Schedule list
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: jadwalKuliah.where((j) => j.hari == _selectedHari).length,
              itemBuilder: (context, index) {
                final jadwal = jadwalKuliah.where((j) => j.hari == _selectedHari).toList()[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
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
                                    jadwal.mataKuliah,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    jadwal.dosen,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
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
                                      onTap: () => _showAddEditDialog(
                                        schedule: jadwal,
                                        index: index,
                                      ),
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
                                      onTap: () => _deleteSchedule(jadwal),
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
                        Divider(height: 24),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                            SizedBox(width: 8),
                            Text(
                              jadwal.hari,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            SizedBox(width: 16),
                            Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                            SizedBox(width: 8),
                            Text(
                              '${jadwal.startTime} - ${jadwal.endTime}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                            SizedBox(width: 8),
                            Text(
                              jadwal.ruangan,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ),
    );
  }

  @override
  void dispose() {
    _mataKuliahController.dispose();
    _ruanganController.dispose();
    _dosenController.dispose();
    _waktuController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  
  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime,
    );
    if (picked != null && picked != _selectedStartTime) {
      setState(() {
        _selectedStartTime = picked;
        _startTimeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }
  
  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime,
    );
    if (picked != null && picked != _selectedEndTime) {
      setState(() {
        _selectedEndTime = picked;
        _endTimeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }
}
