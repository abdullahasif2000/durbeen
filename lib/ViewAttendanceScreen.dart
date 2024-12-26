import 'package:flutter/material.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Import for JSON encoding/decoding

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
  bool? _attendanceMarked;
  bool _isLoading = true;  // To show loading indicator until preferences are loaded.

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sessionID = prefs.getString('SessionID');

      // Retrieve the CourseIDs JSON string and decode it
      String? courseIDsString = prefs.getString('CourseIDs');
      if (courseIDsString != null) {
        List<dynamic> courseIDsList = jsonDecode(courseIDsString);
        _courseID = courseIDsList.isNotEmpty ? courseIDsList[0].toString() : null; // Get the first CourseID
      } else {
        _courseID = null; // Handle the case where CourseIDs is not set
      }

      _sectionID = prefs.getString('SelectedSectionID');
      _isLoading = false;  // Preferences are loaded, hide the loading indicator.
    });

    // Debugging output
    print('SessionID: $_sessionID');
    print('CourseID: $_courseID');
    print('SectionID: $_sectionID');
  }

  Future<void> _checkAttendance() async {
    if (_sessionID == null || _courseID == null || _sectionID == null || _dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      final date = _dateController.text;
      final isMarked = await ApiService().checkAttendanceMarked(
        sessionID: _sessionID!,
        courseID: _courseID!,
        sectionID: _sectionID!,
        date: date,
      );

      setState(() {
        _attendanceMarked = isMarked;
      });
    } catch (e) {
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
    if (picked != null && picked != DateTime.now()) {
      setState(() {
        _dateController.text = "${picked.toLocal()}".split(' ')[0]; // Format as YYYY-MM-DD
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'View Attendance',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 24),
          ),
          backgroundColor: Colors.orange[700],
          centerTitle: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),  // Show loading indicator.
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'View Attendance',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 24),
        ),
        backgroundColor: Colors.orange[700],
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
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
              onTap: () => _selectDate(context), // Open date picker on tap
              readOnly: true, // Make the text field read-only
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _checkAttendance,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Check Attendance'),
            ),
            const SizedBox(height: 20),
            if (_attendanceMarked != null)
              DataTable(
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Attendance Status')),
                ],
                rows: [
                  DataRow(cells: [
                    DataCell(Text(_dateController.text)),
                    DataCell(Text(_attendanceMarked! ? 'Marked' : 'Not Marked')),
                  ]),
                ],
              ),
          ],
        ),
      ),
    );
  }
}