import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sienatalk/theme/app_theme.dart';
import 'package:sienatalk/AdminPage/admin_chat_view_screen.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AdminChatOverviewScreen extends StatelessWidget {
  const AdminChatOverviewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Chats Overview', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryRed,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('employees').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppTheme.primaryRed));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: AppTheme.primaryRed)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No employees found', style: TextStyle(color: AppTheme.primaryRed)));
          }

          final employees = snapshot.data!.docs;

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _getEmployeesWithStudentChats(employees),
            builder: (context, employeesWithChatsSnapshot) {
              if (employeesWithChatsSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: AppTheme.primaryRed));
              }
              if (employeesWithChatsSnapshot.hasError) {
                return Center(child: Text('Error: ${employeesWithChatsSnapshot.error}', style: TextStyle(color: AppTheme.primaryRed)));
              }

              final employeesWithChats = employeesWithChatsSnapshot.data!;
              return AnimationLimiter(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  itemCount: employeesWithChats.length,
                  itemBuilder: (context, index) {
                    final employeeData = employeesWithChats[index];
                    final firstName = employeeData['firstName'] ?? 'Unknown';
                    final lastName = employeeData['lastName'] ?? '';
                    final employeeId = employeeData['id'] ?? 'N/A';
                    final studentChats = employeeData['studentChats'] as List<Map<String, dynamic>>;

                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: _buildEmployeeChatList(
                            context: context,
                            employeeName: '$firstName $lastName',
                            employeeId: employeeId,
                            studentChats: studentChats,
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

  Future<List<Map<String, dynamic>>> _getEmployeesWithStudentChats(List<QueryDocumentSnapshot> employees) async {
    List<Map<String, dynamic>> employeesWithChats = [];

    for (var employee in employees) {
      final employeeData = employee.data() as Map<String, dynamic>;
      final employeeId = employeeData['id'] ?? 'N/A';

      final studentsSnapshot = await FirebaseFirestore.instance.collection('students').get();
      List<Map<String, dynamic>> studentChats = [];

      for (var student in studentsSnapshot.docs) {
        final studentData = student.data();
        final studentId = studentData['id'] ?? 'N/A';
        final regularChatId = _getChatId(employeeId, studentId);
        final anonymousChatId = 'anonymous_${_getChatId(employeeId, studentId)}';

        final regularMessageCount = await _getMessageCount(regularChatId);
        final anonymousMessageCount = await _getMessageCount(anonymousChatId);

        if (regularMessageCount > 0 || anonymousMessageCount > 0) {
          studentChats.add({
            ...studentData,
            'regularMessageCount': regularMessageCount,
            'anonymousMessageCount': anonymousMessageCount,
          });
        }
      }

      employeesWithChats.add({
        ...employeeData,
        'studentChats': studentChats,
      });
    }

    return employeesWithChats;
  }

  String _getChatId(String id1, String id2) {
    final sortedIds = [id1, id2]..sort();
    return sortedIds.join('_');
  }

  Future<int> _getMessageCount(String chatId) async {
    final messagesSnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .get();
    return messagesSnapshot.docs.length;
  }

  Widget _buildEmployeeChatList({
    required BuildContext context,
    required String employeeName,
    required String employeeId,
    required List<Map<String, dynamic>> studentChats,
  }) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        title: Text(
          employeeName,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryRed),
        ),
        children: studentChats.expand((studentChat) {
          final studentName = '${studentChat['firstName']} ${studentChat['lastName']}';
          final studentId = studentChat['id'];
          final regularMessageCount = studentChat['regularMessageCount'];
          final anonymousMessageCount = studentChat['anonymousMessageCount'];
          final anonymousName = studentChat['anonymousName'] ?? 'Anonymous';

          return [
            if (regularMessageCount > 0)
              ListTile(
                leading: _buildAvatar(studentName, studentChat['avatarUrl']),
                title: Text(studentName),
                subtitle: Text('Regular Messages: $regularMessageCount'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminChatViewScreen(
                        chatId: _getChatId(employeeId, studentId),
                        employeeName: employeeName,
                        studentName: studentName,
                        isAnonymous: false,
                      ),
                    ),
                  );
                },
              ),
            if (anonymousMessageCount > 0)
              ListTile(
                leading: _buildAvatar(anonymousName, null),
                title: Text('$anonymousName (Anonymous)'),
                subtitle: Text('Anonymous Messages: $anonymousMessageCount'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminChatViewScreen(
                        chatId: 'anonymous_${_getChatId(employeeId, studentId)}',
                        employeeName: employeeName,
                        studentName: anonymousName,
                        isAnonymous: true,
                      ),
                    ),
                  );
                },
              ),
          ];
        }).toList(),
      ),
    );
  }

  Widget _buildAvatar(String displayName, String? avatarUrl) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: AppTheme.primaryRed,
      child: (avatarUrl != null && avatarUrl.isNotEmpty)
          ? ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl,
          placeholder: (context, url) => CircularProgressIndicator(color: Colors.white),
          errorWidget: (context, url, error) => Text(
            displayName[0].toUpperCase(),
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      )
          : Text(
        displayName[0].toUpperCase(),
        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

