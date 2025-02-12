import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart'; // Import the ApiService
import 'package:crypto/crypto.dart';
import 'dart:convert';

class ChangePassword extends StatefulWidget {
  final VoidCallback onPasswordChanged; // Callback for password change

  const ChangePassword({super.key, required this.onPasswordChanged}); // Constructor

  @override
  _ChangePasswordState createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureOldPassword = true; // Visibility for old password
  bool _obscureNewPassword = true; // Visibility for new password
  bool _obscureConfirmPassword = true; // Visibility for confirm password

  final ApiService apiService = ApiService();

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final oldPassword = _oldPasswordController.text.trim();
      final newPassword = _newPasswordController.text.trim();

      // Fetch UserRole from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userRole = prefs.getString('UserRole') ?? ''; // Retrieve the role with the correct key
      print("Retrieved User Role: $userRole"); // Debugging line

      // Validate user role
      if (userRole.isEmpty || !['admin', 'student', 'faculty'].contains(userRole.toLowerCase())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid user role. Please log in again.')),
        );
        return;
      }

      // Show confirmation dialog
      final confirmChange = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirm Change Password'),
            content: const Text('Are you sure you want to change your password? You will be logged out.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false), // User cancels
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true), // User confirms
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );

      // If the user did not confirm, exit the function
      if (confirmChange != true) {
        return;
      }

      try {
        // Step 1: Verify the old password
        print("Verifying old password for $email with role $userRole...");
        print("Payload for old password verification: { Email: $email, OldPassword: $oldPassword, Role: $userRole }"); // Print payload
        final verifyResponse = await apiService.verifyOldPassword(
          email: email,
          oldPassword: oldPassword,
          role: userRole,
        );

        // Log the response from the old password verification
        print("Old Password Verification response: $verifyResponse");

        if (verifyResponse['success'] == true) {
          // Step 2: Proceed to change the password
          print("Changing password...");
          print("Payload for password change: { Email: $email, NewPassword: $newPassword, Role: $userRole }"); // Print payload
          final response = await apiService.changePassword(
            email: email,
            newPassword: newPassword, // Send new password only
            type: userRole,
          );

          // Log the response from the change password API call
          print("Change Password API response: $response");

          if (response['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response['message'] ?? 'Password changed successfully!')),
            );
            widget.onPasswordChanged(); // Call the callback here

            // Log out the user by clearing SharedPreferences
            await prefs.clear(); // Clear all saved preferences

            Navigator.pop(context); // Go back to the previous screen
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response['message'] ?? 'Failed to change password.')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(verifyResponse['message'] ?? 'Old password verification failed.')),
          );
        }
      } catch (e) {
        print("Error during password change process: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred. Please try again.')),
        );
      }
    }
  }

  // Remove strong password validation
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    return null; // Allow any password
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Change Password',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 24),
        ),
        backgroundColor: Colors.orange[700],
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildPasswordField(
                controller: _oldPasswordController,
                label: "Old Password",
                obscureText: _obscureOldPassword,
                toggleVisibility: () => setState(() => _obscureOldPassword = !_obscureOldPassword),
              ),
              const SizedBox(height: 20),
              _buildPasswordField(
                controller: _newPasswordController,
                label: "New Password",
                obscureText: _obscureNewPassword,
                toggleVisibility: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
              ),
              const SizedBox(height: 20),
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: "Confirm New Password",
                obscureText: _obscureConfirmPassword,
                toggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Change Password',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback toggleVisibility,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
          onPressed: toggleVisibility,
        ),
      ),
      validator: (value) => _validatePassword(value), //
    );
  }
}