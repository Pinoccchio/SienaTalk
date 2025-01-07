import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../theme/app_theme.dart';

class SchedulesOverviewPage extends StatefulWidget {
  @override
  _SchedulesOverviewPageState createState() => _SchedulesOverviewPageState();
}

class _SchedulesOverviewPageState extends State<SchedulesOverviewPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late Stream<QuerySnapshot> _eventsStream;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _eventsStream = FirebaseFirestore.instance.collection('scheduleRequests').snapshots();
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day, List<QueryDocumentSnapshot> allEvents) {
    return allEvents.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final eventDate = (data['date'] as Timestamp).toDate();
      return isSameDay(eventDate, day);
    }).map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryRed.withOpacity(0.8), AppTheme.accentYellow.withOpacity(0.8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _eventsStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: AppTheme.pureWhite)));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: AppTheme.pureWhite));
                    }

                    final allEvents = snapshot.data!.docs;

                    return Column(
                      children: [
                        _buildCalendar(allEvents),
                        const SizedBox(height: 16),
                        Expanded(
                          child: _selectedDay == null
                              ? Center(child: Text('Select a day to view events', style: TextStyle(color: AppTheme.pureWhite)))
                              : _buildEventList(allEvents),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Schedules',
            style: TextStyle(
              color: AppTheme.pureWhite,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 48), // To balance the layout
        ],
      ),
    );
  }

  Widget _buildCalendar(List<QueryDocumentSnapshot> allEvents) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: TableCalendar(
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
            color: AppTheme.primaryRed,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: AppTheme.accentYellow.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: AppTheme.primaryRed,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: TextStyle(color: AppTheme.pureWhite),
          todayTextStyle: TextStyle(color: AppTheme.darkGrey),
        ),
        headerStyle: HeaderStyle(
          formatButtonDecoration: BoxDecoration(
            color: AppTheme.accentYellow,
            borderRadius: BorderRadius.circular(16),
          ),
          formatButtonTextStyle: TextStyle(color: AppTheme.primaryRed),
          titleTextStyle: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEventList(List<QueryDocumentSnapshot> allEvents) {
    final events = _getEventsForDay(_selectedDay!, allEvents);
    if (events.isEmpty) {
      return Center(child: Text('No events for this day', style: TextStyle(color: AppTheme.pureWhite)));
    }
    return AnimationLimiter(
      child: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildEventCard(event),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final isAnonymous = event['isAnonymous'] ?? false;
    final fullName = '${event['firstName']} ${event['lastName']} (ID: ${event['studentId']})';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: event['isUrgent'] ? AppTheme.primaryRed : AppTheme.accentYellow,
                  child: Icon(
                    event['isUrgent'] ? Icons.priority_high : Icons.event,
                    color: AppTheme.pureWhite,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    event['reason'] ?? 'No reason provided',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryRed, fontSize: 18),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text('Scheduled by: $fullName', style: TextStyle(color: AppTheme.darkGrey)),
            if (isAnonymous) Text('(Anonymous mode)', style: TextStyle(color: AppTheme.primaryRed, fontStyle: FontStyle.italic)),
            SizedBox(height: 4),
            Text('Time: ${_formatTime(event['time'])}', style: TextStyle(color: AppTheme.darkGrey)),
            SizedBox(height: 4),
            Text(
              'Urgency: ${event['isUrgent'] ? 'Urgent' : 'Not Urgent'}',
              style: TextStyle(
                color: event['isUrgent'] ? AppTheme.primaryRed : AppTheme.darkGrey,
                fontWeight: event['isUrgent'] ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
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

