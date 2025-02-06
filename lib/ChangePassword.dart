import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart'; // Import the ApiService

class ChangePassword extends StatefulWidget {
  final VoidCallback onPasswordChanged; // Callback for password change

  const ChangePassword({super.key, required this.onPasswordChanged}); // Constructor

  @override
  _ChangePasswordState createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureNewPassword = true; // Visibility for new password
  bool _obscureConfirmPassword = true; // Visibility for confirm password

  final ApiService apiService = ApiService();

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final newPassword = _newPasswordController.text.trim();

      // Fetch UserRole from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userRole = prefs.getString('UserRole') ?? '';

      if (userRole.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User  role not found. Please log in again.')),
        );
        return;
      }

      try {
        // Log the payload for the change password API call
        print("Changing password...");
        print("Payload: { Email: $email, NewPassword: $newPassword, Role: $userRole }");

        // Step 1: Proceed to change the password
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
          Navigator.pop(context); // Go back to the previous screen
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Failed to change password.')),
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
      validator: (value) => _validatePassword(value), // Use the new validation function
    );
  }
}