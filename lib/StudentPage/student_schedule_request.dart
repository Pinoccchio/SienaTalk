import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import intl package for time formatting

class StudentScheduleRequest extends StatefulWidget {
  final String studentId;

  const StudentScheduleRequest({Key? key, required this.studentId}) : super(key: key);

  @override
  _StudentScheduleRequestState createState() => _StudentScheduleRequestState();
}

class _StudentScheduleRequestState extends State<StudentScheduleRequest> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedReason; // Dropdown value
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isUrgent = false;
  bool _isAnonymous = false;

  // Fetching student name from Firestore
  String _firstName = '';
  String _middleName = '';
  String _lastName = '';

  @override
  void initState() {
    super.initState();
    _fetchStudentDetails();
  }

  // Fetch student details from Firestore
  Future<void> _fetchStudentDetails() async {
    try {
      DocumentSnapshot studentDoc = await FirebaseFirestore.instance
          .collection('students') // Assuming you have a collection called "students"
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

  // Format the time as 12-hour format with AM/PM (e.g., 10:41 PM)
  String _formatTime(TimeOfDay time) {
    final now = DateTime(2022, 1, 1, time.hour, time.minute); // Convert TimeOfDay to DateTime
    return DateFormat.jm().format(now); // Format as 12-hour time with AM/PM
  }

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        await FirebaseFirestore.instance.collection('scheduleRequests').add({
          'studentId': widget.studentId,
          'reason': _selectedReason,
          'date': Timestamp.fromDate(_selectedDate),
          'time': '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}',
          'formattedTime': _formatTime(_selectedTime), // Save the formatted time
          'isUrgent': _isUrgent,
          'isAnonymous': _isAnonymous,
          'createdAt': FieldValue.serverTimestamp(),
          'firstName': _firstName,
          'middleName': _middleName,
          'lastName': _lastName,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request submitted successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate successful submission
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
              // Dropdown for reason
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

              // Date picker
              ListTile(
                title: Text('Date: ${_selectedDate.toLocal()}'.split(' ')[0]),
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

              // Time picker
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

              // Urgent switch
              SwitchListTile(
                title: Text('Urgent'),
                value: _isUrgent,
                onChanged: (bool value) {
                  setState(() {
                    _isUrgent = value;
                  });
                },
              ),

              // Anonymous switch
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

              // Submit button
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
