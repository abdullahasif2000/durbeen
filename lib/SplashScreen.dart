import 'package:flutter/material.dart';
import 'LoginScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ModuleScreen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  Future<void> checkLoginStatus(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      // Fetch saved user role
      final role = prefs.getString('UserRole') ?? 'Admin';
      // Navigate to ModuleScreen if logged in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ModuleScreen(role: role)),
      );
    } else {
      // Navigate to LoginScreen if not logged in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => checkLoginStatus(context), // Check login status on tap
        child: Container(
          color: Colors.white,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/CampusConnect large(1).png',
                  height: 350,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Tap to continue',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
