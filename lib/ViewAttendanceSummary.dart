import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class ViewAttendanceSummary extends StatefulWidget {
  @override
  _ViewAttendanceSummaryState createState() => _ViewAttendanceSummaryState();
}

class _ViewAttendanceSummaryState extends State<ViewAttendanceSummary> {
  late Future<List<Map<String, dynamic>>> _coursesFuture;
  final Map<String, List<Map<String, dynamic>>> _attendanceSummaries = {};
  bool _attendanceFetched = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _coursesFuture = _loadStudentCourses();
  }

  Future<List<Map<String, dynamic>>> _loadStudentCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rollNumber = prefs.getString('RollNumber') ?? '';
      final sessionID = prefs.getString('SessionID') ?? '';

      if (rollNumber.isEmpty || sessionID.isEmpty) {
        throw Exception('RollNumber or SessionID not found in SharedPreferences');
      }

      final apiService = ApiService();
      return await apiService.fetchStudentCourses(sessionID, rollNumber);
    } catch (e) {
      debugPrint('Error loading courses: $e');
      throw e;
    }
  }

  Future<void> _fetchAllAttendanceSummaries(List<Map<String, dynamic>> courses) async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final rollNumber = prefs.getString('RollNumber') ?? '';
      final sessionID = prefs.getString('SessionID') ?? '';

      if (rollNumber.isEmpty || sessionID.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('RollNumber or SessionID not found.')),
        );
        return;
      }

      final apiService = ApiService();
      for (var course in courses) {
        final courseName = course['Name'] ?? 'Unknown Course';
        try {
          final summary = await apiService.fetchAttendance(
            sessionID,
            rollNumber,
            course['CourseID'].toString(),
          );
          _attendanceSummaries[courseName] = summary;
        } catch (e) {
          debugPrint('Error fetching attendance for $courseName: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching attendance for $courseName.')),
          );
        }
      }
      setState(() => _attendanceFetched = true);
    } catch (e) {
      debugPrint('Error fetching attendance summaries: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Summary'),
        backgroundColor: Colors.orange[700],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _coursesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No courses found.'));
          }

          final courses = snapshot.data!;
          if (!_attendanceFetched && !_isLoading) {
            // Use a post-frame callback to avoid calling setState during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fetchAllAttendanceSummaries(courses);
            });
          }

          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              final attendanceSummary = _attendanceSummaries[course['Name']] ?? [];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: buildBarChart(course['Name'] ?? 'Unknown Course', attendanceSummary),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget buildBarChart(String courseName, List<Map<String, dynamic>> attendanceSummary) {
    final total = attendanceSummary.length;
    final presentCount = attendanceSummary
        .where((entry) => (entry['AttendanceStatus'] ?? '').toLowerCase() == 'present')
        .length;
    final absentCount = attendanceSummary
        .where((entry) => (entry['AttendanceStatus'] ?? '').toLowerCase() == 'absent')
        .length;
    final lateCount = attendanceSummary
        .where((entry) => (entry['AttendanceStatus'] ?? '').toLowerCase() == 'late')
        .length;

    int getBarLength(int count) {
      final percentage = total == 0 ? 0 : count / total * 100;
      return percentage < 1 ? 1 : percentage.toInt();
    }

    if (total == 0) {
      return Center(child: Text('$courseName: No data available.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Attendance Breakdown for $courseName',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),
        ...[
          {'label': 'Present', 'count': presentCount, 'color': Colors.green},
          {'label': 'Absent', 'count': absentCount, 'color': Colors.red},
          {'label': 'Late', 'count': lateCount, 'color': Colors.orange},
        ].map((data) {
          final count = data['count'] as int;
          return Row(
            children: [
              Text(data['label'] as String, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                flex: getBarLength(count),
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: data['color'] as Color,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$count (${(total == 0 ? 0 : (count / total * 100).toStringAsFixed(1))}%)',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          );
        }),
      ],
    );
  }
}