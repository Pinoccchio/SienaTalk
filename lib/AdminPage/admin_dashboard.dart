import 'package:flutter/material.dart';
import 'package:sienatalk/AdminPage/schedule_overview.dart';
import 'package:sienatalk/AdminPage/users_overview_page.dart';
import 'package:sienatalk/AdminPage/users_page.dart';
import 'package:sienatalk/theme/app_theme.dart';
import 'package:sienatalk/login_screen.dart';

import '../helpers/database_helper.dart';
import 'chat_overview.dart';

class AdminDashboard extends StatefulWidget {
  final String adminId;

  AdminDashboard({required this.adminId});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryRed.withOpacity(0.8), AppTheme.accentYellow.withOpacity(0.8)],
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (int index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                labelType: NavigationRailLabelType.selected,
                backgroundColor: Colors.white.withOpacity(0.1),
                selectedIconTheme: IconThemeData(color: AppTheme.pureWhite),
                unselectedIconTheme: IconThemeData(color: AppTheme.pureWhite.withOpacity(0.7)),
                selectedLabelTextStyle: TextStyle(color: AppTheme.pureWhite),
                unselectedLabelTextStyle: TextStyle(color: AppTheme.pureWhite.withOpacity(0.7)),
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard),
                    selectedIcon: Icon(Icons.dashboard),
                    label: Text('Overview'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.people),
                    selectedIcon: Icon(Icons.people),
                    label: Text('Users'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.chat),
                    selectedIcon: Icon(Icons.chat),
                    label: Text('Chats'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.calendar_today),
                    selectedIcon: Icon(Icons.calendar_today),
                    label: Text('Schedule'),
                  ),
                ],
              ),
              VerticalDivider(thickness: 1, width: 1, color: Colors.white.withOpacity(0.3)),
              Expanded(
                child: _buildSelectedView(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _logout(context),
        child: Icon(Icons.logout, color: AppTheme.pureWhite),
        backgroundColor: AppTheme.primaryRed,
      ),
    );
  }

  Widget _buildSelectedView() {
    switch (_selectedIndex) {
      case 0:
        return OverviewPage();
      case 1:
        return UsersPage();
      case 2:
      // Pass the adminId dynamically
        return AdminChatOverviewScreen();
      case 3:
        return SchedulesOverviewPage();
      default:
        return OverviewPage();
    }
  }

  Future<void> _logout(BuildContext context) async {
    bool? confirmLogout = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Log Out',
          style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold),
        ),
        content: Text('Are you sure you want to log out?', style: TextStyle(color: AppTheme.darkGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppTheme.primaryRed)),
          ),
          ElevatedButton(
            onPressed: () async {
              // Clear the session from the database
              await DatabaseHelper.instance.clearSession();

              // Close the dialog and confirm logout
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
}
