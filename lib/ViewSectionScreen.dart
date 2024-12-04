import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class ViewSectionScreen extends StatefulWidget {
  const ViewSectionScreen({Key? key}) : super(key: key);

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

  // Load SessionID and CourseIDs from SharedPreferences
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    sessionID = prefs.getString('SessionID') ?? '';
    final courseIDsString = prefs.getString('SelectedCourseIDs');
    if (courseIDsString != null) {
      courseIDs = List<String>.from(jsonDecode(courseIDsString));
    }

    // Fetch sections after loading data
    if (sessionID.isNotEmpty && courseIDs.isNotEmpty) {
      setState(() {
        _sectionsFuture = fetchSections();
      });
    } else {
      setState(() {
        _sectionsFuture = Future.value([]);
      });
    }
  }

  // Fetch sections from the API
  Future<List<Map<String, dynamic>>> fetchSections() async {
    List<Map<String, dynamic>> sections = [];
    try {
      for (String courseID in courseIDs) {
        final response = await ApiService().fetchSections(
          courseID: courseID,
          sessionID: sessionID,
        );
        if (response != null && response.isNotEmpty) {
          sections.addAll(response);
        }
      }
    } catch (e) {
      debugPrint('Error fetching sections: $e');
      throw Exception("Failed to fetch sections");
    }
    return sections;
  }

  // Delete section from the API
  Future<void> deleteSection(String sectionID) async {
    try {
      final response = await ApiService().deleteSection(sectionID);
      if (response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Section deleted successfully')),
        );
        _loadData(); // Refresh the list after deletion
      } else {
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
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No sections found.'));
            }

            final sections = snapshot.data!;

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
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deleteSection(section['id']),
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
