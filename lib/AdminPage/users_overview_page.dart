import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sienatalk/theme/app_theme.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'data_card.dart';

class OverviewPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _getUserCounts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppTheme.pureWhite));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: AppTheme.pureWhite)));
        }

        final counts = snapshot.data!;

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: AnimationLimiter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 375),
                childAnimationBuilder: (widget) => SlideAnimation(
                  horizontalOffset: 50.0,
                  child: FadeInAnimation(
                    child: widget,
                  ),
                ),
                children: [
                  Text(
                    'Overview',
                    style: Theme.of(context).textTheme.headline4!.copyWith(color: AppTheme.pureWhite, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DataCard(
                          title: 'Total Students',
                          value: counts['students'].toString(),
                          icon: Icons.school,
                          color: AppTheme.accentYellow,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: DataCard(
                          title: 'Total Employees',
                          value: counts['employees'].toString(),
                          icon: Icons.work,
                          color: AppTheme.primaryRed,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  /*
                  Text(
                    'Recent Activity',
                    style: Theme.of(context).textTheme.headline5!.copyWith(color: AppTheme.pureWhite, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  // Add your recent activity list or widget here

                   */
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, int>> _getUserCounts() async {
    final studentsSnapshot = await FirebaseFirestore.instance.collection('students').get();
    final employeesSnapshot = await FirebaseFirestore.instance.collection('employees').get();

    return {
      'students': studentsSnapshot.docs.length,
      'employees': employeesSnapshot.docs.length,
    };
  }
}

