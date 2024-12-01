import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sienatalk/theme/app_theme.dart';
import 'package:sienatalk/StudentPage/voice_chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  final String studentId;

  ChatListScreen({required this.studentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Employee and Admin List'),
        backgroundColor: AppTheme.primaryRed,
      ),
      body: FutureBuilder<List<QuerySnapshot>>(
        future: Future.wait([
          FirebaseFirestore.instance.collection('admins').get(),
          FirebaseFirestore.instance.collection('employees').get(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No records found'));
          }

          final combinedData = [
            ...snapshot.data![0].docs.map((doc) => {'data': doc.data() as Map<String, dynamic>, 'isAdmin': true}),
            ...snapshot.data![1].docs.map((doc) => {'data': doc.data() as Map<String, dynamic>, 'isAdmin': false}),
          ];

          return ListView.builder(
            itemCount: combinedData.length,
            itemBuilder: (context, index) {
              final record = combinedData[index];
              final data = record['data'] as Map<String, dynamic>;
              final isAdmin = record['isAdmin'] as bool;

              final firstName = data['firstName'] ?? 'Unknown';
              final lastName = data['lastName'] ?? '';
              final id = data['id'] ?? 'N/A';

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: isAdmin ? AppTheme.primaryRed : AppTheme.accentYellow,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isAdmin ? AppTheme.accentYellow : AppTheme.primaryRed,
                    child: Icon(
                      isAdmin ? Icons.admin_panel_settings : Icons.person,
                      color: AppTheme.pureWhite,
                    ),
                  ),
                  title: Text(
                    '$firstName $lastName',
                    style: TextStyle(
                      color: AppTheme.pureWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    isAdmin ? 'Admin' : 'Employee',
                    style: TextStyle(
                      color: AppTheme.pureWhite.withOpacity(0.7),
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: AppTheme.pureWhite.withOpacity(0.7),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VoiceChatScreen(
                          studentId: studentId,
                          chatPartnerId: id,
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