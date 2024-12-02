import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../helpers/database_helper.dart';
import '../login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String studentId;

  const ProfileScreen({Key? key, required this.studentId}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<DocumentSnapshot> _studentDataFuture;
  bool _isAnonymous = false;

  @override
  void initState() {
    super.initState();
    _studentDataFuture = _fetchStudentData();
  }

  Future<DocumentSnapshot> _fetchStudentData() async {
    return await FirebaseFirestore.instance
        .collection('students')
        .doc(widget.studentId)
        .get();
  }

  Future<void> _updateAnonymityStatus(bool isAnonymous) async {
    await FirebaseFirestore.instance
        .collection('students')
        .doc(widget.studentId)
        .update({'isAnonymous': isAnonymous});
    setState(() {
      _isAnonymous = isAnonymous;
      _studentDataFuture = _fetchStudentData();
    });
  }

  Future<void> _logout(BuildContext context) async {
    bool? confirmLogout = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Log Out'),
        content: Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.clearSession();
              Navigator.pop(context, true);
            },
            child: Text('Log Out'),
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
      appBar: AppBar(
        title: Text('Student Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _studentDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                'No student data available',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final studentData = snapshot.data!.data() as Map<String, dynamic>;
          final firstName = studentData['firstName'] ?? 'N/A';
          final middleName = studentData['middleName'] ?? 'N/A';
          final lastName = studentData['lastName'] ?? 'N/A';
          _isAnonymous = studentData['isAnonymous'] ?? false;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 40),
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: _isAnonymous
                      ? Icon(Icons.person_outline, size: 60, color: Colors.white)
                      : Text(
                    '${firstName[0]}${lastName[0]}',
                    style: TextStyle(fontSize: 40, color: Colors.white),
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  _isAnonymous ? 'Anonymous' : '$firstName $middleName $lastName',
                  style: Theme.of(context).textTheme.headline5?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Student ID: ${_isAnonymous ? 'Hidden' : widget.studentId}',
                  style: Theme.of(context).textTheme.subtitle1?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 24),
                SwitchListTile(
                  title: Text('Anonymous Mode'),
                  value: _isAnonymous,
                  onChanged: (bool value) {
                    _updateAnonymityStatus(value);
                  },
                  secondary: Icon(Icons.visibility_off),
                ),
                SizedBox(height: 24),
                if (!_isAnonymous) ...[
                  _buildInfoCard('First Name', firstName, Icons.person),
                  _buildInfoCard('Middle Name', middleName, Icons.person_outline),
                  _buildInfoCard('Last Name', lastName, Icons.person),
                  _buildInfoCard('Student ID', widget.studentId, Icons.badge),
                ] else
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Personal information is hidden in anonymous mode.',
                        style: Theme.of(context).textTheme.subtitle1,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 5,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Icon(icon, color: Colors.blue),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
      ),
    );
  }
}