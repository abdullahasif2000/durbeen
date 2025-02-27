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

    if (_role == 'Student') {
      await _fetchAttendanceRecords();
    } else {
      await _fetchAttendanceDates();
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchAttendanceRecords() async {
    if (_sessionID == null || _courseID == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing required information')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      if (_role == 'Student') {
        final records = await ApiService().fetchAttendance(
          _sessionID!,
          _rollNumber!,
          _courseID!,
        );


        _attendanceRecords = records.map((record) {
          return {
            'Date': record['Date'],
            'AttendanceStatus': record['AttendanceStatus'],
            'RollNumber': _rollNumber,
            'WarningsSent': '0',
          };
        }).toList();
      } else {

        if (_selectedDate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a date')),
          );
          return;
        }

        // Log the API call payload
        print('Fetching attendance details with payload:');
        print('SessionID: $_sessionID');
        print('CourseID: $_courseID');
        print('Date: $_selectedDate');
        print('SectionID: $_sectionID');

        final records = await ApiService().fetchAttendanceDetails(
          _sessionID!,
          _courseID!,
          _selectedDate!,
          _sectionID!,
        );

        _attendanceRecords = records.map((record) {
          return {
            'Date': record['Date'],
            'AttendanceStatus': record['AttendanceStatus'],
            'RollNumber': record['RollNumber'],
            'WarningsSent': record['WarningsSent'] ?? '0',
            'Name': record['Name'],
          };
        }).toList();
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

  Color _getAttendanceStatusColor(String? status) {
    switch (status) {
      case 'present':
        return Colors.green.shade100;
      case 'absent':
        return Colors.red.shade100;
      case 'late':
        return Colors.yellow.shade100;
      default:
        return Colors.grey.shade200;
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
                  _fetchAttendanceRecords();
                },
                items: _attendanceDates.map<DropdownMenuItem<String>>((String date) {
                  return DropdownMenuItem<String>(
                    value: date,
                    child: Text(date),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
            if (_error.isNotEmpty)
              Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            if (_attendanceRecords.isNotEmpty)
              Expanded(
                child: _role == 'Student'
                    ? ListView.builder(
                  itemCount: _attendanceRecords.length,
                  itemBuilder: (context, index) {
                    final record = _attendanceRecords[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text('Date: ${record['Date']}'),
                        subtitle: Text('Status: ${record['AttendanceStatus']}'),
                        tileColor: _getAttendanceStatusColor(record['AttendanceStatus']),
                      ),
                    );
                  },
                )
                    : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        const DataColumn(label: Text('Roll Number')),
                        const DataColumn(label: Text('Name')),
                        const DataColumn(label: Text('Date')),
                        const DataColumn(label: Text('Attendance Status')),
                        const DataColumn(label: Text('Warnings Sent')),
                      ],
                      rows: _attendanceRecords.map((record) {
                        return DataRow(
                          color: MaterialStateProperty.resolveWith<Color?>(
                                (Set<MaterialState> states) =>
                                _getAttendanceStatusColor(record['AttendanceStatus']),
                          ),
                          cells: [
                            DataCell(Text(record['RollNumber'] ?? '')),
                            DataCell(Text(record['Name'] ?? '')),
                            DataCell(Text(record['Date'] ?? '')),
                            DataCell(Text(record['AttendanceStatus'] ?? '')),
                            DataCell(Text(record['WarningsSent'] ?? '')),
                          ],
                        );
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