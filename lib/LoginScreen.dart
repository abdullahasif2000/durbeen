import 'package:flutter/material.dart';
import 'ModuleScreen.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String? selectedRole = 'Admin'; // Default role
  bool _obscurePassword = true;

  void handleLogin() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String role = selectedRole!;

    if (!_isValidEmail(email)) {
      _showSnackbar('Please enter a valid email address');
      return;
    }

    if (password.isEmpty || password.length < 6) {
      _showSnackbar('Password must be at least 6 characters long');
      return;
    }

    try {
      final response = await ApiService().login(email, password, role);

      if (response != null) {
        // Save login state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);

        // Save user role
        await prefs.setString('UserRole', role);

        if (role == "Admin") {
          // Save email for admin
          await prefs.setString('AdminEmail', email);
          print("Admin email saved: $email");
        }

        if (role == "Faculty") {
          String? facultyID = response['FacultyID']?.toString();
          await prefs.setString('FacultyID', facultyID ?? '');
          print("FacultyID saved: $facultyID");
        }

        if (role == "Student") {
          String? rollNumber = response['RollNumber']?.toString();
          await prefs.setString('RollNumber', rollNumber ?? '');
          print("RollNumber saved: $rollNumber");
        }

        // Navigate to ModuleScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ModuleScreen(role: role)),
        );
      } else {
        _showSnackbar('Invalid credentials. Please try again.');
      }
    } catch (e) {
      _showSnackbar('Error occurred during login. Please try again later.');
      print('Login error: $e');
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Colors.orange[700],
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
          ),
          centerTitle: true,
          title: const Text(
            'Campus Connect',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 24,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/cc-logo1-rbg.png',
                height: 170,
              ),
              const SizedBox(height: 30),
              const Text(
                'Login To Your Account',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 5,
                color: Colors.white.withOpacity(0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.email, color: Colors.orange[700]),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const Divider(),
                      TextField(
                        controller: passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.lock, color: Colors.orange[700]),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.orange[700],
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                      const Divider(),
                      DropdownButton<String>(
                        value: selectedRole,
                        onChanged: (String? newRole) {
                          setState(() {
                            selectedRole = newRole;
                          });
                        },
                        items: <String>['Admin', 'Student', 'Faculty']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                '© 2024. All rights reserved.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
