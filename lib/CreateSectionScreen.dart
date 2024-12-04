import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'AddStudentToSection.dart';
import 'ViewSectionScreen.dart';
import 'api_service.dart';

class CreateSectionScreen extends StatefulWidget {
  final String cohort;
  final List<Map<String, dynamic>> selectedCourses;

  const CreateSectionScreen({
    required this.cohort,
    required this.selectedCourses,
    Key? key,
  }) : super(key: key);

  @override
  _CreateSectionScreenState createState() => _CreateSectionScreenState();
}

class _CreateSectionScreenState extends State<CreateSectionScreen> {
  final TextEditingController sectionController = TextEditingController();
  List<String> studentRollNumbers = [];
  bool isSectionCreated = false;

  // Shared Preferences to get SessionID
  String sessionID = '0';

  // Store section details for displaying in a card
  String? createdSectionName;
  String? createdSectionID;
  List<Map<String, dynamic>>? createdCourses;

  @override
  void initState() {
    super.initState();
    _loadSessionID();
  }

  // Load SessionID from SharedPreferences
  Future<void> _loadSessionID() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      sessionID = prefs.getString('SessionID') ?? '';
    });
    debugPrint('Loaded SessionID: $sessionID');
  }

  // Retrieve the selected CourseIDs from SharedPreferences
  Future<List<String>> _getSelectedCourseIDs() async {
    final prefs = await SharedPreferences.getInstance();
    final courseIDsString = prefs.getString('SelectedCourseIDs');
    if (courseIDsString != null) {
      return List<String>.from(jsonDecode(courseIDsString));
    }
    return [];
  }

  // check if section already exists
  Future<bool> checkIfSectionExists(String sectionName, List<String> selectedCourseIDs) async {
    try {
      for (var courseID in selectedCourseIDs) {
        // Make the API call to fetch sections for the course
        final response = await ApiService().fetchSections(
          courseID: courseID,
          sessionID: sessionID,
        );

        // Check if any of the fetched sections already have the same name
        for (var section in response) {
          if (section['SectionName'] == sectionName) {
            return true;
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking existing sections: $e');
      return false;
    }
    return false; //no match found
  }

  // API Call to create a new section
  Future<void> createSection() async {
    // make sure SessionID is loaded
    if (sessionID.isEmpty || sessionID == '0') {
      await _loadSessionID();
    }

    if (sessionID.isEmpty || sessionID == '0') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SessionID is not loaded properly.')),
      );
      return;
    }

    String sectionName = sectionController.text.trim();

    if (sectionName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Section name is required')),
      );
      return;
    }

    // Retrieve selected CourseIDs from SharedPreferences
    final selectedCourseIDs = await _getSelectedCourseIDs();
    if (selectedCourseIDs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No courses selected!')),
      );
      return;
    }

    // Check if the section name already exists for the selected courses
    bool isSectionExist = await checkIfSectionExists(sectionName, selectedCourseIDs);
    if (isSectionExist) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Section name already exists!')),
      );
      return;
    }

    try {
      for (var courseID in selectedCourseIDs) {
        // API call to create the section
        final response = await ApiService().createNewSection(
          courseID: courseID,
          sectionName: sectionName,
          sessionID: sessionID,
        );

        if (response['status'] == 'success') {
          String newSectionID = response['SectionID'].toString();
          debugPrint('New SectionID: $newSectionID');

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('NewSectionID', newSectionID);

          setState(() {
            createdSectionName = sectionName;
            createdSectionID = newSectionID;
            createdCourses = widget.selectedCourses;
            isSectionCreated = true;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Section "$sectionName" created successfully with SectionID: $newSectionID')),
          );
        } else {
          debugPrint('Failed response: ${response.toString()}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create section for CourseID: $courseID')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error creating section: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating section: $e')),
      );
    }
  }

  // Add students to section
  void addStudents() async {
    final updatedRollNumbers = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => AddStudentToSection(
          cohort: widget.cohort,
          selectedCourses: widget.selectedCourses,
        ),
      ),
    );

    if (updatedRollNumbers != null) {
      debugPrint('Updated Roll Numbers: $updatedRollNumbers');
      setState(() {
        studentRollNumbers = updatedRollNumbers;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Section',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 24),
        ),
        backgroundColor: Colors.orange[700],
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: TextEditingController(text: widget.cohort),
                decoration: const InputDecoration(
                  labelText: 'Cohort',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: sectionController,
                decoration: const InputDecoration(
                  labelText: 'Section Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: createSection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Create Section',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (isSectionCreated) ...[
                Card(
                  margin: const EdgeInsets.only(top: 20),
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
                          'Section Created Successfully!',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text('Section Name: $createdSectionName'),
                        Text('Section ID: $createdSectionID'),
                        const SizedBox(height: 10),
                        const Text(
                          'Courses:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        for (var course in createdCourses ?? [])
                          Text(
                            '- ${course['Name']} (Faculty: ${course['FacultyName']})',
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: addStudents,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Add Students to Section',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              // Add the "View Sections" button here
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ViewSectionScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'View Sections',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
