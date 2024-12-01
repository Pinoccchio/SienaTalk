import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../login_screen.dart';

class AuthHelper {
  static Future<void> logout(BuildContext context) async {
    await DatabaseHelper.instance.clearSession();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
    );
  }
}

