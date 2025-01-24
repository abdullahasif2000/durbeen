import 'package:flutter/material.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class EditAttendanceScreen extends StatefulWidget {
  const EditAttendanceScreen({Key? key}) : super(key: key);

  @override
  _EditAttendanceScreenState createState() => _EditAttendanceScreenState();
}

class _EditAttendanceScreenState extends State<EditAttendanceScreen> {
  String? _sessionID;
  String? _courseID;
  String? _sectionID;
  String? _userRole; // Store user role
  List<Map<String, dynamic>> _attendanceRecords = [];
  List<String> _attendanceDates = []; // List to hold attendance dates
  String? _selectedDate; // Selected date from dropdown
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sessionID = prefs.getString('SessionID');
      _userRole = prefs.getString('UserRole'); // Load user role

      // Debug statement to print the user role in the console
      print('Loaded User Role: $_userRole');

      String? courseIDsString = prefs.getString('CourseIDs');
      if (courseIDsString != null) {
        List<dynamic> courseIDsList = jsonDecode(courseIDsString);
        _courseID = courseIDsList.isNotEmpty ? courseIDsList[0].toString() : null;
      } else {
        _courseID = null;
      }

      _sectionID = prefs.getString('SelectedSectionID');
      _isLoading = false;
    });

    // Fetch attendance dates for all roles
    await _fetchAttendanceDates();
  }

  Future<void> _fetchAttendanceRecords() async {
    // Attendance fetching logic for all roles
    if (_sessionID == null || _courseID == null || _sectionID == null || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final records = await ApiService().fetchAttendanceDetails(
        _sessionID!,
        _courseID!,
        _selectedDate!,
      );

      setState(() {
        _attendanceRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _fetchAttendanceDates() async {
    if (_sessionID == null || _courseID == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SessionID or CourseID is missing')),
      );
      return;
    }

    try {
      final dates = await ApiService().fetchAttendanceDates(_sessionID!, _courseID!);
      setState(() {
        _attendanceDates = dates;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching dates: $e')),
      );
    }
  }

  Future<void> _updateAttendanceStatus(String rollNumber, String newStatus) async {
    try {
      await ApiService().updateAttendanceStatus(
        sessionID: _sessionID!,
        courseID: _courseID!,
        sectionID: _sectionID!,
        date: _selectedDate!,
        rollNumber: rollNumber,
        attendanceStatus: newStatus,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance updated successfully')),
      );

      _fetchAttendanceRecords(); // Refresh the attendance records
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating attendance: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Attendance'),
          backgroundColor: Colors.orange[700],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Attendance'),
        backgroundColor: Colors.orange[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Select a Date:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButton<String>(
              hint: const Text('Select Date'),
              value: _selectedDate,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedDate = newValue;
                });
                _fetchAttendanceRecords(); // Fetch attendance for the selected date
              },
              items: _attendanceDates.map<DropdownMenuItem<String>>((String date) {
                return DropdownMenuItem<String>(
                  value: date,
                  child: Text(date),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            if (_error.isNotEmpty)
              Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            if (_attendanceRecords.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Roll Number')),
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Present')),
                      DataColumn(label: Text('Absent')),
                      DataColumn(label: Text('Late')),
                    ],
                    rows: _attendanceRecords.map((record) {
                      String rollNumber = record['RollNumber'] ?? '';
                      String attendanceStatus = record['AttendanceStatus'] ?? '';

                      bool isPresent = attendanceStatus == 'present';
                      bool isAbsent = attendanceStatus == 'absent';
                      bool isLate = attendanceStatus == 'late';

                      return DataRow(cells: [
                        DataCell(Text(rollNumber)),
                        DataCell(Text(record['Date'] ?? '')),
                        DataCell(
                          Checkbox(
                            value: isPresent,
                            onChanged: (value) {
                              if (value != null) {
                                _updateAttendanceStatus(rollNumber, value ? 'present' : (isAbsent ? 'absent' : 'late'));
                              }
                            },
                          ),
                        ),
                        DataCell(
                          Checkbox(
                            value: isAbsent,
                            onChanged: (value) {
                              if (value != null) {
                                _updateAttendanceStatus(rollNumber, value ? 'absent' : (isPresent ? 'present' : 'late'));
                              }
                            },
                          ),
                        ),
                        DataCell(
                          Checkbox(
                            value: isLate,
                            onChanged: (value) {
                              if (value != null) {
                                _updateAttendanceStatus(rollNumber, value ? 'late' : (isPresent ? 'present' : 'absent'));
                              }
                            },
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            if (_attendanceRecords.isEmpty && _error.isEmpty)
              const Center(child: Text('No attendance records found.')),
          ],
        ),
      ),
    );
  }
}