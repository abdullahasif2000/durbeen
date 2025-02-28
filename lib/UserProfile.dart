import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
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
  File? profileImage;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _loadProfileImage();
  }

  Future<void> _fetchUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedRole = prefs.getString('UserRole');
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
      } else if (userRole == 'Admin') {
        final List<Map<String, dynamic>> adminData = await ApiService().fetchAdminData();
        final savedAdminEmail = prefs.getString('AdminEmail');
        final admin = adminData.firstWhere(
              (admin) => admin['Email'] == savedAdminEmail,
          orElse: () => {},
        );
        setState(() {
          userData = admin.isNotEmpty ? admin : null;
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String imagePath = '${appDocDir.path}/profile_image.png';
      final File imageFile = File(imagePath);

      await imageFile.writeAsBytes(await pickedFile.readAsBytes());

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileImagePath', imagePath);

      setState(() {
        profileImage = imageFile;
      });
    }
  }

  Future<void> _loadProfileImage() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? imagePath = prefs.getString('profileImagePath');
    if (imagePath != null) {
      setState(() {
        profileImage = File(imagePath);
      });
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
            Container(
              width: double.infinity,
              color: Colors.orange[700],
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage:
                          profileImage != null ? FileImage(profileImage!) : null,
                          child: profileImage == null
                              ? const Icon(Icons.person, size: 60, color: Colors.orange)
                              : null,
                        ),
                        if (profileImage == null)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 15,
                              backgroundColor: Colors.orange,
                              child: const Icon(
                                Icons.add,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    userData!['Email'] ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    userRole,
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
                        _buildInfoRow('Faculty Name', userData!['FacultyName']),
                        _buildInfoRow('Status', userData!['Status']),
                      ] else if (userRole == 'Admin') ...[
                        _buildInfoRow('Admin ID', userData!['id']),
                        _buildInfoRow('Email', userData!['Email']),
                        _buildInfoRow('Name ', userData!['Name']),
                        _buildInfoRow('Department', userData!['department']),
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
