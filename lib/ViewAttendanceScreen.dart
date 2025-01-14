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
  final TextEditingController _dateController = TextEditingController();
  String? _sessionID;
  String? _courseID;
  String? _sectionID;
  String? _role;
  String? _rollNumber;
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

    // Automatically fetch attendance for students
    if (_role == 'Student') {
      _fetchAttendanceForStudent();
    } else {
      setState(() {
        _isLoading = false; // Only set false if not loading for students
      });
    }
  }

  Future<void> _fetchAttendanceForStudent() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final records = await ApiService().fetchAttendance(
        _sessionID!,
        _rollNumber ?? '',
        _courseID!,
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

  Future<void> _fetchAttendanceRecords() async {
    // Admin and faculty attendance fetching logic
    if (_sessionID == null || _courseID == null || _sectionID == null || _dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.toLocal()}".split(' ')[0];
      });
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
            if (_role != 'Student') ...[
              TextField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Enter Date (YYYY-MM-DD)',
                  border: OutlineInputBorder(),
                ),
                onTap: () => _selectDate(context),
                readOnly: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchAttendanceRecords,
                child: const Text('Fetch Attendance'),
              ),
              const SizedBox(height: 20),
            ],
            if (_error.isNotEmpty)
              Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            if (_attendanceRecords.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      if (_role != 'Student')
                        const DataColumn(label: Text('Roll Number')),
                      const DataColumn(label: Text('Date')),
                      const DataColumn(label: Text('Attendance Status')),
                    ],
                    rows: _attendanceRecords.map((record) {
                      return DataRow(cells: [
                        if (_role != 'Student')
                          DataCell(Text(record['RollNumber'] ?? '')),
                        DataCell(Text(record['Date'] ?? '')),
                        DataCell(Text(record['AttendanceStatus'] ?? '')),
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
