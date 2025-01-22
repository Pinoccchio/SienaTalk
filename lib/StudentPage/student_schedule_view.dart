import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'student_schedule_request.dart';

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
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _selectedDay = _focusedDay;
    _eventsStream = FirebaseFirestore.instance
        .collection('scheduleRequests')
        .where('studentId', isEqualTo: widget.studentId)
        .snapshots();
    _loadEvents();
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  void _loadEvents() {
    _eventsStream.listen((snapshot) {
      if (!_isMounted) return;
      final allEvents = snapshot.docs;
      final newEvents = <DateTime, List<Map<String, dynamic>>>{};
      for (var doc in allEvents) {
        final data = doc.data() as Map<String, dynamic>;
        final eventDate = (data['date'] as Timestamp).toDate();
        final day = DateTime(eventDate.year, eventDate.month, eventDate.day);
        if (newEvents[day] == null) newEvents[day] = [];
        newEvents[day]!.add(data);
      }
      if (_isMounted) {
        setState(() {
          _events = newEvents;
        });
      }
    });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay) && !selectedDay.isBefore(DateTime.now())) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  Future<void> _showScheduleConflictDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Schedule Conflict'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('This day already has a scheduled event.'),
                Text('Please choose another day or time for your schedule.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _addNewSchedule() async {
    if (_selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a day first')),
      );
      return;
    }

    if (_selectedDay!.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot book for past dates')),
      );
      return;
    }

    final eventsOnSelectedDay = _getEventsForDay(_selectedDay!);
    if (eventsOnSelectedDay.isNotEmpty) {
      await _showScheduleConflictDialog();
    } else {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StudentScheduleRequest(
            studentId: widget.studentId,
            initialDate: _selectedDay!,
          ),
        ),
      );

      if (result == true) {
        _loadEvents();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Schedule'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            onDaySelected: _onDaySelected,
            onFormatChanged: (format) {
              if (_isMounted) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            calendarStyle: CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
            ),
            enabledDayPredicate: (day) => !day.isBefore(DateTime.now()),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _selectedDay == null
                ? Center(child: Text('Select a day to view events'))
                : _buildEventList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewSchedule,
        child: Icon(Icons.add),
        tooltip: 'Add new schedule',
      ),
    );
  }

  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay!);
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

