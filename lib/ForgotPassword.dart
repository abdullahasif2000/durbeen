import 'package:flutter/material.dart';
import 'dart:math';
import 'api_service.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController _emailController = TextEditingController();
  String? _selectedType;
  final List<String> _userTypes = ['Admin', 'Student', 'Faculty'];


  final ApiService apiService = ApiService();

  String _generateRandomPassword() {
    const length = 12; // password length
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()';
    Random random = Random();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }

  void _showAlertDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _submit() async {
    final email = _emailController.text.trim();
    final type = _selectedType;

    if (email.isEmpty || type == null) {
      print("Email or user type is empty.");
      _showAlertDialog('Error', 'Please enter your email and select a user type.');
      return;
    }

    final newPassword = _generateRandomPassword();
    print("Generated new password for $email: $newPassword");

    // changePassword method
    final changePasswordResult = await apiService.changePassword(email: email, newPassword: newPassword, type: type);
    print("Change password result: ${changePasswordResult['message']}");

    if (changePasswordResult['success'] == true) {
      // send new password via email
      final emailResult = await apiService.sendEmail(email: email, newPassword: newPassword);
      print("Email sending result: ${emailResult['message']}");

      _showAlertDialog('Success', emailResult['message'] ?? 'Email sent successfully.');
    } else {
      _showAlertDialog('Error', changePasswordResult['message'] ?? 'Failed to change password.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: Colors.orange[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
          Image.asset(
          'assets/images/ForgotPasswordLarge.png',
          height: 100,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 20),
        const Text(
          'What\'s My Password?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Enter Your Email',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedType,
          hint: const Text('You Are?'),
          items: _userTypes.map((String type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedType = newValue;
            });
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[700],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text('Request Password'),
      ),
      ],
    ),
    ),
    );
  }
}