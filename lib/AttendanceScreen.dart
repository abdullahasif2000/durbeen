
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late Future<List<Map<String, dynamic>>> _studentsFuture;
  List<Map<String, dynamic>> attendanceData = [];
  DateTime? _selectedDate;
  bool _isAttendanceMarked = false; // Track if attendance has been marked

  @override
  void initState() {
    super.initState();
    _studentsFuture = _loadAndFetchStudents();
    _checkAttendanceMarked();
    _selectedDate = DateTime.now(); // Default to today's date
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

  Future<void> _checkAttendanceMarked() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionID = prefs.getString('SessionID');
    final courseID = prefs.getString('CourseIDs') ?? '[]';
    final sectionID = prefs.getString('SelectedSectionID');

    List<dynamic> parsedCourseIDs = [];
    try {
      parsedCourseIDs = jsonDecode(courseID);
    } catch (e) {
      print("Error decoding CourseIDs: $e");
    }

    if (sessionID == null || parsedCourseIDs.isEmpty || sectionID == null) {
      throw Exception("Missing required data for attendance check.");
    }

    try {
      final isMarked = await ApiService().checkAttendanceMarked(
        sessionID: sessionID,
        courseID: parsedCourseIDs.first.toString(),
        sectionID: sectionID,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate!),
      );

      setState(() {
        _isAttendanceMarked = isMarked;
      });

      if (_isAttendanceMarked) {
        // Notify user (Optional)
        showDialog(
          context: context,
          builder: (context) =>
              AlertDialog(
                title: const Text("Attendance Already Marked"),
                content: const Text(
                    "Attendance has already been marked for this date."),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("OK"),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      print("Error checking attendance: $e");
    }
  }


  void _updateAttendance(String rollNumber, String status) {
    if (_isAttendanceMarked) return; // Prevent updates if attendance is marked

    // Check if status is valid
    if (!['present', 'absent', 'late'].contains(status)) return;

    final index = attendanceData.indexWhere((entry) =>
    entry['RollNumber'] == rollNumber);

    if (index == -1) {
      attendanceData.add(
          {'RollNumber': rollNumber, 'AttendanceStatus': status});
    } else {
      attendanceData[index]['AttendanceStatus'] = status;
    }

    setState(() {});
  }

  Future<void> _submitAttendance() async {
    try {
      if (_selectedDate == null) {
        print('Error: Please select a date.');
        return;
      }

      if (_isAttendanceMarked) {
        print('Error: Attendance has already been marked for this date.');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final sessionID = prefs.getString('SessionID');
      final courseID = prefs.getString('CourseIDs') ?? '[]';
      final sectionID = prefs.getString('SelectedSectionID');
      final parsedCourseIDs = jsonDecode(courseID) as List;

      if (sessionID == null || parsedCourseIDs.isEmpty || sectionID == null || attendanceData.isEmpty) {
        print('Error: Missing required data for submission.');
        return;
      }

      setState(() {
        _isAttendanceMarked = true;
      });

      bool allSuccess = true;
      for (final entry in attendanceData) {
        final success = await ApiService().markAttendance(
          rollNumber: entry['RollNumber'],
          courseID: parsedCourseIDs.first.toString(),
          sessionID: sessionID,
          sectionID: sectionID,
          date: DateFormat('yyyy-MM-dd').format(_selectedDate!),
          attendanceStatus: entry['AttendanceStatus'],
        );

        if (!success) {
          allSuccess = false;
        }
      }

      if (allSuccess) {
        setState(() {
          // Retain attendanceData to show statuses but keep interaction disabled
          _isAttendanceMarked = true;
        });
        print('All attendance records successfully submitted.');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Attendance submitted successfully!'),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        print('Some attendance records failed to submit.');
      }
    } catch (e) {
      print('Error while submitting attendance: $e');
    }
  }


  Future<void> _pickDate() async {
    final now = DateTime.now();
    final twoDaysAgo = now.subtract(const Duration(hours: 48));

    final selected = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: twoDaysAgo,
      lastDate: now,
    );

    if (selected != null) {
      setState(() {
        _selectedDate = selected;
      });
      _checkAttendanceMarked(); // Check attendance status after date is picked
    }
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
            mainAxisSize: MainAxisSize.max,
            children: [
              // Date Picker Button
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Text(
                      'Selected Date: ${_selectedDate?.toString().split(' ')[0] ?? 'None'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _pickDate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[700],
                      ),
                      child: const Text('Select Date'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Roll Number')),
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Present')),
                      DataColumn(label: Text('Absent')),
                      DataColumn(label: Text('Late')),
                    ],
                    rows: students.map((student) {
                      final rollNumber = student['RollNumber'] ?? 'N/A';
                      final rowColor = _getRowColor(rollNumber);

                      return DataRow(
                        color: WidgetStateProperty.resolveWith((states) => rowColor),
                        cells: [
                          DataCell(Text(rollNumber)),
                          DataCell(Text(student['Name'] ?? 'N/A')),
                          DataCell(
                            Checkbox(
                              value: _isMarked(rollNumber, 'present'),
                              onChanged: _isAttendanceMarked
                                  ? null // Disable if attendance is marked
                                  : (value) {
                                if (value == true) {
                                  _updateAttendance(rollNumber, 'present');
                                }
                              },
                            ),
                          ),
                          DataCell(
                            Checkbox(
                              value: _isMarked(rollNumber, 'absent'),
                              onChanged: _isAttendanceMarked
                                  ? null // Disable if attendance is marked
                                  : (value) {
                                if (value == true) {
                                  _updateAttendance(rollNumber, 'absent');
                                }
                              },
                            ),
                          ),
                          DataCell(
                            Checkbox(
                              value: _isMarked(rollNumber, 'late'),
                              onChanged: _isAttendanceMarked
                                  ? null // Disable if attendance is marked
                                  : (value) {
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
              ElevatedButton(
                onPressed: _isAttendanceMarked ? null : _submitAttendance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
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
    final index = attendanceData.indexWhere((entry) =>
    entry['RollNumber'] == rollNumber);

    if (index != -1) {
      final status = attendanceData[index]['AttendanceStatus'];
      switch (status) {
        case 'present':
          return Colors.green.withOpacity(0.5);
        case 'absent':
          return Colors.red.withOpacity(0.5);
        case 'late':
          return Colors.yellow.withOpacity(0.5);
        default:
          return Colors.transparent;
      }
    }
    return Colors.transparent;
  }

  bool _isMarked(String rollNumber, String status) {
    final index = attendanceData.indexWhere((entry) =>
    entry['RollNumber'] == rollNumber);
    if (index != -1) {
      return attendanceData[index]['AttendanceStatus'] == status;
    }
    return false;
  }
}

