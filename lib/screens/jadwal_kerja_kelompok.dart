import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/main_scaffold.dart';

class TeamSchedule {
  String namaKelompok;
  String mataKuliah;
  String waktu;
  String tempat;
  String ketua;
  String tanggal;

  TeamSchedule({
    required this.namaKelompok,
    required this.mataKuliah,
    required this.waktu,
    required this.tempat,
    required this.ketua,
    required this.tanggal,
  });
}

class JadwalKerjaKelompok extends StatefulWidget {
  @override
  State<JadwalKerjaKelompok> createState() => _JadwalKerjaKelompokState();
}

class _JadwalKerjaKelompokState extends State<JadwalKerjaKelompok> {
  final _formKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController();
  final _membersController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  double _progress = 0.0;
  bool _isEditing = false;
  int? _editingIndex;

  List<TeamSchedule> _teamSchedules = [
    TeamSchedule(
      name: 'Tim UI/UX 1',
      time: TimeOfDay(hour: 10, minute: 0),
      members: 5,
      progress: 0.6,
    ),
    TeamSchedule(
      name: 'Tim Backend',
      time: TimeOfDay(hour: 13, minute: 30),
      members: 4,
      progress: 0.8,
    ),
    TeamSchedule(
      name: 'Tim Frontend',
      time: TimeOfDay(hour: 15, minute: 0),
      members: 3,
      progress: 0.4,
    ),
  ];  Future<void> _selectTime(BuildContext context) async {    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      initialEntryMode: TimePickerEntryMode.input,
      useRootNavigator: true,
      orientation: Orientation.portrait, // Force portrait to hide switch
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteTextStyle: TextStyle(fontSize: 16),
              dayPeriodTextStyle: TextStyle(fontSize: 16),
            ),
          ).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              // Menghilangkan tombol switch mode
              entryModeIconColor: Colors.transparent,
              // Sembunyikan garis pembatas
              dayPeriodBorderSide: BorderSide.none,
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              alwaysUse24HourFormat: true, // Gunakan format 24 jam
            ),
            child: child!,
          ),
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _editTeam(int index) {
    final team = _teamSchedules[index];
    setState(() {
      _isEditing = true;
      _editingIndex = index;
      _teamNameController.text = team.name;
      _membersController.text = team.members.toString();
      _selectedTime = team.time;
      _progress = team.progress;
    });
  }

  void _deleteTeam(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Tim'),
        content: Text('Apakah anda yakin ingin menghapus tim ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _teamSchedules.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tim berhasil dihapus'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _saveTeam() {
    if (_formKey.currentState!.validate()) {
      final newTeam = TeamSchedule(
        name: _teamNameController.text,
        time: _selectedTime,
        members: int.parse(_membersController.text),
        progress: _progress,
      );

      setState(() {
        if (_isEditing && _editingIndex != null) {
          _teamSchedules[_editingIndex!] = newTeam;
        } else {
          _teamSchedules.add(newTeam);
        }
        _resetForm();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Tim berhasil diupdate' : 'Tim berhasil ditambahkan'),
          backgroundColor: Theme.of(context).primaryColor,
        ),
      );
    }
  }

  void _resetForm() {
    _teamNameController.clear();
    _membersController.clear();
    _selectedTime = TimeOfDay.now();
    _progress = 0.0;
    _isEditing = false;
    _editingIndex = null;
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 0,
      title: 'Jadwal Kerja Kelompok',
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () => context.go('/homepage'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Daftar Tim',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),            Container(
              height: 220, // Menambah tinggi container untuk menampung semua konten
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: _teamSchedules.length,
                itemBuilder: (context, index) {
                  final team = _teamSchedules[index];
                  return Container(
                    width: 280,
                    margin: EdgeInsets.only(right: 16),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        onTap: () => _editTeam(index),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      team.name,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline),
                                    color: Colors.red,
                                    onPressed: () => _deleteTeam(index),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  team.time.format(context),
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                '${team.members} Anggota',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Progress: ${(team.progress * 100).toInt()}%',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: team.progress,
                                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).primaryColor,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing ? 'Edit Tim' : 'Tambah Tim Baru',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 24),
                    TextFormField(
                      controller: _teamNameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Tim',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.group_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama tim tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _membersController,
                      decoration: InputDecoration(
                        labelText: 'Jumlah Anggota',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.people_outline),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Jumlah anggota tidak boleh kosong';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Masukkan angka yang valid';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    InkWell(
                      onTap: () => _selectTime(context),
                      child: IgnorePointer(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Waktu',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: Icon(Icons.access_time),
                            suffixIcon: Icon(Icons.arrow_drop_down),
                          ),
                          controller: TextEditingController(
                            text: _selectedTime.format(context),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Progress: ${(_progress * 100).toInt()}%',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    Slider(
                      value: _progress,
                      onChanged: (value) {
                        setState(() {
                          _progress = value;
                        });
                      },
                      activeColor: Theme.of(context).primaryColor,
                    ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        if (_isEditing)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _resetForm,
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text('Batal'),
                            ),
                          ),
                        if (_isEditing)
                          SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveTeam,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(_isEditing ? 'Update' : 'Simpan'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _membersController.dispose();
    super.dispose();
  }
}
