import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sienatalk/theme/app_theme.dart';
import 'package:sienatalk/EmployeePage/employee_voice_chat_screen.dart';

class EmployeeChatListScreen extends StatelessWidget {
  final String employeeId;

  EmployeeChatListScreen({required this.employeeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student List'),
        backgroundColor: AppTheme.primaryRed,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('students').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No students found'));
          }

          final students = snapshot.data!.docs;

          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final studentData = students[index].data() as Map<String, dynamic>;
              final firstName = studentData['firstName'] ?? 'Unknown';
              final lastName = studentData['lastName'] ?? '';
              final studentId = studentData['id'] ?? 'N/A';

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryRed,
                    child: Icon(
                      Icons.person,
                      color: AppTheme.pureWhite,
                    ),
                  ),
                  title: Text(
                    '$firstName $lastName',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryRed,
                    ),
                  ),
                  subtitle: Text(
                    'Student',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: AppTheme.primaryRed.withOpacity(0.7),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EmployeeVoiceChatScreen(
                          employeeId: employeeId,
                          chatPartnerId: studentId,
                          chatPartnerName: '$firstName $lastName',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
