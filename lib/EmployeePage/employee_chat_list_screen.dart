import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sienatalk/theme/app_theme.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'employee_voice_chat_screen.dart';

class EmployeeChatListScreen extends StatelessWidget {
  final String employeeId;

  EmployeeChatListScreen({required this.employeeId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Student Chats', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: AppTheme.primaryRed,
          elevation: 0,
          bottom: TabBar(
            tabs: [
              Tab(child: Text('Regular Chats', style: TextStyle(color: Colors.white))),
              Tab(child: Text('Anonymous Chats', style: TextStyle(color: Colors.white))),
            ],
            indicatorColor: Colors.white,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
        ),
        body: TabBarView(
          children: [
            _ChatList(employeeId: employeeId, isAnonymous: false),
            _ChatList(employeeId: employeeId, isAnonymous: true),
          ],
        ),
      ),
    );
  }
}

class _ChatList extends StatelessWidget {
  final String employeeId;
  final bool isAnonymous;

  const _ChatList({
    Key? key,
    required this.employeeId,
    required this.isAnonymous,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('students').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppTheme.primaryRed));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: AppTheme.primaryRed)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No students found', style: TextStyle(color: AppTheme.primaryRed)));
        }

        final students = snapshot.data!.docs;

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _getStudentsWithMessageCounts(students),
          builder: (context, studentsWithMessagesSnapshot) {
            if (studentsWithMessagesSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: AppTheme.primaryRed));
            }

            if (studentsWithMessagesSnapshot.hasError) {
              return Center(child: Text('Error: ${studentsWithMessagesSnapshot.error}', style: TextStyle(color: AppTheme.primaryRed)));
            }

            final studentsWithMessages = studentsWithMessagesSnapshot.data!
                .where((student) => student['hasMessages'] == true)
                .toList();

            studentsWithMessages.sort((a, b) => (b['totalMessageCount'] as int).compareTo(a['totalMessageCount'] as int));

            if (studentsWithMessages.isEmpty) {
              return Center(
                child: Text(
                  isAnonymous ? 'No anonymous chats yet' : 'No regular chats yet',
                  style: TextStyle(color: AppTheme.primaryRed),
                ),
              );
            }

            return AnimationLimiter(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 16),
                itemCount: studentsWithMessages.length,
                itemBuilder: (context, index) {
                  final studentData = studentsWithMessages[index];
                  final firstName = studentData['firstName'] as String? ?? 'Unknown';
                  final lastName = studentData['lastName'] as String? ?? '';
                  final studentId = studentData['id'] as String? ?? 'N/A';
                  final anonymousName = studentData['anonymousName'] as String? ?? 'Anonymous';
                  final displayName = isAnonymous ? anonymousName : '$firstName $lastName';
                  final totalMessageCount = studentData['totalMessageCount'] as int;

                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: _buildChatListItem(
                          context: context,
                          displayName: displayName,
                          studentId: studentId,
                          totalMessageCount: totalMessageCount,
                          isAnonymous: isAnonymous,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getStudentsWithMessageCounts(List<QueryDocumentSnapshot> students) async {
    List<Map<String, dynamic>> studentsWithMessages = [];

    for (var student in students) {
      final studentData = student.data() as Map<String, dynamic>;
      final studentId = studentData['id'] as String? ?? 'N/A';

      // Ensure employeeId is a String
      final List<String> ids = [employeeId, studentId];
      ids.sort(); // Sort the list

      final chatId = isAnonymous
          ? 'anonymous_${ids.join('_')}'
          : ids.join('_'); // Join sorted ids

      final messageCount = await _getMessageCount(chatId);

      if (messageCount > 0) {
        studentsWithMessages.add({
          ...studentData,
          'totalMessageCount': messageCount,
          'hasMessages': true,
        });
      }
    }

    return studentsWithMessages;
  }

  Future<int> _getMessageCount(String chatId) async {
    final messagesSnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isNotEqualTo: employeeId)
        .get();

    return messagesSnapshot.docs.length;
  }

  Widget _buildChatListItem({
    required BuildContext context,
    required String displayName,
    required String studentId,
    required int totalMessageCount,
    required bool isAnonymous,
  }) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmployeeVoiceChatScreen(
                employeeId: employeeId,
                chatPartnerId: studentId,
                chatPartnerName: displayName,
                isAnonymousChat: isAnonymous,
              ),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              _buildAvatar(isAnonymous, displayName),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppTheme.primaryRed,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Total Messages: $totalMessageCount',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppTheme.primaryRed),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isAnonymous, String displayName) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: isAnonymous ? Colors.grey : AppTheme.primaryRed,
      child: Text(
        displayName[0].toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

