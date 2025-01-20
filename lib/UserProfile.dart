import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String userRole = '';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedRole = prefs.getString('UserRole'); // Fetch role from SharedPreferences
    setState(() {
      userRole = savedRole ?? '';
    });

    if (userRole.isEmpty) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No Role found')),
      );
      return;
    }

    try {
      if (userRole == 'Student') {
        final List<Map<String, dynamic>> studentData = await ApiService().fetchStudentData();
        final savedRollNumber = prefs.getString('RollNumber');
        final student = studentData.firstWhere(
              (student) => student['RollNumber'] == savedRollNumber,
          orElse: () => {},
        );
        setState(() {
          userData = student.isNotEmpty ? student : null;
          isLoading = false;
        });
      } else if (userRole == 'Faculty') {
        final List<Map<String, dynamic>> facultyData = await ApiService().fetchFacultyData();
        final savedFacultyID = prefs.getString('FacultyID');
        final faculty = facultyData.firstWhere(
              (faculty) => faculty['FacultyID'] == savedFacultyID,
          orElse: () => {},
        );
        setState(() {
          userData = faculty.isNotEmpty ? faculty : null;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
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
          : userData != null
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
                    userData!['Name'] ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    userData!['Email'] ?? 'N/A',
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
                      if (userRole == 'Student') ...[
                        _buildInfoRow('Roll Number', userData!['RollNumber']),
                        _buildInfoRow('Name', userData!['Name']),
                        _buildInfoRow('Father Name', userData!['FatherName']),
                        _buildInfoRow('Year of Admission', userData!['YearAdmission']),
                        _buildInfoRow('Cohort', userData!['cohort']),
                        _buildInfoRow('Status', userData!['Status']),
                        _buildInfoRow('Seat Number', userData!['SeatNumber']),
                        _buildInfoRow('Enrollment Number', userData!['EnrollmentNumber']),
                      ] else if (userRole == 'Faculty') ...[
                        _buildInfoRow('Faculty ID', userData!['FacultyID']),
                        _buildInfoRow('Email', userData!['Email']),
                        _buildInfoRow('Status', userData!['Status']),
                      ],
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
