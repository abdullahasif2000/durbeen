import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ViewSectionScreen.dart';
import 'AddStudentToSection.dart';
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
  bool isSectionCreated = false;

  // Shared Preferences to get SessionID
  String sessionID = '0';

  // Store section details for displaying in a card
  String? createdSectionName;
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

  // Check if section already exists
  Future<bool> checkIfSectionExists(
      String sectionName, List<String> selectedCourseIDs) async {
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
    return false; // no match found
  }

  // API Call to create a new section
  Future<void> createSection() async {
    // Ensure SessionID is loaded
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

    List<String> createdSectionIDs = []; // List to store SectionIDs for selected courses

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

          // Add the new SectionID to the list
          createdSectionIDs.add(newSectionID);
        } else {
          debugPrint('Failed response: ${response.toString()}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create section for CourseID: $courseID')),
          );
        }
      }

      // Overwrite the list of SectionIDs in SharedPreferences
      if (createdSectionIDs.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();

        // Convert List<String> to JSON String for storage
        String sectionIDsJson = jsonEncode(createdSectionIDs);
        await prefs.setString('CreatedSectionIDs', sectionIDsJson);

        debugPrint('Overwritten SectionIDs: $sectionIDsJson');

        setState(() {
          createdSectionName = sectionName;
          createdCourses = widget.selectedCourses;
          isSectionCreated = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Section(s) "$sectionName" created successfully.')),
        );
      }
    } catch (e) {
      debugPrint('Error creating section: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating section: $e')),
      );
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
              ],
              const SizedBox(height: 20),
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
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddStudentToSectionScreen(cohort: widget.cohort),
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
                    'Add Student',
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
