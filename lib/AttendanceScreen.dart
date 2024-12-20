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
  List<Map<String, dynamic>> attendanceData = [];

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

  void _updateAttendance(String rollNumber, String status) {
    final index =
    attendanceData.indexWhere((entry) => entry['RollNumber'] == rollNumber);

    if (index == -1) {
      attendanceData.add({'RollNumber': rollNumber, 'AttendanceStatus': status});
    } else {
      attendanceData[index]['AttendanceStatus'] = status;
    }

    setState(() {});
  }

  Future<void> _submitAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionID = prefs.getString('SessionID');
    final courseID = prefs.getString('CourseIDs') ?? '[]';
    final sectionID = prefs.getString('SelectedSectionID');
    final parsedCourseIDs = jsonDecode(courseID) as List;

    if (sessionID == null ||
        parsedCourseIDs.isEmpty ||
        sectionID == null ||
        attendanceData.isEmpty) {
      print('Error: Missing required data for submission.');
      return;
    }

    for (final entry in attendanceData) {
      final success = await ApiService().markAttendance(
        rollNumber: entry['RollNumber'],
        courseID: parsedCourseIDs.first.toString(),
        sessionID: sessionID,
        sectionID: sectionID,
        date: DateTime.now().toString().split(' ')[0],
        attendanceStatus: entry['AttendanceStatus'],
      );

      if (success) {
        print('Attendance submitted for Roll Number: ${entry['RollNumber']}');
      } else {
        print(
            'Failed to submit attendance for Roll Number: ${entry['RollNumber']}');
      }
    }

    setState(() {
      attendanceData.clear(); // Clear the data after submission
    });

    print('All attendance records submitted.');
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

          return Column(
            mainAxisSize: MainAxisSize.max, // Ensure the column takes the full height
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.zero, // Remove any padding
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Roll Number')),
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Present')),
                        DataColumn(label: Text('Absent')),
                        DataColumn(label: Text('Late')),
                      ],
                      rows: students.map((student) {
                        final rollNumber = student['RollNumber'] ?? 'N/A';
                        final rowColor = _getRowColor(rollNumber);

                        return DataRow(
                          color: MaterialStateProperty.resolveWith(
                                  (states) => rowColor),
                          cells: [
                            DataCell(Text(rollNumber)),
                            DataCell(Text(student['Name'] ?? 'N/A')),
                            DataCell(
                              Text(DateTime.now().toString().split(' ')[0]),
                            ),
                            DataCell(
                              Checkbox(
                                value: _isMarked(rollNumber, 'present'),
                                onChanged: (value) {
                                  if (value == true) {
                                    _updateAttendance(rollNumber, 'present');
                                  }
                                },
                              ),
                            ),
                            DataCell(
                              Checkbox(
                                value: _isMarked(rollNumber, 'absent'),
                                onChanged: (value) {
                                  if (value == true) {
                                    _updateAttendance(rollNumber, 'absent');
                                  }
                                },
                              ),
                            ),
                            DataCell(
                              Checkbox(
                                value: _isMarked(rollNumber, 'late'),
                                onChanged: (value) {
                                  if (value == true) {
                                    _updateAttendance(rollNumber, 'late');
                                  }
                                },
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              // Directly place the button without a SizedBox
              ElevatedButton(
                onPressed: _submitAttendance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700], // Set button color
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
                child: const Text(
                  'Submit Attendance',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }


  Color _getRowColor(String rollNumber) {
    final index = attendanceData
        .indexWhere((entry) => entry['RollNumber'] == rollNumber);

    if (index != -1) {
      final status = attendanceData[index]['AttendanceStatus'];
      switch (status) {
        case 'present':
          return Colors.green.withOpacity(0.5);
        case 'absent':
          return Colors.red.withOpacity(0.5);
        case 'late':
          return Colors.blue.withOpacity(0.5);
      }
    }
    return Colors.transparent;
  }

  bool _isMarked(String rollNumber, String status) {
    final index = attendanceData
        .indexWhere((entry) => entry['RollNumber'] == rollNumber);
    if (index != -1) {
      return attendanceData[index]['AttendanceStatus'] == status;
    }
    return false;
  }
}
