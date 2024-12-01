import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../helpers/database_helper.dart';
import 'ACCOUNTS/static_accounts.dart';
import 'EmployeePage/employee_dashboard.dart';
import 'StudentPage/student_dashboard.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkInternetAndProceed();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();
  }

  Future<void> _checkInternetAndProceed() async {
    await Future.delayed(Duration(seconds: 2)); // Minimum splash display time

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _showNoInternetDialog();
      return;
    }

    await _uploadStaticUsers();
    await _checkSessionAndProceed();
  }

  Future<void> _uploadStaticUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<UserAccount> studentAccounts = UserAccount.generateStudentAccounts();
      List<UserAccount> adminAccounts = UserAccount.generateAdminAccounts();
      List<UserAccount> employeeAccounts = UserAccount.generateEmployeeAccounts();

      await _uploadUsersToFirestore(studentAccounts, 'students');
      await _uploadUsersToFirestore(adminAccounts, 'admins');
      await _uploadUsersToFirestore(employeeAccounts, 'employees');

      Fluttertoast.showToast(
        msg: "Static users uploaded successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error uploading static users: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadUsersToFirestore(List<UserAccount> users, String category) async {
    final CollectionReference categoryCollection = FirebaseFirestore.instance.collection(category);

    for (var user in users) {
      try {
        DocumentSnapshot userDoc = await categoryCollection.doc(user.id).get();

        if (!userDoc.exists) {
          await categoryCollection.doc(user.id).set({
            'firstName': user.firstName,
            'middleName': user.middleName,
            'lastName': user.lastName,
            'id': user.id,
            'password': user.password,
          });
          print('Uploaded ${user.firstName} ${user.lastName} (ID: ${user.id}) to $category collection.');
        } else {
          print('User ${user.firstName} ${user.lastName} (ID: ${user.id}) already exists in $category collection.');
        }
      } catch (e) {
        throw Exception("Error uploading user ${user.id}: $e");
      }
    }
  }

  Future<void> _checkSessionAndProceed() async {
    final session = await DatabaseHelper.instance.getSession();
    if (session != null) {
      _navigateBasedOnRole(session['userRole'], session['userId']);
    } else {
      _navigateToLogin();
    }
  }

  void _navigateBasedOnRole(String role, String userId) {
    switch (role) {
      case 'student':
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => StudentDashboard(studentId: userId),
        ));
        break;
      case 'employee':
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => EmployeeDashboard(employeeId: userId),
        ));
        break;
      case 'admin':
      // TODO: Implement AdminDashboard
        _navigateToLogin();
        break;
      default:
        _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => LoginScreen(),
    ));
  }

  void _showNoInternetDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('No Internet Connection'),
        content: Text('Please connect to the internet and try again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFAA0000), Color(0xFF800000)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _fadeInAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'SienaTalk',
                      style: TextStyle(
                        fontSize: 32.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16.0),
                    Text(
                      'The Siena College Communication Platform',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 32.0),
                  child: CircularProgressIndicator(color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

