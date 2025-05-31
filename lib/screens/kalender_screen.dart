import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../widgets/main_scaffold.dart';
import '../utils/database_helper.dart';
import 'jadwal_perkuliahan.dart';

class Event {
  final String title;
  final String description;
  final TimeOfDay time;
  final Color color;

  Event({
    required this.title,
    required this.description,
    required this.time,
    required this.color,
  });
}

class KalenderScreen extends StatefulWidget {
  const KalenderScreen({super.key});

  @override
  State<KalenderScreen> createState() => _KalenderScreenState();
}

class _KalenderScreenState extends State<KalenderScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Event>> _events = {};

  // Di dalam class _KalenderScreenState
  
  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }
  
  Future<void> _loadEvents() async {
    try {
      final db = DatabaseHelper.instance;
      final schedules = await db.getAllSchedules();
      final teamSchedules = await db.getAllTeamSchedules();
      
      Map<DateTime, List<Event>> events = {};
      
      // Konversi jadwal kuliah ke events
      for (var schedule in schedules) {
        // Tentukan tanggal berdasarkan hari dalam seminggu
        final dayIndex = _getDayIndex(schedule.hari);
        if (dayIndex != -1) {
          final date = _getNextDayOfWeek(dayIndex);
          
          // Parse waktu dari string format "09:00 - 10:40"
          final timeString = schedule.waktu.split(' - ')[0];
          final timeParts = timeString.split(':');
          final hour = int.tryParse(timeParts[0]) ?? 0;
          final minute = int.tryParse(timeParts[1]) ?? 0;
          
          if (!events.containsKey(date)) {
            events[date] = [];
          }
          
          events[date]!.add(Event(
            title: schedule.mataKuliah,
            description: '${schedule.ruangan} - ${schedule.dosen}',
            time: TimeOfDay(hour: hour, minute: minute),
            color: _getColorForCourse(schedule.mataKuliah),
          ));
        }
      }
      
      // Konversi jadwal tim ke events
      for (var teamSchedule in teamSchedules) {
        final schedule = teamSchedule.schedule;
        final dayIndex = _getDayIndex(schedule.hari);
        if (dayIndex != -1) {
          final date = _getNextDayOfWeek(dayIndex);
          
          final timeString = schedule.waktu.split(' - ')[0];
          final timeParts = timeString.split(':');
          final hour = int.tryParse(timeParts[0]) ?? 0;
          final minute = int.tryParse(timeParts[1]) ?? 0;
          
          if (!events.containsKey(date)) {
            events[date] = [];
          }
          
          events[date]!.add(Event(
            title: 'Kerja Kelompok - ${schedule.mataKuliah}',
            description: '${schedule.ruangan} - ${teamSchedule.members.length} anggota',
            time: TimeOfDay(hour: hour, minute: minute),
            color: Colors.purple,
          ));
        }
      }
      
      setState(() {
        _events = events;
      });
    } catch (e) {
      print('Error loading events: $e');
    }
  }
  
  // Fungsi helper untuk mendapatkan indeks hari
  int _getDayIndex(String day) {
    final days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return days.indexWhere((d) => d.toLowerCase() == day.toLowerCase());
  }
  
  // Fungsi untuk mendapatkan tanggal hari berikutnya dalam seminggu
  DateTime _getNextDayOfWeek(int dayIndex) {
    final now = DateTime.now();
    final daysUntilNext = (dayIndex + 1 - now.weekday) % 7;
    return now.add(Duration(days: daysUntilNext));
  }
  
  // Fungsi helper untuk menentukan warna berdasarkan nama mata kuliah
  Color _getColorForCourse(String courseName) {
    if (courseName.toLowerCase().contains('mobile')) return Colors.blue;
    if (courseName.toLowerCase().contains('data')) return Colors.orange;
    if (courseName.toLowerCase().contains('ai') || 
        courseName.toLowerCase().contains('kecerdasan')) return Colors.green;
    if (courseName.toLowerCase().contains('kelompok')) return Colors.purple;
    return Colors.teal;
  }
  
  List<Event> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 1,
      title: 'Kalender',
      body: Column(
        children: [
          Card(
            margin: EdgeInsets.all(16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(8),
              child: TableCalendar<Event>(
                firstDay: DateTime.utc(2024, 1, 1),
                lastDay: DateTime.utc(2025, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: _getEventsForDay,
                startingDayOfWeek: StartingDayOfWeek.monday,
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  markersMaxCount: 3,
                  markerDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                ),
                onDaySelected: _onDaySelected,
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
              ),
            ),
          ),
          Expanded(
            child: _selectedDay == null
                ? Center(
                    child: Text(
                      'Pilih tanggal untuk melihat jadwal',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _getEventsForDay(_selectedDay!).length,
                    itemBuilder: (context, index) {
                      final event = _getEventsForDay(_selectedDay!)[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          leading: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: event.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.calendar_today,
                              color: event.color,
                            ),
                          ),
                          title: Text(
                            event.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.access_time,
                                      size: 14, color: Colors.grey[600]),
                                  SizedBox(width: 4),
                                  Text(
                                    event.time.format(context),
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  SizedBox(width: 16),
                                  Icon(Icons.location_on,
                                      size: 14, color: Colors.grey[600]),
                                  SizedBox(width: 4),
                                  Text(
                                    event.description,
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
          ),
          if (_selectedDay != null)
            Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement add event
                  },
                  icon: Icon(Icons.add),
                  label: Text('Tambah Jadwal Baru'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
