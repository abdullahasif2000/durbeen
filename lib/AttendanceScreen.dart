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
  bool _isAttendanceMarked = false;
  bool isLoading = false;
  String? _userRole; // Store user role

  @override
  void initState() {
    super.initState();
    _studentsFuture = _loadAndFetchStudents();
    _checkAttendanceMarked();
    _selectedDate = DateTime.now();
  }

  Future<List<Map<String, dynamic>>> _loadAndFetchStudents() async {
    final prefs = await SharedPreferences.getInstance();
    _userRole = prefs.getString('UserRole'); // Load user role

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

    final students = await ApiService().fetchMappedStudents(
      SessionID: sessionID,
      CourseID: parsedCourseIDs.first.toString(),
      SectionID: sectionID,
    );

    // Initialize attendanceData with all students as present
    attendanceData = students.map((student) {
      return {
        'RollNumber': student['RollNumber'],
        'AttendanceStatus': 'present', // Default status
      };
    }).toList();

    return students;
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
      // Check attendance for the selected course and date
      final isMarked = await ApiService().checkAttendanceMarked(
        sessionID: sessionID,
        courseID: parsedCourseIDs.first.toString(), // Use the current course ID
        sectionID: sectionID,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate!),
      );

      setState(() {
        _isAttendanceMarked = isMarked;
      });

    } catch (e) {
      print('Error checking attendance: $e');
    }
  }

  void _updateAttendance(String rollNumber, String status) {
    if (_isAttendanceMarked) return; // Prevent updates if attendance is marked

    // Check if status is valid
    if (!['present', 'absent', 'late'].contains(status)) return;

    final index = attendanceData.indexWhere((entry) =>
    entry['RollNumber'] == rollNumber);

    if (index == -1) {
      // If the student is not in attendanceData, add them with the selected status
      attendanceData.add({
        'RollNumber': rollNumber,
        'AttendanceStatus': status,
      });
    } else {
      // Update the attendance status
      attendanceData[index]['AttendanceStatus'] = status;
    }

    setState(() {});
  }

  Future<void> _submitAttendance() async {
    try {
      if (_selectedDate == null) {
        _showErrorDialog('Error: Please select a date.');
        return;
      }

      if (_isAttendanceMarked) {
        _showErrorDialog('Error: Attendance has already been marked for this date.');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final sessionID = prefs.getString('SessionID');
      final courseID = prefs.getString('CourseIDs') ?? '[]';
      final sectionID = prefs.getString('SelectedSectionID');
      final parsedCourseIDs = jsonDecode(courseID) as List;

      if (sessionID == null || parsedCourseIDs.isEmpty || sectionID == null || attendanceData.isEmpty) {
        _showErrorDialog('Error: Missing required data for submission.');
        return;
      }

      // Retrieve UserID based on role
      String userID;
      String type = prefs.getString('UserRole') ?? ''; // Get the role for Type

      if (type == 'Faculty') {
        userID = prefs.getString('FacultyID') ?? ''; // Get FacultyID
      } else if (type == 'Admin') {
        userID = prefs.getString('AdminID') ?? ''; // Get AdminID
      } else {
        _showErrorDialog('Error: Invalid user role.');
        return;
      }

      // Show loading dialog
      final loadingDialog = AlertDialog(
        content: Row(
          children: const [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("Submitting attendance..."),
          ],
        ),
      );

      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing the dialog by tapping outside
        builder: (BuildContext context) {
          return loadingDialog;
        },
      );

      bool allSuccess = true;
      for (final entry in attendanceData) {
        final success = await ApiService().markAttendance(
          rollNumber: entry['RollNumber'],
          courseID: parsedCourseIDs.first.toString(),
          sessionID: sessionID,
          sectionID: sectionID,
          date: DateFormat('yyyy-MM-dd').format(_selectedDate!),
          attendanceStatus: entry['AttendanceStatus'],
          userID: userID, // Pass the UserID
          type: type,     // Pass the Type
        );

        if (!success) {
          allSuccess = false;
        }
      }

      Navigator.of(context).pop(); // Dismiss the loading dialog

      if (allSuccess) {
        setState(() {
          // Retain attendanceData to show statuses but keep interaction disabled
          _isAttendanceMarked = true;
        });
        print('All attendance records successfully submitted.');

        // Show success message
        _showSuccessDialog('Attendance submitted successfully!');
      } else {
        print('Some attendance records failed to submit.');
        _showErrorDialog('Some attendance records failed to submit.');
      }
    } catch (e) {
      print('Error while submitting attendance: $e');
      _showErrorDialog('Error while submitting attendance: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    DateTime? firstDate;

    // Set the first date based on user role
    if (_userRole == 'Admin') {
      firstDate = DateTime(2000); // No limit, set to a very early date
    } else {
      firstDate = now; // Limit to the current date for Faculty
    }

    final selected = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: firstDate,
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
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 8.0, // Adjust spacing between columns
                      dataRowHeight: 40.0, // Adjust height of each row
                      columns: [
                        DataColumn(label: Container(width: 80, child: const Text('Roll Number', style: TextStyle(fontSize: 14)))),
                        DataColumn(label: Container(width: 120, child: const Text('Name', style: TextStyle(fontSize: 14)))),
                        DataColumn(label: Container(width: 60, child: const Text('Present', style: TextStyle(fontSize: 14)))),
                        DataColumn(label: Container(width: 60, child: const Text('Absent', style: TextStyle(fontSize: 14)))),
                        DataColumn(label: Container(width: 60, child: const Text('Late', style: TextStyle(fontSize: 14)))),
                      ],
                      rows: students.map((student) {
                        final rollNumber = student['RollNumber'] ?? 'N/A';
                        final rowColor = _getRowColor(rollNumber);

                        return DataRow(
                          color: MaterialStateProperty.resolveWith((states) => rowColor),
                          cells: [
                            DataCell(Text(rollNumber, style: const TextStyle(fontSize: 14))),
                            DataCell(Text(student['Name'] ?? 'N/A', style: const TextStyle(fontSize: 14))),
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
    return status == 'present'; // By default, "Present" is selected
  }
}