import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'AddMoreStudents.dart';

class ViewSectionScreen extends StatefulWidget {
  final String cohort;
  const ViewSectionScreen({Key? key, required this.cohort}) : super(key: key);

  @override
  _ViewSectionScreenState createState() => _ViewSectionScreenState();
}

class _ViewSectionScreenState extends State<ViewSectionScreen> {
  late Future<List<Map<String, dynamic>>> _sectionsFuture = Future.value([]);
  String sessionID = '';
  List<String> courseIDs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    sessionID = prefs.getString('SessionID') ?? '';
    final courseIDsString = prefs.getString('SelectedCourseIDs');
    if (courseIDsString != null) {
      courseIDs = List<String>.from(jsonDecode(courseIDsString));
    }

    debugPrint("SessionID loaded: $sessionID");
    debugPrint("CourseIDs loaded: $courseIDs");

    if (sessionID.isNotEmpty && courseIDs.isNotEmpty) {
      setState(() {
        _sectionsFuture = fetchSections();
      });
    } else {
      debugPrint("No SessionID or CourseIDs available to fetch sections.");
      setState(() {
        _sectionsFuture = Future.value([]);
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchSections() async {
    List<Map<String, dynamic>> sections = [];
    try {
      for (String courseID in courseIDs) {
        debugPrint("Fetching sections for CourseID: $courseID, SessionID: $sessionID");
        final response = await ApiService().fetchSections(
          courseID: courseID,
          sessionID: sessionID,
        );
        if (response != null && response.isNotEmpty) {
          for (var section in response) {
            final sectionID = section['id'];
            final students = await ApiService().fetchMappedStudents(
              SessionID: sessionID,
              CourseID: courseID,
              SectionID: sectionID,
            );
            section['studentCount'] = students.length;
          }
          sections.addAll(response);
        } else {
          debugPrint("No sections found for CourseID $courseID.");
        }
      }
    } catch (e) {
      debugPrint('Error fetching sections: $e');
      throw Exception("Failed to fetch sections");
    }
    return sections;
  }

  Future<void> deleteSection(String sectionID) async {
    try {
      debugPrint("Attempting to delete section with ID: $sectionID");
      final response = await ApiService().deleteSection(sectionID);
      debugPrint("Delete response: $response");

      if (response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Section deleted successfully')),
        );
        _loadData();
      } else {
        debugPrint("Failed to delete section. Response: $response");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete section')),
        );
      }
    } catch (e) {
      debugPrint('Error deleting section: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting section: $e')),
      );
    }
  }

  void _confirmDelete(String sectionID) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text(
            'Are you sure you want to delete this section?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop();
                deleteSection(sectionID);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'View Sections',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 24),
        ),
        backgroundColor: Colors.orange[700],
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _sectionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              debugPrint("Error in FutureBuilder: ${snapshot.error}");
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              debugPrint("No sections found.");
              return const Center(child: Text('No sections found.'));
            }

            final sections = snapshot.data!;

            debugPrint("Sections to display: $sections");

            return ListView.builder(
              itemCount: sections.length,
              itemBuilder: (context, index) {
                final section = sections[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 3,
                  child: ListTile(
                    title: Text(
                      'Section Name: ${section['SectionName']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Section ID: ${section['id']}'),
                        Text('Course ID: ${section['CourseID']}'),
                        Text('Total Students: ${section['studentCount']}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.person_add_alt_1, color: Colors.blue),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddMoreStudents(
                                  sectionID: section['id'],
                                  courseID: section['CourseID'],
                                  cohort: widget.cohort,
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(section['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}