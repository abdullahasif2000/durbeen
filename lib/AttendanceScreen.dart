import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late Future<List<Map<String, dynamic>>> _studentsFuture;

  @override
  void initState() {
    super.initState();
    _studentsFuture = _loadAndFetchStudents();
  }

  Future<List<Map<String, dynamic>>> _loadAndFetchStudents() async {
    final prefs = await SharedPreferences.getInstance();

    final sessionID = prefs.getString('SessionID');
    final courseID = prefs.getString('CourseIDs') ?? '[]';
    final sectionID = prefs.getString('SelectedSectionID');

    if (sessionID == null || courseID.isEmpty || sectionID == null) {
      throw Exception("Missing required data from SharedPreferences.");
    }

    final parsedCourseIDs = jsonDecode(courseID) as List;
    if (parsedCourseIDs.isEmpty) {
      throw Exception("CourseIDs list is empty.");
    }

    return await ApiService().fetchMappedStudents(
      SessionID: sessionID,
      CourseID: parsedCourseIDs.first.toString(),
      SectionID: sectionID,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: Colors.orange[700],
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _studentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No students found.'));
          }

          final students = snapshot.data!;

          return SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Roll Number')),
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Session ID')),
                DataColumn(label: Text('Course ID')),
                DataColumn(label: Text('Section ID')),
              ],
              rows: students.map((student) {
                return DataRow(cells: [
                  DataCell(Text(student['RollNumber'] ?? 'N/A')),
                  DataCell(Text(student['Name'] ?? 'N/A')),
                  DataCell(Text(student['SessionID'] ?? 'N/A')),
                  DataCell(Text(student['CourseID'] ?? 'N/A')),
                  DataCell(Text(student['SectionID'] ?? 'N/A')),
                ]);
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}