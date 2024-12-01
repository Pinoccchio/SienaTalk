  import 'package:flutter/material.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:table_calendar/table_calendar.dart';
  import 'package:intl/intl.dart';

  class StudentScheduleView extends StatefulWidget {
    final String studentId;

    const StudentScheduleView({Key? key, required this.studentId}) : super(key: key);

    @override
    _StudentScheduleViewState createState() => _StudentScheduleViewState();
  }

  class _StudentScheduleViewState extends State<StudentScheduleView> {
    CalendarFormat _calendarFormat = CalendarFormat.month;
    DateTime _focusedDay = DateTime.now();
    DateTime? _selectedDay;
    late Stream<QuerySnapshot> _eventsStream;

    @override
    void initState() {
      super.initState();
      _selectedDay = _focusedDay;
      _eventsStream = FirebaseFirestore.instance
          .collection('scheduleRequests')
          .where('studentId', isEqualTo: widget.studentId)
          .snapshots();
    }

    List<Map<String, dynamic>> _getEventsForDay(DateTime day, List<QueryDocumentSnapshot> allEvents) {
      return allEvents.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final eventDate = (data['date'] as Timestamp).toDate();
        return isSameDay(eventDate, day);
      }).map((doc) => doc.data() as Map<String, dynamic>).toList();
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
      return Scaffold(
        appBar: AppBar(
          title: Text('My Schedule'),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _eventsStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final allEvents = snapshot.data!.docs;

            return Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2021, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  eventLoader: (day) => _getEventsForDay(day, allEvents),
                  onDaySelected: _onDaySelected,
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  calendarStyle: CalendarStyle(
                    markerDecoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _selectedDay == null
                      ? Center(child: Text('Select a day to view events'))
                      : _buildEventList(allEvents),
                ),
              ],
            );
          },
        ),
      );
    }

    Widget _buildEventList(List<QueryDocumentSnapshot> allEvents) {
      final events = _getEventsForDay(_selectedDay!, allEvents);
      if (events.isEmpty) {
        return Center(child: Text('No events for this day'));
      }
      return ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: Icon(
                event['isUrgent'] ? Icons.priority_high : Icons.event,
                color: event['isUrgent'] ? Colors.red : null,
              ),
              title: Text(event['reason'] ?? 'No reason provided'),
              subtitle: Text(
                '${_formatTime(event['time'])} - ${event['isUrgent'] ? 'Urgent' : 'Not Urgent'}',
              ),
              trailing: event['isAnonymous']
                  ? Icon(Icons.visibility_off, color: Colors.grey)
                  : null,
            ),
          );
        },
      );
    }

    String _formatTime(String time) {
      final parts = time.split(':');
      if (parts.length != 2) return time;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) return time;
      return DateFormat.jm().format(DateTime(2022, 1, 1, hour, minute));
    }
  }

