import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'AddStudentToSection.dart';
import 'api_service.dart';

class CreateSectionScreen extends StatefulWidget {
  final String cohort;
  final List<Map<String, dynamic>> selectedCourses;

  const CreateSectionScreen({
    required this.cohort,
    required this.selectedCourses,
    super.key,
  });

  @override
  _CreateSectionScreenState createState() => _CreateSectionScreenState();
}

class _CreateSectionScreenState extends State<CreateSectionScreen> {
  final TextEditingController sectionController = TextEditingController();
  List<String> studentRollNumbers = [];
  bool isSectionCreated = false;

  // Shared Preferences to get SessionID
  late String sessionID;

  // Store section details for displaying in a card
  String? createdSectionName;
  String? createdSectionID;
  List<Map<String, dynamic>>? createdCourses;

  @override
  void initState() {
    super.initState();
    _loadSessionID();
  }

  Future<void> _loadSessionID() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      sessionID = prefs.getString('SessionID') ?? '';
    });
    debugPrint('Loaded SessionID: $sessionID'); // Debugging session ID load
  }

  // API Call to create a new section
  Future<void> createSection() async {
    String sectionName = sectionController.text.trim();

    if (sectionName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Section name is required')),
      );
      return;
    }

    if (widget.selectedCourses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No courses selected!')),
      );
      return;
    }

    try {
      for (var course in widget.selectedCourses) {
        String courseID = course['CourseID'].toString();

        // Make the API call
        final response = await ApiService().createNewSection(
          courseID: courseID,
          sectionName: sectionName,
          sessionID: sessionID,
        );

        if (response['status'] == 'success') {
          String newSectionID = response['SectionID'].toString(); // Extract SectionID
          debugPrint('New SectionID: $newSectionID'); // Log the SectionID for debugging

          // Optionally store the SectionID in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('NewSectionID', newSectionID);
          debugPrint('Stored SectionID in SharedPreferences: $newSectionID');

          // Store section details for displaying in a card
          setState(() {
            createdSectionName = sectionName;
            createdSectionID = newSectionID;
            createdCourses = widget.selectedCourses;
            isSectionCreated = true;
          });

          // Display success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Section "$sectionName" created successfully with SectionID: $newSectionID')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create section for Course: ${course['Name']}')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating section: $e')),
      );
    }
  }

  // Navigate to AddStudentToSection and update student list after adding students
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
      debugPrint('Updated Roll Numbers: $updatedRollNumbers'); // Debugging added students
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
                // Display the created section details in a card
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
                        Text(
                          'Section Created Successfully!',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text('Section Name: $createdSectionName'),
                        Text('Section ID: $createdSectionID'),
                        const SizedBox(height: 10),
                        Text(
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
            ],
          ),
        ),
      ),
    );
  }
}
