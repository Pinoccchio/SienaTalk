import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RecentActivityScreen extends StatefulWidget {
  final String studentId;

  const RecentActivityScreen({Key? key, required this.studentId}) : super(key: key);

  @override
  _RecentActivityScreenState createState() => _RecentActivityScreenState();
}

class _RecentActivityScreenState extends State<RecentActivityScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recent Activity', style: TextStyle(fontSize: 20)),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('scheduleRequests')
                .where('studentId', isEqualTo: widget.studentId)
                .snapshots(),
            builder: (context, snapshot) {
              final totalCount = snapshot.hasData ? snapshot.data!.docs.length : 0;

              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Row(
                  children: [
                    if (totalCount > 0)
                      Chip(
                        label: Text(
                          '$totalCount total',
                          style: TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Colors.blue.shade100,
                      ),
                  ],
                ),
              );
            },
          ),
        ],
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('scheduleRequests')
            .where('studentId', isEqualTo: widget.studentId)
            .orderBy('createdAt', descending: true)
            .limit(10)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No recent activity'));
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var activity = snapshot.data!.docs[index];
              return _buildActivityCard(context, activity);
            },
          );
        },
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, DocumentSnapshot activity) {
    final data = activity.data() as Map<String, dynamic>;
    final reason = data['reason'] as String;
    final date = (data['date'] as Timestamp).toDate();
    final time = data['time'] as String;
    final isUrgent = data['isUrgent'] as bool;
    final isAnonymous = data['isAnonymous'] as bool;
    final createdAt = data['createdAt'] as Timestamp;

    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isUrgent ? Icons.priority_high : Icons.event,
                    color: isUrgent ? Colors.red : Colors.blue,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reason,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isAnonymous) Icon(Icons.visibility_off, color: Colors.grey),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Scheduled for: ${DateFormat('MMM d, yyyy').format(date)} at $time',
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 4),
              Text(
                'Requested: ${DateFormat('MMM d, yyyy HH:mm').format(createdAt.toDate())}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

