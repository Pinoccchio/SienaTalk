import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sienatalk/StudentPage/profile_screen.dart';
import 'package:sienatalk/StudentPage/recent_activity_screen.dart';
import 'package:sienatalk/StudentPage/student_schedule_request.dart';
import 'package:sienatalk/StudentPage/student_schedule_view.dart';
import 'package:sienatalk/StudentPage/chat_list_screen.dart';
import '../theme/app_theme.dart';

class StudentDashboard extends StatefulWidget {
  final String studentId;

  const StudentDashboard({Key? key, required this.studentId}) : super(key: key);

  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  Set<String> _readActivityIds = {};

  @override
  void initState() {
    super.initState();
    _loadReadActivities();
  }

  Future<void> _loadReadActivities() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _readActivityIds = prefs.getStringList('readActivityIds')?.toSet() ?? {};
    });
  }

  Future<int> _getUnreadCount() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('scheduleRequests')
        .where('studentId', isEqualTo: widget.studentId)
        .get();

    return snapshot.docs.where((doc) => !_readActivityIds.contains(doc.id)).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .doc(widget.studentId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Student not found'));
          }

          final studentData = snapshot.data!.data() as Map<String, dynamic>;
          final firstName = studentData['firstName'] ?? 'Student';
          final lastName = studentData['lastName'] ?? '';

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryRed, AppTheme.primaryRed],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, firstName, lastName),
                  Expanded(
                    child: _buildDashboardContent(context),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String firstName, String lastName) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome,',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              Text(
                '$firstName $lastName',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          Row(
            children: [
              _buildNotificationIcon(),
              SizedBox(width: 16),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen(studentId: widget.studentId)),
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    '${firstName[0]}${lastName[0]}',
                    style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return FutureBuilder<int>(
      future: _getUnreadCount(),
      builder: (context, snapshot) {
        int unreadCount = snapshot.data ?? 0;

        return Stack(
          children: [
            IconButton(
              icon: Icon(Icons.notifications, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RecentActivityScreen(studentId: widget.studentId)),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: Text(
                    '$unreadCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDashboardContent(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryRed),
            ),
            SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildFeatureCard(
                    context,
                    icon: Icons.calendar_today,
                    title: 'View Schedule',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => StudentScheduleView(studentId: widget.studentId)),
                    ),
                  ),
                  _buildFeatureCard(
                    context,
                    icon: Icons.schedule_send,
                    title: 'Request Scheduling',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => StudentScheduleRequest(studentId: widget.studentId)),
                    ),
                  ),
                  _buildFeatureCard(
                    context,
                    icon: Icons.chat,
                    title: 'Chat',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ChatListScreen(studentId: widget.studentId)),
                    ),
                  ),
                  _buildFeatureCard(
                    context,
                    icon: Icons.history,
                    title: 'Recent Activity',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RecentActivityScreen(studentId: widget.studentId)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: AppTheme.primaryRed),
              SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryRed),
              ),
            ],
          ),
        ),
      ),
    );
  }
}