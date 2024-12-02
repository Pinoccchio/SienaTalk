import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sienatalk/theme/app_theme.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'employee_voice_chat_screen.dart';

class EmployeeChatListScreen extends StatelessWidget {
  final String employeeId;

  EmployeeChatListScreen({required this.employeeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Chats', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryRed,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
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

              final studentsWithMessages = studentsWithMessagesSnapshot.data!;
              studentsWithMessages.sort((a, b) => (b['totalMessageCount'] as int).compareTo(a['totalMessageCount'] as int));

              return AnimationLimiter(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  itemCount: studentsWithMessages.length,
                  itemBuilder: (context, index) {
                    final studentData = studentsWithMessages[index];
                    final firstName = studentData['firstName'] ?? 'Unknown';
                    final lastName = studentData['lastName'] ?? '';
                    final studentId = studentData['id'] ?? 'N/A';
                    final anonymousMessageCount = studentData['anonymousMessageCount'] as int;
                    final nonAnonymousMessageCount = studentData['nonAnonymousMessageCount'] as int;
                    final totalMessageCount = anonymousMessageCount + nonAnonymousMessageCount;

                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: _buildChatListItem(
                            context: context,
                            displayName: '$firstName $lastName',
                            studentId: studentId,
                            anonymousMessageCount: anonymousMessageCount,
                            nonAnonymousMessageCount: nonAnonymousMessageCount,
                            totalMessageCount: totalMessageCount,
                            isAnonymous: studentData['isAnonymous'] ?? false,
                            avatarUrl: studentData['avatarUrl'],
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
        'totalMessageCount': anonymousMessageCount + nonAnonymousMessageCount,
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
    required String studentId,
    required int anonymousMessageCount,
    required int nonAnonymousMessageCount,
    required int totalMessageCount,
    required bool isAnonymous,
    String? avatarUrl,
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
                chatPartnerName: isAnonymous ? 'Anonymous Student' : displayName,
              ),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              _buildAvatar(isAnonymous, displayName, avatarUrl),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAnonymous ? 'Anonymous Student' : displayName,
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
              Column(
                children: [
                  _buildMessageCountBadge('A', anonymousMessageCount, Colors.grey),
                  SizedBox(height: 4),
                  _buildMessageCountBadge('N', nonAnonymousMessageCount, AppTheme.accentYellow),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isAnonymous, String displayName, String? avatarUrl) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: isAnonymous ? Colors.grey : AppTheme.primaryRed,
      child: isAnonymous
          ? Icon(Icons.person_outline, color: Colors.white, size: 32)
          : (avatarUrl != null && avatarUrl.isNotEmpty
          ? ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl,
          placeholder: (context, url) => CircularProgressIndicator(color: Colors.white),
          errorWidget: (context, url, error) => Text(
            displayName[0].toUpperCase(),
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      )
          : Text(
        displayName[0].toUpperCase(),
        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
      )),
    );
  }

  Widget _buildMessageCountBadge(String label, int count, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 4),
          Text(
            count.toString(),
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}


