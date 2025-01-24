import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:data_table_2/data_table_2.dart';
import 'api_service.dart';
import 'CreateSectionScreen.dart';
import 'SelectSectionScreen.dart';
import 'dart:convert';

class SelectCohortScreen extends StatefulWidget {
  final String source; // Determines the source module
  final String? option; // Optional parameter for the action (Mark, Edit, View)

  const SelectCohortScreen({Key? key, required this.source, this.option}) : super(key: key);

  @override
  _SelectCohortScreenState createState() => _SelectCohortScreenState();
}

class _SelectCohortScreenState extends State<SelectCohortScreen> {
  late Future<List<String>> _cohortsFuture;
  late Future<List<Map<String, dynamic>>> _coursesFuture;
  String? _selectedCohort;
  final List<Map<String, dynamic>> _selectedCourses = [];
  String? _role;

  @override
  void initState() {
    super.initState();
    _cohortsFuture = fetchCohorts();
    _loadUserRoleAndCohort();
  }

  Future<void> _loadUserRoleAndCohort() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCohort = prefs.getString('cohort'); // Load the cohort from SharedPreferences
    setState(() {
      _role = prefs.getString('UserRole'); // Load user role
      if (_role == 'Student') {
        _selectedCohort = savedCohort; // Automatically set the cohort for students
        if (_selectedCohort != null) {
          _coursesFuture = fetchCourses(_selectedCohort!); // Fetch courses for the pre-selected cohort
        }
      }
    });
  }

  Future<List<String>> fetchCohorts() async {
    try {
      final response = await ApiService().fetchCohorts();
      return response.map<String>((cohort) => cohort['cohort'].toString()).toList();
    } catch (e) {
      throw Exception("Failed to load cohorts: $e");
    }
  }

  Future<List<Map<String, dynamic>>> fetchCourses(String cohort) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rollNumber = prefs.getString('RollNumber') ?? '';
      final sessionID = prefs.getString('SessionID') ?? '';

      if (_role == 'Student') {
        return await ApiService().fetchStudentCourses(sessionID, rollNumber);
      } else if (_role == 'Faculty') {
        final courses = await ApiService().fetchCourses(cohort);
        final facultyID = prefs.getString('FacultyID') ?? '';
        return courses.where((course) => course['FacultyID'].toString() == facultyID).toList();
      } else {
        return await ApiService().fetchCourses(cohort);
      }
    } catch (e) {
      throw Exception("Failed to load courses: $e");
    }
  }

  Future<void> _saveSelectedCourseIDs() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedCourseIDs = _selectedCourses.map((course) => course['CourseID'].toString()).toList();
    await prefs.setString('SelectedCourseIDs', jsonEncode(selectedCourseIDs));
    await prefs.setString('CourseIDs', jsonEncode(selectedCourseIDs));
    debugPrint('Saved CourseIDs to SharedPreferences: $selectedCourseIDs');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Cohort',
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
            FutureBuilder<List<String>>(
              future: _cohortsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData && snapshot.data!.isEmpty) {
                  return const Center(child: Text('No cohorts available'));
                }

                final cohorts = snapshot.data!;
                return DropdownButton<String>(
                  value: _selectedCohort,
                  hint: const Text(
                    'Choose Cohort',
                    style: TextStyle(fontSize: 16),
                  ),
                  items: cohorts.map((cohort) {
                    return DropdownMenuItem<String>(
                      value: cohort,
                      child: Text(cohort),
                    );
                  }).toList(),
                  onChanged: _role == 'Student'
                      ? null // Disable dropdown for students
                      : (value) {
                    setState(() {
                      _selectedCohort = value;
                      _coursesFuture = fetchCourses(value!);
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            if (_selectedCohort != null)
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _coursesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No courses available for this cohort.'));
                    }

                    final courses = snapshot.data!;
                    return _role == 'Student'
                        ? DataTable2(
                      headingRowColor: MaterialStateProperty.all(Colors.grey[700]),
                      headingTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      columnSpacing: 1,
                      horizontalMargin: 5,
                      minWidth: 700,
                      border: TableBorder.all(color: Colors.grey[300]!, width: 1),
                      columns: const [
                        DataColumn(label: Text('Sr. No')),
                        DataColumn(label: Text('Course ID')),
                        DataColumn(label: Text('Course Code')),
                        DataColumn(label: Text('Course Name')),
                        DataColumn(label: Text('Credits')),
                      ],
                      rows: List.generate(
                        courses.length,
                            (index) {
                          final course = courses[index];
                          final isSelected = _selectedCourses.contains(course);

                          return DataRow(
                            selected: isSelected,
                            onSelectChanged: widget.source == 'Courses'
                                ? null // Disable selection if source is 'Courses'
                                : (value) {
                              setState(() {
                                if (value == true) {
                                  if (!_selectedCourses.contains(course)) {
                                    _selectedCourses.add(course);
                                  }
                                } else {
                                  _selectedCourses.remove(course);
                                }
                              });
                            },
                            cells: [
                              DataCell(Text('${index + 1}')),
                              DataCell(Text(course['CourseID'].toString())),
                              DataCell(Text(course['CCNew'])),
                              DataCell(Text(course['Name'])),
                              DataCell(Text(course['CreditHours']?.toString() ?? 'N/A')),
                            ],
                          );
                        },
                      ),
                    )
                        : DataTable2(
                      headingRowColor: MaterialStateProperty.all(Colors.grey[700]),
                      headingTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      columnSpacing: 1,
                      horizontalMargin: 5,
                      minWidth: 700,
                      border: TableBorder.all(color: Colors.grey[300]!, width: 1),
                      columns: const [
                        DataColumn(label: Text('Sr. No')),
                        DataColumn(label: Text('Course ID')),
                        DataColumn(label: Text('Course Name')),
                        DataColumn(label: Text('Faculty Name')),
                        DataColumn(label: Text('Faculty ID')),
                        DataColumn(label: Text('Session ID')),
                      ],
                      rows: List.generate(
                        courses.length,
                            (index) {
                          final course = courses[index];
                          final isSelected = _selectedCourses.contains(course);

                          return DataRow(
                            selected: isSelected,
                            onSelectChanged: widget.source == 'Courses'
                                ? null // Disable selection if source is 'Courses'
                                : (value) {
                              setState(() {
                                if (value == true) {
                                  if (!_selectedCourses.contains(course)) {
                                    _selectedCourses.add(course);
                                  }
                                } else {
                                  _selectedCourses.remove(course);
                                }
                              });
                            },
                            cells: [
                              DataCell(Text('${index + 1}')),
                              DataCell(Text(course['CourseID'].toString())),
                              DataCell(Text(course['Name'])),
                              DataCell(Text(course['FacultyName'])),
                              DataCell(Text(course['FacultyID'].toString())),
                              DataCell(Text(course['SessionID'].toString())),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),
            if (_selectedCourses.isNotEmpty && widget.source != 'Courses')
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () async {
                    await _saveSelectedCourseIDs();
                    if (widget.source == 'Mapping') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateSectionScreen(
                            cohort: _selectedCohort!,
                            selectedCourses: _selectedCourses,
                          ),
                        ),
                      );
                    } else if (widget.source == 'Attendance') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectSectionScreen(
                            option: widget.option ?? '',
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Proceed with Selected Courses',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

          ],
        ),
      ),
    );
  }
}