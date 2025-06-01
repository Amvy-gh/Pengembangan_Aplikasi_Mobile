import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../widgets/main_scaffold.dart';
import '../utils/database_helper.dart';

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
  TimeOfDay _selectedTime = TimeOfDay.now();
  TimeOfDay _selectedStartTime = TimeOfDay.now();
  TimeOfDay _selectedEndTime = TimeOfDay(hour: TimeOfDay.now().hour + 1, minute: TimeOfDay.now().minute);
  String _selectedHari = 'Senin';
  bool _isEditing = false;
  int? _editingIndex;

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
      final schedules = await db.getAllSchedules();
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
  
      if (_isEditing && _editingIndex != null) {
        // Update di database
        // Catatan: Perlu menambahkan fungsi updateSchedule di DatabaseHelper
        DatabaseHelper.instance.updateSchedule(jadwalKuliah[_editingIndex!].id!, schedule).then((_) {
          setState(() {
            jadwalKuliah[_editingIndex!] = schedule;
            _resetForm();
            Navigator.pop(context);
          });
        });
      } else {
        // Simpan ke database
        DatabaseHelper.instance.insertSchedule(schedule).then((id) {
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
  
  // Tambahkan fungsi delete
  void _deleteSchedule(int index) {
    // Hapus dari database
    DatabaseHelper.instance.deleteSchedule(jadwalKuliah[index].id!).then((_) {
      setState(() {
        jadwalKuliah.removeAt(index);
      });
    });
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
  Widget build(BuildContext context) {    return MainScaffold(
      currentIndex: 1,
      title: 'Jadwal Perkuliahan',
      actions: [
        IconButton(
          icon: Icon(Icons.add),
          onPressed: () => _showAddEditDialog(),
          tooltip: 'Tambah Jadwal',
        ),
        IconButton(
          icon: Icon(Icons.file_upload),
          onPressed: () async {
            FilePickerResult? result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['pdf', 'xlsx'],
            );
            if (result != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('File berhasil diupload: ${result.files.single.name}'),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              );
            }
          },
          tooltip: 'Import Jadwal',
        ),
      ],
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () => context.go('/homepage'),
      ),      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 60,
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                      label: Text(hari),
                      onSelected: (selected) {
                        setState(() {
                          _selectedHari = selected ? hari : 'Senin';
                        });
                      },
                      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                      checkmarkColor: Theme.of(context).primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jadwal Minggu Ini',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: jadwalKuliah.where((j) => j.hari == _selectedHari).length,
                    itemBuilder: (context, index) {
                      final jadwal = jadwalKuliah.where((j) => j.hari == _selectedHari).toList()[index];return Dismissible(
                        key: Key(jadwal.mataKuliah),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20),
                          child: Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          bool? result = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Hapus Jadwal'),
                              content: Text('Apakah anda yakin ingin menghapus jadwal ini?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text('Batal'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context, true);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Jadwal berhasil dihapus'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  },
                                  child: Text('Hapus', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (result == true) {
                            setState(() {
                              jadwalKuliah.removeAt(index);
                            });
                          }
                          return result ?? false;
                        },
                        child: Card(
                          margin: EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            onTap: () => _showAddEditDialog(
                              schedule: jadwal,
                              index: index,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .primaryColor
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.school,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              jadwal.mataKuliah,
                                              style: TextStyle(
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
                                      IconButton(
                                        icon: Icon(Icons.edit),
                                        onPressed: () => _showAddEditDialog(
                                          schedule: jadwal,
                                          index: index,
                                        ),
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ],
                                  ),
                                  Divider(height: 24),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today,
                                          size: 16, color: Colors.grey[600]),
                                      SizedBox(width: 8),
                                      Text(
                                        jadwal.hari,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Icon(Icons.access_time,
                                          size: 16, color: Colors.grey[600]),
                                      SizedBox(width: 8),
                                      Text(
                                        '${jadwal.startTime} - ${jadwal.endTime}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on,
                                          size: 16, color: Colors.grey[600]),
                                      SizedBox(width: 8),
                                      Text(
                                        jadwal.ruangan,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
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

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _waktuController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
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
