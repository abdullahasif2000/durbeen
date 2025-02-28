import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:data_table_2/data_table_2.dart';
import 'api_service.dart';
import 'CreateSectionScreen.dart';
import 'SelectSectionScreen.dart';
import 'dart:convert';

class SelectCohortScreen extends StatefulWidget {
  final String source;
  final String? option;

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
    final savedCohort = prefs.getString('cohort');
    setState(() {
      _role = prefs.getString('UserRole');
      if (_role == 'Student') {
        _selectedCohort = savedCohort;
        if (_selectedCohort != null) {
          _coursesFuture = fetchCourses(_selectedCohort!);
        }
      } else if (_role == 'Faculty') {
        _coursesFuture = fetchFacultyCourses();
      }
    });
  }

  Future<List<String>> fetchCohorts() async {
    try {
      debugPrint('Fetching cohorts from API...');
      final response = await ApiService().fetchCohorts();
      debugPrint('Cohorts fetched successfully: ${response.toString()}');
      return response.map<String>((cohort) => cohort['cohort'].toString()).toList();
    } catch (e) {
      debugPrint('Error fetching cohorts: $e');
      throw Exception("Failed to load cohorts: $e");
    }
  }

  Future<List<Map<String, dynamic>>> fetchCourses(String cohort) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionID = prefs.getString('SessionID') ?? '';
      if (sessionID.isEmpty) {
        throw Exception("SessionID is required but not found.");
      }

      debugPrint('Fetching courses for cohort: $cohort with SessionID: $sessionID');

      if (_role == 'Student') {
        final rollNumber = prefs.getString('RollNumber') ?? '';
        if (rollNumber.isEmpty) {
          throw Exception("RollNumber is required but not found.");
        }
        final response = await ApiService().fetchStudentCourses(sessionID, rollNumber);
        debugPrint('Courses fetched for student: ${response.toString()}');
        return response;
      } else if (_role == 'Admin') {

        final response = await ApiService().fetchCourses(cohort, sessionID);
        debugPrint('Courses fetched for admin: ${response.toString()}');
        return response;
      } else {
        throw Exception('Invalid role');
      }
    } catch (e) {
      debugPrint('Error fetching courses: $e');
      throw Exception("Failed to load courses: $e");
    }
  }


  Future<List<Map<String, dynamic>>> fetchFacultyCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionID = prefs.getString('SessionID') ?? '';
      final facultyID = prefs.getString('FacultyID') ?? '';

      debugPrint('Fetching faculty courses with FacultyID: $facultyID and SessionID: $sessionID');

      final response = await ApiService().fetchFacultyCourses(facultyID, sessionID);
      debugPrint('Faculty courses fetched successfully: ${response.toString()}');
      return response;
    } catch (e) {
      debugPrint('Error fetching faculty courses: $e');
      throw Exception("Failed to load faculty courses: $e");
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

            if (_role == 'Admin')
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
                    onChanged: (value) {
                      setState(() {
                        _selectedCohort = value;
                        _coursesFuture = fetchCourses(value!);
                      });
                    },
                  );
                },
              ),
            const SizedBox(height: 20),
            if (_selectedCohort != null || _role == 'Faculty')
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _coursesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No courses available.'));
                    }

                    final courses = snapshot.data!;
                    return DataTable2(
                      headingRowColor: MaterialStateProperty.all(Colors.grey[700]),
                      headingTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      columnSpacing: 1,
                      horizontalMargin: 5,
                      minWidth: 700,
                      border: TableBorder.all(color: Colors.grey[300]!, width: 1),
                      columns: _getColumnsBasedOnRole(),
                      rows: List.generate(
                        courses.length,
                            (index) {
                          final course = courses[index];
                          final isSelected = _selectedCourses.contains(course);

                          return DataRow(
                            selected: isSelected,
                            onSelectChanged: widget.source == 'Courses'
                                ? null
                                : (value) {
                              setState(() {
                                if (widget.source == 'Attendance') {

                                  if (value == true) {
                                    _selectedCourses.clear();
                                    _selectedCourses.add(course);
                                  } else {
                                    _selectedCourses.remove(course);
                                  }
                                } else {

                                  if (value == true) {
                                    if (!_selectedCourses.contains(course)) {
                                      _selectedCourses.add(course);
                                    }
                                  } else {
                                    _selectedCourses.remove(course);
                                  }
                                }
                              });
                            },
                            cells: _getRowCells(course, index + 1),
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

  List<DataColumn> _getColumnsBasedOnRole() {
    if (_role == 'Admin') {
      return const [
        DataColumn(label: Text('Sr. No')),
        DataColumn(label: Text('Course ID')),
        DataColumn(label: Text('Course Name')),
        DataColumn(label: Text('Faculty Name')),
        DataColumn(label: Text('Session ID')),
        DataColumn(label: Text('Description')),
      ];
    } else if (_role == 'Faculty') {
      return const [
        DataColumn(label: Text('Sr. No')),
        DataColumn(label: Text('Course ID')),
        DataColumn(label: Text('Course Code')),
        DataColumn(label: Text('Course Name')),
        DataColumn(label: Text('Short Code')),
        DataColumn(label: Text('Session ID')),
      ];
    } else if (_role == 'Student') {
      return const [
        DataColumn(label: Text('Sr. No')),
        DataColumn(label: Text('Course ID')),
        DataColumn(label: Text('Old Code')),
        DataColumn(label: Text('New Code')),
        DataColumn(label: Text('Course Name')),
        DataColumn(label: Text('Short Code')),
        DataColumn(label: Text('Credit Hours')),
      ];
    }
    return [];
  }

  List<DataCell> _getRowCells(Map<String, dynamic> course, int serialNumber) {
    if (_role == 'Admin') {
      return [
        DataCell(Text('$serialNumber')),
        DataCell(Text(course['CourseID']?.toString() ?? 'N/A')),
        DataCell(Text(course['Name'] ?? 'N/A')),
        DataCell(Text(course['FacultyName'] ?? 'N/A')),
        DataCell(Text(course['SessionID']?.toString() ?? 'N/A')),
        DataCell(Text(course['Description'] ?? 'N/A')),
      ];
    } else if (_role == 'Faculty') {
      return [
        DataCell(Text('$serialNumber')),
        DataCell(Text(course['CourseID']?.toString() ?? 'N/A')),
        DataCell(Text(course['CCNew'] ?? 'N/A')),
        DataCell(Text(course['Name'] ?? 'N/A')),
        DataCell(Text(course['ShortCode'] ?? 'N/A')),
        DataCell(Text(course['SessionID']?.toString() ?? 'N/A')),
      ];
    } else if (_role == 'Student') {
      return [
        DataCell(Text('$serialNumber')),
        DataCell(Text(course['CourseID']?.toString() ?? 'N/A')),
        DataCell(Text(course['CCOld'] ?? 'N/A')),
        DataCell(Text(course['CCNew'] ?? 'N/A')),
        DataCell(Text(course['Name'] ?? 'N/A')),
        DataCell(Text(course['ShortCode'] ?? 'N/A')),
        DataCell(Text(course['CreditHours']?.toString() ?? 'N/A')),
      ];
    }
    return [];
  }
}
