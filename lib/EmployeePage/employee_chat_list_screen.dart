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

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _getStudentsWithMessageCounts(students),
            builder: (context, studentsWithMessagesSnapshot) {
              if (studentsWithMessagesSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (studentsWithMessagesSnapshot.hasError) {
                return Center(child: Text('Error: ${studentsWithMessagesSnapshot.error}'));
              }

              final studentsWithMessages = studentsWithMessagesSnapshot.data!;
              studentsWithMessages.sort((a, b) => b['nonAnonymousMessageCount'].compareTo(a['nonAnonymousMessageCount']));

              return ListView.builder(
                itemCount: studentsWithMessages.length * 2, // Separate entries for anonymous and non-anonymous
                itemBuilder: (context, index) {
                  final studentIndex = index ~/ 2;
                  final isAnonymousEntry = index.isOdd;
                  final studentData = studentsWithMessages[studentIndex];
                  final firstName = studentData['firstName'] ?? 'Unknown';
                  final lastName = studentData['lastName'] ?? '';
                  final studentId = studentData['id'] ?? 'N/A';
                  final anonymousMessageCount = studentData['anonymousMessageCount'];
                  final nonAnonymousMessageCount = studentData['nonAnonymousMessageCount'];

                  if (isAnonymousEntry && anonymousMessageCount > 0) {
                    return _buildChatListItem(
                      context: context,
                      displayName: 'Anonymous Student',
                      isAnonymous: true,
                      messageCount: anonymousMessageCount,
                      studentId: studentId,
                    );
                  } else if (!isAnonymousEntry && nonAnonymousMessageCount > 0) {
                    return _buildChatListItem(
                      context: context,
                      displayName: '$firstName $lastName',
                      isAnonymous: false,
                      messageCount: nonAnonymousMessageCount,
                      studentId: studentId,
                    );
                  } else {
                    return SizedBox.shrink(); // Hide empty entries
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getStudentsWithMessageCounts(List<QueryDocumentSnapshot> students) async {
    List<Map<String, dynamic>> studentsWithMessages = [];

    for (var student in students) {
      final studentData = student.data() as Map<String, dynamic>;
      final studentId = studentData['id'] ?? 'N/A';
      final chatId = _getChatId(employeeId, studentId);

      final anonymousMessageCount = await _getMessageCount(chatId, true);
      final nonAnonymousMessageCount = await _getMessageCount(chatId, false);

      studentsWithMessages.add({
        ...studentData,
        'anonymousMessageCount': anonymousMessageCount,
        'nonAnonymousMessageCount': nonAnonymousMessageCount,
      });
    }

    return studentsWithMessages;
  }

  String _getChatId(String id1, String id2) {
    final sortedIds = [id1, id2]..sort();
    return sortedIds.join('_');
  }

  Future<int> _getMessageCount(String chatId, bool isAnonymous) async {
    final messagesSnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isNotEqualTo: employeeId)
        .where('isAnonymous', isEqualTo: isAnonymous)
        .get();

    return messagesSnapshot.docs.length;
  }

  Widget _buildChatListItem({
    required BuildContext context,
    required String displayName,
    required bool isAnonymous,
    required int messageCount,
    required String studentId,
  }) {
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
            isAnonymous ? Icons.person_outline : Icons.person,
            color: AppTheme.pureWhite,
          ),
        ),
        title: Text(
          displayName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryRed,
          ),
        ),
        subtitle: Text(
          isAnonymous ? 'Anonymous Messages' : 'Student',
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.accentYellow,
                shape: BoxShape.circle,
              ),
              child: Text(
                messageCount.toString(),
                style: TextStyle(
                  color: AppTheme.primaryRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.primaryRed.withOpacity(0.7),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmployeeVoiceChatScreen(
                employeeId: employeeId,
                chatPartnerId: studentId,
                chatPartnerName: displayName,
                isAnonymous: isAnonymous,
              ),
            ),
          );
        },
      ),
    );
  }
}

