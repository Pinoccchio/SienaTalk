import 'package:flutter/material.dart';

class ScheduleRequest extends StatefulWidget {
  @override
  _ScheduleRequestState createState() => _ScheduleRequestState();
}

class _ScheduleRequestState extends State<ScheduleRequest> {
  final _formKey = GlobalKey<FormState>();
  String _reason = 'Meeting';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _urgency = 'Normal';
  bool _isAnonymous = false;

  final List<String> _reasons = ['Meeting', 'Training', 'Urgent', 'Other'];
  final List<String> _urgencyLevels = ['Low', 'Normal', 'High', 'Urgent'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Submit Schedule Request'),
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
                value: _reason,
                items: _reasons.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _reason = newValue!;
                  });
                },
              ),
              SizedBox(height: 16),
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
              ListTile(
                title: Text('Time: ${_selectedTime.format(context)}'),
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
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Urgency level',
                  border: OutlineInputBorder(),
                ),
                value: _urgency,
                items: _urgencyLevels.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _urgency = newValue!;
                  });
                },
              ),
              SizedBox(height: 16),
              SwitchListTile(
                title: Text('Submit Anonymously'),
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
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // TODO: Implement request submission
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Schedule request submitted')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

