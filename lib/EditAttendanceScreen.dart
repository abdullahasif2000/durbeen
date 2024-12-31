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
  final TextEditingController _dateController = TextEditingController();
  String? _sessionID;
  String? _courseID;
  String? _sectionID;
  String? _userRole; // Store user role
  List<Map<String, dynamic>> _attendanceRecords = [];
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
      _userRole = prefs.getString('User  Role'); // Load user role

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
  }

  Future<void> _fetchAttendanceRecords() async {
    if (_sessionID == null || _courseID == null || _sectionID == null || _dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    DateTime selectedDate = DateTime.parse(_dateController.text);

    // Validate date for faculty role
    if (_userRole == 'Faculty') {
      DateTime now = DateTime.now();
      DateTime facultyLimitDate = now.subtract(const Duration(hours: 48));

      if (selectedDate.isBefore(facultyLimitDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Faculty can only edit attendance for the last 48 hours')),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final records = await ApiService().fetchAttendanceRecords(
        sessionID: _sessionID!,
        courseID: _courseID!,
        sectionID: _sectionID!,
        date: _dateController.text,
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

  Future<void> _updateAttendanceStatus(String rollNumber, String newStatus) async {
    try {
      await ApiService().updateAttendanceStatus(
        sessionID: _sessionID!,
        courseID: _courseID!,
        sectionID: _sectionID!,
        date: _dateController.text,
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
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Enter Date (YYYY-MM-DD)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.datetime,
              onTap: () async {
                DateTime now = DateTime.now();
                DateTime firstDate;

                if (_userRole == 'Faculty') {
                  firstDate = now.subtract(const Duration(hours: 48));
                } else {
                  firstDate = DateTime(2000);
                }

                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: now,
                  firstDate: firstDate,
                  lastDate: now,
                );

                if (picked != null) {
                  setState(() {
                    _dateController.text = "${picked.toLocal()}".split(' ')[0];
                  });
                }
              },
              readOnly: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchAttendanceRecords,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
              ),
              child: const Text('Fetch Attendance'),
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