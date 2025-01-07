import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sienatalk/theme/app_theme.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class UsersPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white.withOpacity(0.1),
            child: TabBar(
              tabs: [
                Tab(text: 'Students'),
                Tab(text: 'Employees'),
              ],
              labelColor: AppTheme.pureWhite,
              unselectedLabelColor: AppTheme.pureWhite.withOpacity(0.7),
              indicatorColor: AppTheme.accentYellow,
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                UserList(collection: 'students'),
                UserList(collection: 'employees'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class UserList extends StatelessWidget {
  final String collection;

  UserList({required this.collection});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppTheme.pureWhite));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: AppTheme.pureWhite)));
        }

        return AnimationLimiter(
          child: ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var userData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Colors.white.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: collection == 'students' ? AppTheme.accentYellow : AppTheme.primaryRed,
                          child: Text(
                            userData['firstName'][0].toUpperCase(),
                            style: TextStyle(color: AppTheme.pureWhite),
                          ),
                        ),
                        title: Text(
                          '${userData['firstName']} ${userData['lastName']}',
                          style: TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          userData['id'],
                          style: TextStyle(color: AppTheme.pureWhite.withOpacity(0.7)),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.pureWhite),
                        onTap: () {
                          _showUserDetails(context, userData, collection);
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showUserDetails(BuildContext context, Map<String, dynamic> userData, String collection) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('User Details', style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold)),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ID: ${userData['id']}', style: TextStyle(color: AppTheme.darkGrey)),
              Text('First Name: ${userData['firstName']}', style: TextStyle(color: AppTheme.darkGrey)),
              Text('Middle Name: ${userData['middleName']}', style: TextStyle(color: AppTheme.darkGrey)),
              Text('Last Name: ${userData['lastName']}', style: TextStyle(color: AppTheme.darkGrey)),
              if (collection == 'students')
                Text('Is Anonymous: ${userData['isAnonymous'] ?? 'N/A'}', style: TextStyle(color: AppTheme.darkGrey)),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Close', style: TextStyle(color: AppTheme.primaryRed)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

