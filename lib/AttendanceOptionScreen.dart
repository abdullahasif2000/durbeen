import 'package:flutter/material.dart';
import 'SelectCohortScreen.dart';

class AttendanceOptionScreen extends StatefulWidget {
  final String role;

  const AttendanceOptionScreen({Key? key, required this.role}) : super(key: key);

  @override
  _AttendanceOptionScreenState createState() => _AttendanceOptionScreenState();
}

class _AttendanceOptionScreenState extends State<AttendanceOptionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Attendance Options',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 24),
        ),
        centerTitle: true,
        backgroundColor: Colors.orange[700],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.role != 'Student')
                _buildButton(
                  context,
                  label: 'Mark Attendance',
                  icon: Icons.edit_calendar,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SelectCohortScreen(source: 'Attendance'),
                      ),
                    );
                  },
                ),
              if (widget.role != 'Student') const SizedBox(height: 20),
              if (widget.role != 'Student')
                _buildButton(
                  context,
                  label: 'Edit Attendance',
                  icon: Icons.edit,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SelectCohortScreen(source: 'Attendance'),
                      ),
                    );
                  },
                ),
              if (widget.role != 'Student') const SizedBox(height: 20),
              _buildButton(
                context,
                label: 'View Attendance',
                icon: Icons.visibility,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SelectCohortScreen(source: 'Attendance'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, {required String label, required IconData icon, required VoidCallback onTap}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 5,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: Colors.white),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
    );
  }
}