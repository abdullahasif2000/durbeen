import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'dart:convert';
import 'AttendanceScreen.dart';
import 'ViewAttendanceScreen.dart';
import 'EditAttendanceScreen.dart';

class SelectSectionScreen extends StatefulWidget {
  final String option; // Make this non-nullable

  const SelectSectionScreen({Key? key, required this.option}) : super(key: key);

  @override
  _SelectSectionScreenState createState() => _SelectSectionScreenState();
}

class _SelectSectionScreenState extends State<SelectSectionScreen> {
  late Future<List<Map<String, dynamic>>> _sectionsFuture;

  @override
  void initState() {
    super.initState();
    _sectionsFuture = _fetchSectionsWithStudentCounts();
  }

  Future<List<Map<String, dynamic>>> _fetchSectionsWithStudentCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('SessionID');
    final courseIdsString = prefs.getString('CourseIDs');

    if (sessionId == null || courseIdsString == null) {
      throw Exception("SessionID or CourseIDs not found in SharedPreferences");
    }

    List<dynamic> courseIds = List.from(jsonDecode(courseIdsString));
    List<Map<String, dynamic>> allSections = [];

    for (var courseId in courseIds) {
      final sections = await ApiService().fetchSections(
        sessionID: sessionId,
        courseID: courseId.toString(),
      );

      for (var section in sections) {
        // Fetch total students for each section
        final totalStudents = await _fetchTotalStudents(
          sessionId,
          courseId.toString(),
          section['id'].toString(),
        );
        section['totalStudents'] = totalStudents; // Add total students to section map
      }

      allSections.addAll(sections);
    }

    return allSections;
  }

  Future<int> _fetchTotalStudents(String sessionId, String courseId, String sectionId) async {
    final students = await ApiService().fetchMappedStudents(
      SessionID: sessionId,
      CourseID: courseId,
      SectionID: sectionId,
    );
    return students.length; // Return the total number of students
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Section',
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
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No sections available.'));
            }

            final sections = snapshot.data!;

            return ListView.builder(
              itemCount: sections.length,
              itemBuilder: (context, index) {
                final section = sections[index];

                return GestureDetector(
                  onTap: () async {
                    // Save SectionID to SharedPreferences
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('SelectedSectionID', section['id'].toString());

                    // Print the saved SectionID to console
                    print('Selected SectionID: ${section['id']}');

                    // Navigate to the appropriate screen based on the option
                    if (widget.option == 'Mark') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AttendanceScreen(),
                        ),
                      );
                    } else if (widget.option == 'View') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ViewAttendanceScreen(),
                        ),
                      );
                    } else if (widget.option == 'Edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditAttendanceScreen(),
                        ),
                      );
                    }
                  },
                  child: Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Display Section Name in bold
                              Text(
                                section['SectionName'] ?? 'N/A',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              const SizedBox(height: 8),
                              Text('CourseID: ${section['CourseID'] ?? 'N/A'}'),
                              Text('Session ID: ${section['SessionID'] ?? 'N/A'}'),
                              Text('Total Students: ${section['totalStudents'] ?? 0}'),
                            ],
                          ),
                          const Icon(
                            Icons.calendar_month,
                            color: Colors.orange,
                            size: 30,
                          ),
                        ],
                      ),
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
