import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../widgets/main_scaffold.dart';

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
  @override
  State<KalenderScreen> createState() => _KalenderScreenState();
}

class _KalenderScreenState extends State<KalenderScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Event>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // Example events
    _events = {
      DateTime.now(): [
        Event(
          title: 'Pemrograman Mobile',
          description: 'Lab Komputer 3',
          time: TimeOfDay(hour: 9, minute: 0),
          color: Colors.blue,
        ),
        Event(
          title: 'Basis Data Lanjut',
          description: 'Ruang 302',
          time: TimeOfDay(hour: 11, minute: 0),
          color: Colors.orange,
        ),
      ],
      DateTime.now().add(Duration(days: 1)): [
        Event(
          title: 'Kerja Kelompok UI/UX',
          description: 'Online Meeting',
          time: TimeOfDay(hour: 14, minute: 0),
          color: Colors.purple,
        ),
      ],
    };
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
