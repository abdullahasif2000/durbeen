import 'package:flutter/material.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ViewAttendanceScreen extends StatefulWidget {
  const ViewAttendanceScreen({Key? key}) : super(key: key);

  @override
  _ViewAttendanceScreenState createState() => _ViewAttendanceScreenState();
}

class _ViewAttendanceScreenState extends State<ViewAttendanceScreen> {
  String? _sessionID;
  String? _courseID;
  String? _sectionID;
  String? _role;
  String? _rollNumber;
  List<Map<String, dynamic>> _attendanceRecords = [];
  List<String> _attendanceDates = [];
  String? _selectedDate;
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
      _role = prefs.getString('UserRole');
      _rollNumber = prefs.getString('RollNumber');

      String? courseIDsString = prefs.getString('CourseIDs');
      if (courseIDsString != null) {
        List<dynamic> courseIDsList = jsonDecode(courseIDsString);
        _courseID = courseIDsList.isNotEmpty ? courseIDsList[0].toString() : null;
      } else {
        _courseID = null;
      }

      _sectionID = prefs.getString('SelectedSectionID');
    });

    // Debugging output
    print('SessionID: $_sessionID');
    print('CourseID: $_courseID');
    print('SectionID: $_sectionID');
    print('Role: $_role');
    print('RollNumber: $_rollNumber');

    // Fetch attendance dates for all roles
    await _fetchAttendanceDates();
    setState(() {
      _isLoading = false; // Set loading to false after fetching dates
    });

    // Automatically fetch attendance for students
    if (_role == 'Student') {
      _fetchAttendanceRecords(); // Fetch attendance records for the student
    }
  }

  Future<void> _fetchAttendanceRecords() async {
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
        _sectionID!, // Pass SectionID here
      );

      // If the role is Student, filter the records by RollNumber
      if (_role == 'Student') {
        _attendanceRecords = records.where((record) => record['RollNumber'] == _rollNumber).toList();
      } else {
        _attendanceRecords = records; // For other roles, show all records
      }

      setState(() {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('View Attendance'),
          backgroundColor: Colors.orange[700],
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('View Attendance'),
        backgroundColor: Colors.orange[700],
        centerTitle: true,
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
                  scrollDirection: Axis.vertical, // Enable vertical scrolling
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal, // Enable horizontal scrolling
                    child: DataTable(
                      columns: [
                        if (_role != 'Student')
                          const DataColumn(label: Text('Roll Number')),
                        const DataColumn(label: Text('Name')),
                        const DataColumn(label: Text('Date')),
                        const DataColumn(label: Text('Attendance Status')),
                        const DataColumn(label: Text('Warnings Sent')),

                      ],
                      rows: _attendanceRecords.map((record) {
                        return DataRow(cells: [
                          if (_role != 'Student')
                            DataCell(Text(record['RollNumber'] ?? '')),
                          DataCell(Text(record['Name'] ?? '')),
                          DataCell(Text(record['Date'] ?? '')),
                          DataCell(Text(record['AttendanceStatus'] ?? '')),
                          DataCell(Text(record['WarningsSent'] ?? '')),

                        ]);
                      }).toList(),
                    ),
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