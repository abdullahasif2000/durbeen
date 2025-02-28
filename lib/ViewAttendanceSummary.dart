import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
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
              final noOfSessions = course['NoOfSessions'] ?? 0;

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              course['Name'] ?? 'Unknown Course',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Column(
                            children: [
                              _buildStatusIndicator(Colors.green, 'Present'),
                              _buildStatusIndicator(Colors.red, 'Absent'),
                              _buildStatusIndicator(Colors.yellow, 'Late'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No. Of Sessions: $noOfSessions',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      buildPieChart(attendanceSummary, noOfSessions),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusIndicator(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }

  Widget buildPieChart(List<Map<String, dynamic>> attendanceSummary, int noOfSessions) {
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

    if (total == 0) {
      return Center(child: Text('No data available.'));
    }

    String status;
    if (absentCount >= 8) {
      status = 'Fail';
    } else if (absentCount == 7) {
      status = 'Probation';
    } else if (absentCount == 6) {
      status = 'Warning';
    } else {
      status = 'Clear';
    }

    final pieChartData = [
      PieChartSectionData(
        value: presentCount.toDouble(),
        title: '${presentCount} (${(presentCount / noOfSessions * 100).toStringAsFixed(1)}%)',
        color: Colors.green,
        titleStyle: const TextStyle(fontSize: 11, color: Colors.black87),
      ),
      PieChartSectionData(
        value: absentCount.toDouble(),
        title: '${absentCount} (${(absentCount / noOfSessions * 100).toStringAsFixed(1)}%)',
        color: Colors.red,
        titleStyle: const TextStyle(fontSize: 11, color: Colors.black87),
      ),
      PieChartSectionData(
        value: lateCount.toDouble(),
        title: '${lateCount} (${(lateCount / noOfSessions * 100).toStringAsFixed(1)}%)',
        color: Colors.yellow,
        titleStyle: const TextStyle(fontSize: 11, color: Colors.black87),
      ),
    ];

    return SizedBox(
      height: 200,
      child: Column(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: pieChartData,
                borderData: FlBorderData(show: false),
                sectionsSpace: 0,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Status: $status',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}