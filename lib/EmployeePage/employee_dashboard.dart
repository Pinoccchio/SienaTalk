import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../theme/app_theme.dart';
import 'anonymouse_chat.dart';
import 'employee_chat_list_screen.dart';
import 'employee_profile_screen.dart';
import 'employee_schedules_view.dart';

class EmployeeDashboard extends StatelessWidget {
  final String employeeId;

  const EmployeeDashboard({Key? key, required this.employeeId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('employees')
            .doc(employeeId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Employee not found'));
          }

          final employeeData = snapshot.data!.data() as Map<String, dynamic>;
          final firstName = employeeData['firstName'] ?? 'Employee';
          final lastName = employeeData['lastName'] ?? '';

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryRed, AppTheme.accentYellow],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildProfileSection(context, firstName, lastName),
                  Expanded(
                    child: AnimationLimiter(
                      child: ListView(
                        padding: EdgeInsets.all(16),
                        children: AnimationConfiguration.toStaggeredList(
                          duration: const Duration(milliseconds: 375),
                          childAnimationBuilder: (widget) => SlideAnimation(
                            horizontalOffset: 50.0,
                            child: FadeInAnimation(
                              child: widget,
                            ),
                          ),
                          children: [
                            _buildFeatureCard(
                              context,
                              'View Schedules',
                              Icons.calendar_today,
                                  () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => EmployeeSchedulesView()),
                              ),
                            ),
                            SizedBox(height: 16),
                            _buildFeatureCard(
                              context,
                              'Chats',
                              Icons.chat_bubble_outline,
                                  () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => EmployeeChatListScreen(employeeId: employeeId)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, String firstName, String lastName) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.pureWhite,
            child: Text(
              '${firstName[0]}${lastName[0]}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryRed, // Primary red color
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome,',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.darkGrey,
                  ),
                ),
                Text(
                  '$firstName $lastName',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.pureWhite,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.settings, color: AppTheme.pureWhite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EmployeeProfileScreen(employeeId: employeeId)),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(icon, size: 48, color: AppTheme.primaryRed), // Primary red color for the icon
              SizedBox(width: 24),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryRed, // Primary red color for the text
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: AppTheme.primaryRed), // Primary red color for the arrow
            ],
          ),
        ),
      ),
    );
  }
}
