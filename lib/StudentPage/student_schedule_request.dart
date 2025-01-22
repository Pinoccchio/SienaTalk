import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StudentScheduleRequest extends StatefulWidget {
  final String studentId;
  final DateTime initialDate;

  const StudentScheduleRequest({
    Key? key,
    required this.studentId,
    required this.initialDate,
  }) : super(key: key);

  @override
  _StudentScheduleRequestState createState() => _StudentScheduleRequestState();
}

class _StudentScheduleRequestState extends State<StudentScheduleRequest> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedReason;
  late DateTime _selectedDate;
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isUrgent = false;
  bool _isAnonymous = false;

  String _firstName = '';
  String _middleName = '';
  String _lastName = '';

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _fetchStudentDetails();
  }

  Future<void> _fetchStudentDetails() async {
    try {
      DocumentSnapshot studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.studentId)
          .get();

      if (studentDoc.exists) {
        setState(() {
          _firstName = studentDoc['firstName'] ?? '';
          _middleName = studentDoc['middleName'] ?? '';
          _lastName = studentDoc['lastName'] ?? '';
        });
      }
    } catch (e) {
      print('Error fetching student details: $e');
    }
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime(2022, 1, 1, time.hour, time.minute);
    return DateFormat.jm().format(now);
  }

  Future<bool> _checkExistingSchedule() async {
    final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    final existingSchedules = await FirebaseFirestore.instance
        .collection('scheduleRequests')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    return existingSchedules.docs.isNotEmpty;
  }

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        // Check for existing schedules on the selected date
        bool hasExistingSchedule = await _checkExistingSchedule();

        if (hasExistingSchedule) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('This date is already booked. Please choose another date.')),
          );
          return;
        }

        await FirebaseFirestore.instance.collection('scheduleRequests').add({
          'studentId': widget.studentId,
          'reason': _selectedReason,
          'date': Timestamp.fromDate(_selectedDate),
          'time': '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}',
          'formattedTime': _formatTime(_selectedTime),
          'isUrgent': _isUrgent,
          'isAnonymous': _isAnonymous,
          'createdAt': FieldValue.serverTimestamp(),
          'firstName': _firstName,
          'middleName': _middleName,
          'lastName': _lastName,
          'isNewForEmployee': true,
          'isNewForAdmin': true,
          'isNewForStudent': true,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request submitted successfully')),
        );
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting request: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Schedule Request'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Reason for scheduling',
                  border: OutlineInputBorder(),
                ),
                value: _selectedReason,
                items: <String>[
                  'Urgent Appointment',
                  'Follow-up Discussion',
                  'Academic Support',
                  'Project Guidance',
                  'Consultation',
                ].map((reason) {
                  return DropdownMenuItem<String>(
                    value: reason,
                    child: Text(reason),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedReason = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a reason';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              ListTile(
                title: Text('Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                  );
                  if (picked != null && picked != _selectedDate) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
              ),
              ListTile(
                title: Text('Time: ${_formatTime(_selectedTime)}'),
                trailing: Icon(Icons.access_time),
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                  );
                  if (picked != null && picked != _selectedTime) {
                    setState(() {
                      _selectedTime = picked;
                    });
                  }
                },
              ),
              SwitchListTile(
                title: Text('Urgent'),
                value: _isUrgent,
                onChanged: (bool value) {
                  setState(() {
                    _isUrgent = value;
                  });
                },
              ),
              SwitchListTile(
                title: Text('Anonymous'),
                value: _isAnonymous,
                onChanged: (bool value) {
                  setState(() {
                    _isAnonymous = value;
                  });
                },
              ),
              SizedBox(height: 24),
              ElevatedButton(
                child: Text('Submit Request'),
                onPressed: _submitRequest,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

