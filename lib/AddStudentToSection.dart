import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AddStudentToSectionScreen extends StatefulWidget {
  final String cohort;

  AddStudentToSectionScreen({required this.cohort});

  @override
  _AddStudentToSectionScreenState createState() =>
      _AddStudentToSectionScreenState();
}

class _AddStudentToSectionScreenState extends State<AddStudentToSectionScreen> {
  List<Map<String, dynamic>> students = [];
  String? selectedRollNumber;
  List<String> sectionIDs = [];
  List<String> courseIDs = [];
  String? sessionID;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      // Retrieve SessionID
      sessionID = prefs.getString('SessionID');

      // Retrieve SectionIDs
      final sectionData = prefs.getString('CreatedSectionIDs');
      if (sectionData != null) {
        try {
          sectionIDs = List<String>.from(jsonDecode(sectionData));
        } catch (e) {
          print("Error parsing SectionIDs: $e");
          sectionIDs = [];
        }
      }

      // Retrieve CourseIDs
      final courseData = prefs.getString('CourseIDs');
      if (courseData != null) {
        try {
          courseIDs = List<String>.from(jsonDecode(courseData));
        } catch (e) {
          print("Error parsing CourseIDs: $e");
          courseIDs = [];
        }
      }
    });

    // Debugging info
    print("SessionID: $sessionID");
    print("SectionIDs: $sectionIDs");
    print("CourseIDs: $courseIDs");

    // Fetch students based on the cohort
    await _fetchStudents();
    // Fetch students already added to the section
    await _fetchMappedStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      final fetchedStudents =
      await ApiService().fetchStudentsByCohort(widget.cohort);
      setState(() {
        students = fetchedStudents;
      });
    } catch (e) {
      print('Error fetching students: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch students')),
      );
    }
  }

  Future<void> _fetchMappedStudents() async {
    if (sessionID == null || sectionIDs.isEmpty || courseIDs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid SessionID, SectionIDs, or CourseIDs.')),
      );
      return;
    }

    try {
      List<Map<String, dynamic>> allMappedStudents = [];
      for (int i = 0; i < sectionIDs.length; i++) {
        final sectionID = sectionIDs[i];
        final courseID = courseIDs[i];
        final mappedStudents = await ApiService().fetchMappedStudents(
          sessionID: sessionID!,
          sectionID: sectionID,
          courseID: courseID,
        );

        allMappedStudents.addAll(mappedStudents);
      }

      setState(() {
        students = allMappedStudents;
      });
    } catch (e) {
      print('Error fetching mapped students: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch mapped students')),
      );
    }
  }

  Future<void> _mapStudentToSections(String rollNumber) async {
    if (sessionID == null || sectionIDs.isEmpty || courseIDs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid SessionID, SectionIDs, or CourseIDs.')),
      );
      return;
    }

    try {
      for (int i = 0; i < sectionIDs.length; i++) {
        final sectionID = sectionIDs[i];
        final courseID = courseIDs[i];
        final success = await ApiService().addStudentToSection(
          sessionID: sessionID!,
          sectionID: sectionID,
          courseID: courseID,
          rollNumber: rollNumber,
        );

        if (success) {
          print('Student added successfully to Section $sectionID for Course $courseID!');
        } else {
          print('Failed to add student to Section $sectionID for Course $courseID.');
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Student mapped to all sections successfully!')),
      );

      // Fetch updated list of students after mapping
      await _fetchMappedStudents();
    } catch (e) {
      print('Error mapping student: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error mapping student to sections.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: AppBar(
          title: Text('Map Students to Sections'),
          backgroundColor: Colors.orange[700],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: selectedRollNumber,
              hint: Text('Select Student Roll Number'),
              items: students.map((student) {
                return DropdownMenuItem<String>(
                  value: student['RollNumber'],
                  child: Text('${student['RollNumber']} - ${student['Name']}'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedRollNumber = value;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: selectedRollNumber == null
                  ? null
                  : () async {
                await _mapStudentToSections(selectedRollNumber!);
              },
              child: Text('Map Selected Student to All Sections'),
            ),
            SizedBox(height: 20),
            Text(
              'Students Added to Sections',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  return Card(
                    child: ListTile(
                      title: Text('Roll Number: ${student['RollNumber']}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Name: ${student['Name']}'),
                          Text('Session ID: ${student['SessionID']}'),
                          Text('Section ID: ${student['SectionID']}'),
                          Text('Course ID: ${student['CourseID']}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
