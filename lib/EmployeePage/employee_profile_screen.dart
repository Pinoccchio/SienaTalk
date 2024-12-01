import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../helpers/database_helper.dart';
import '../login_screen.dart';
import '../theme/app_theme.dart';

class EmployeeProfileScreen extends StatelessWidget {
  final String employeeId;

  const EmployeeProfileScreen({Key? key, required this.employeeId}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    bool? confirmLogout = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Log Out', style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to log out?', style: TextStyle(color: AppTheme.darkGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppTheme.primaryRed)),
          ),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.clearSession();
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Log Out', style: TextStyle(color: AppTheme.pureWhite)),
          ),
        ],
      ),
    );
    if (confirmLogout == true) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
            (Route<dynamic> route) => false,
      );
    }
  }

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
            return Center(child: CircularProgressIndicator(color: AppTheme.primaryRed));
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: AppTheme.primaryRed),
              ),
            );
          } else if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                'No employee data available',
                style: TextStyle(color: AppTheme.darkGrey),
              ),
            );
          }

          final employeeData = snapshot.data!.data() as Map<String, dynamic>;
          final firstName = employeeData['firstName'] ?? 'N/A';
          final lastName = employeeData['lastName'] ?? 'N/A';

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
                  _buildAppBar(context),
                  Expanded(
                    child: SingleChildScrollView(
                      child: AnimationLimiter(
                        child: Column(
                          children: AnimationConfiguration.toStaggeredList(
                            duration: const Duration(milliseconds: 375),
                            childAnimationBuilder: (widget) => SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: widget,
                              ),
                            ),
                            children: [
                              SizedBox(height: 40),
                              _buildProfileAvatar(firstName, lastName),
                              SizedBox(height: 24),
                              Text(
                                '$firstName $lastName',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.pureWhite,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Employee ID: $employeeId',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.pureWhite.withOpacity(0.8),
                                ),
                              ),
                              SizedBox(height: 40),
                              _buildInfoCard('First Name', firstName, Icons.person),
                              _buildInfoCard('Last Name', lastName, Icons.person),
                              _buildInfoCard('Employee ID', employeeId, Icons.badge),
                            ],
                          ),
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

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: AppTheme.pureWhite),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'Employee Profile',
            style: TextStyle(
              color: AppTheme.pureWhite,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: Icon(Icons.logout, color: AppTheme.pureWhite),
            onPressed: () => _logout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(String firstName, String lastName) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.pureWhite, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 5,
            blurRadius: 10,
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 60,
        backgroundColor: AppTheme.accentYellow,
        child: Text(
          '${firstName[0]}${lastName[0]}',
          style: TextStyle(fontSize: 40, color: AppTheme.primaryRed, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.accentYellow.withOpacity(0.2),
          child: Icon(icon, color: AppTheme.primaryRed),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkGrey)),
        subtitle: Text(value, style: TextStyle(color: AppTheme.primaryRed, fontSize: 16)),
      ),
    );
  }
}