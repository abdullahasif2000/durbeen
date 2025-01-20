import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  Map<String, dynamic>? loggedInStudent;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedRollNumber = prefs.getString('RollNumber');

    if (savedRollNumber == null || savedRollNumber.isEmpty) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No Roll Number found')),
      );
      return;
    }

    try {
      final List<Map<String, dynamic>> data = await ApiService().fetchStudentData();
      final student = data.firstWhere(
            (student) => student['RollNumber'] == savedRollNumber,
        orElse: () => {},
      );

      setState(() {
        loggedInStudent = student.isNotEmpty ? student : null;
        isLoading = false;
      });

      if (loggedInStudent == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data found for the logged-in student')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching student data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: Colors.orange[700],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : loggedInStudent != null
          ? SingleChildScrollView(
        child: Column(
          children: [
            // Header Section with User Avatar
            Container(
              width: double.infinity,
              color: Colors.orange[700],
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 60, color: Colors.orange),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    loggedInStudent!['Name'] ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    loggedInStudent!['Email'] ?? 'N/A',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
            ),

            // User Details Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'User Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      _buildInfoRow('Seat Number', loggedInStudent!['SeatNumber']),
                      _buildInfoRow('Enrollment Number', loggedInStudent!['EnrollmentNumber']),
                      _buildInfoRow('Roll Number', loggedInStudent!['RollNumber']),
                      _buildInfoRow('Father Name', loggedInStudent!['FatherName']),
                      _buildInfoRow('Year of Admission', loggedInStudent!['YearAdmission']),
                      _buildInfoRow('Cohort', loggedInStudent!['cohort']),
                      _buildInfoRow('Status', loggedInStudent!['Status']),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      )
          : const Center(child: Text('No data available')),
    );
  }

  // Helper Widget for Displaying Rows of Information
  Widget _buildInfoRow(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Flexible(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
