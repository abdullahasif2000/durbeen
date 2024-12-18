import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'dart:convert';

class SelectSectionScreen extends StatefulWidget {
  const SelectSectionScreen({Key? key}) : super(key: key);

  @override
  _SelectSectionScreenState createState() => _SelectSectionScreenState();
}

class _SelectSectionScreenState extends State<SelectSectionScreen> {
  late Future<List<Map<String, dynamic>>> _sectionsFuture;

  @override
  void initState() {
    super.initState();
    _sectionsFuture = _fetchSections();
  }

  Future<List<Map<String, dynamic>>> _fetchSections() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('SessionID'); // Assuming SessionID is stored as a string
    final courseIdsString = prefs.getString('CourseIDs');

    // Log the retrieved SessionID and CourseIDs
    print('Retrieved SessionID: $sessionId');
    print('Retrieved CourseIDs: $courseIdsString');

    if (sessionId == null || courseIdsString == null) {
      throw Exception("SessionID or CourseIDs not found in SharedPreferences");
    }

    // Convert the CourseIDs string back to a list
    List<dynamic> courseIds = List.from(jsonDecode(courseIdsString));
    print('Parsed CourseIDs: $courseIds');

    List<Map<String, dynamic>> allSections = [];

    // Fetch sections for each CourseID
    for (var courseId in courseIds) {
      print('Fetching sections for CourseID: $courseId');
      final sections = await ApiService().fetchSections(
        sessionID: sessionId,
        courseID: courseId.toString(),
      );

      // Log the fetched sections
      print('Fetched sections for CourseID $courseId: $sections');

      allSections.addAll(sections);
    }

    return allSections;
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
                // Log the section data
                print('Section data at index $index: $section');

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Section ID: ${section['id'] ?? 'N/A'}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text('Course ID: ${section['CourseID'] ?? 'N/A'}'),
                        Text('Section Name: ${section['SectionName'] ?? 'N/A'}'),
                        Text('Session ID: ${section['SessionID'] ?? 'N/A'}'),

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