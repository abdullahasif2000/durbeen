import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class GenerateComplaint extends StatefulWidget {
  const GenerateComplaint({Key? key}) : super(key: key);

  @override
  _GenerateComplaintState createState() => _GenerateComplaintState();
}

class _GenerateComplaintState extends State<GenerateComplaint> {
  String? selectedRequestType;
  String? selectedDepartmentName;
  List<Map<String, dynamic>> departments = [];
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  String complaint = '';

  final List<String> requestTypes = [
    'Complaint',
    'Suggestion',
    'Anonymous',
  ];

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
    _loadUserData(); // Load SharedPreferences
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _fetchDepartments() async {
    try {
      final List<Map<String, dynamic>> fetchedDepartments = await ApiService().fetchDepartments();
      setState(() {
        departments = fetchedDepartments;
      });
      print('Fetched Departments: $departments');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching departments: $e')),
      );
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      String name = prefs.getString('Name') ?? '';
      String email = prefs.getString('Email') ?? '';

      // If the user is Faculty, load the FacultyName instead
      if (prefs.getString('UserRole') == 'Faculty') {
        name = prefs.getString('FacultyName') ?? '';
      }

      nameController.text = name;
      emailController.text = email;

      print('Loaded Name: $name');
      print('Loaded Email: $email');
    });
  }

  Future<void> _submitComplaint() async {
    final prefs = await SharedPreferences.getInstance();
    String userRole = prefs.getString('UserRole') ?? '';
    String userId = '';

    if (userRole == "Admin") {
      userId = prefs.getString('AdminID') ?? '';
    } else if (userRole == "Faculty") {
      userId = prefs.getString('FacultyID') ?? '';
    } else if (userRole == "Student") {
      userId = prefs.getString('RollNumber') ?? '';
    }

    // Log the payload
    print('Submitting complaint with payload:');
    print('User ID: $userId');
    print('Department: $selectedDepartmentName');
    print('Name: ${nameController.text}');
    print('Email: ${emailController.text}');
    print('Type: $selectedRequestType');
    print('User Type: $userRole');
    print('Complaint: $complaint');

    // Encode the parameters
    String encodedName = Uri.encodeComponent(nameController.text);
    String encodedEmail = Uri.encodeComponent(emailController.text);
    String encodedComplaint = Uri.encodeComponent(complaint);
    String encodedDepartment = Uri.encodeComponent(selectedDepartmentName ?? '');
    String encodedType = Uri.encodeComponent(selectedRequestType ?? '');


    await ApiService().generateComplaint(
      userId: userId,
      department: encodedDepartment,
      name: encodedName,
      email: encodedEmail,
      type: encodedType,
      userType: userRole,
      complaint: encodedComplaint,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Complaint submitted!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Complaint'),
        backgroundColor: Colors.orange[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Select Request Type:',
                style: TextStyle(fontSize: 18),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.zero,
                ),
                child: DropdownButton<String>(
                  value: selectedRequestType,
                  hint: const Text('Choose Request Type'),
                  isExpanded: true,
                  underline: Container(),
                  items: requestTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(type),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedRequestType = newValue;
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Select Department:',
                style: TextStyle(fontSize: 18),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.zero,
                ),
                child: DropdownButton<String>(
                  value: selectedDepartmentName,
                  hint: const Text('Choose Department'),
                  isExpanded: true,
                  underline: Container(),
                  items: departments.map((Map<String, dynamic> department) {
                    return DropdownMenuItem<String>(
                      value: department['DepartmentName'],
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(department['DepartmentName']),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedDepartmentName = newValue;
                      print('Selected Department: $selectedDepartmentName');
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                child: TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                child: TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Complaint:',
                style: TextStyle(fontSize: 18),
              ),
              Card(
                elevation: 4,
                child: TextField(
                  maxLines: 5,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter your complaint here',
                  ),
                  onChanged: (value) {
                    complaint = value;
                  },
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    if (selectedRequestType != null && selectedDepartmentName != null) {
                      _submitComplaint();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select both fields.')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: const Text('Submit Complaint'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}