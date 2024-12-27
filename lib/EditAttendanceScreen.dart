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

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final date = _dateController.text;
      final records = await ApiService().fetchAttendanceRecords(
        sessionID: _sessionID!,
        courseID: _courseID!,
        sectionID: _sectionID!,
        date: date,
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
      print('DEBUG: Attempting to update attendance...');
      print('DEBUG: RollNumber: $rollNumber, NewStatus: $newStatus');
      print('DEBUG: SessionID: $_sessionID');
      print('DEBUG: CourseID: $_courseID');
      print('DEBUG: SectionID: $_sectionID');
      print('DEBUG: Date: ${_dateController.text}');

      await ApiService().updateAttendanceStatus(
        sessionID: _sessionID!,
        courseID: _courseID!,
        sectionID: _sectionID!,
        date: _dateController.text,
        rollNumber: rollNumber,
        attendanceStatus: newStatus,
      );

      print('DEBUG: Attendance updated successfully.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance updated successfully')),
      );

      _fetchAttendanceRecords(); // Refresh the attendance records
    } catch (e) {
      print('ERROR: Failed to update attendance: $e');
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
                      DataColumn(label: Text('Attendance Status')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: _attendanceRecords.map((record) {
                      return DataRow(cells: [
                        DataCell(Text(record['RollNumber'] ?? '')),
                        DataCell(Text(record['Date'] ?? '')),
                        DataCell(Text(record['AttendanceStatus'] ?? '')),
                        DataCell(
                          DropdownButton<String>(
                            value: record['AttendanceStatus'],
                            items: ['present', 'absent', 'late']
                                .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ))
                                .toList(),
                            onChanged: (newValue) {
                              if (newValue != null) {
                                _updateAttendanceStatus(record['RollNumber']!, newValue);
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
