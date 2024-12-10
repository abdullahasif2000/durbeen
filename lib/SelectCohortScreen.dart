import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:data_table_2/data_table_2.dart';
import 'api_service.dart';
import 'CreateSectionScreen.dart';
import 'dart:convert';

class SelectCohortScreen extends StatefulWidget {
  const SelectCohortScreen({Key? key}) : super(key: key);

  @override
  _SelectCohortScreenState createState() => _SelectCohortScreenState();
}

class _SelectCohortScreenState extends State<SelectCohortScreen> {
  late Future<List<String>> _cohortsFuture;
  late Future<List<Map<String, dynamic>>> _coursesFuture;
  String? _selectedCohort; // Holds the currently selected cohort
  final List<Map<String, dynamic>> _selectedCourses = []; // Stores selected courses

  @override
  void initState() {
    super.initState();
    _cohortsFuture = fetchCohorts();
  }

  Future<List<String>> fetchCohorts() async {
    try {
      final response = await ApiService().fetchCohorts();
      return response.map<String>((cohort) => cohort['cohort'].toString()).toList();
    } catch (e) {
      throw Exception("Failed to load cohorts: $e");
    }
  }

  // Fetch courses for the selected cohort
  Future<List<Map<String, dynamic>>> fetchCourses(String cohort) async {
    try {
      return await ApiService().fetchCourses(cohort); // Fetch courses for a specific cohort
    } catch (e) {
      throw Exception("Failed to load courses: $e");
    }
  }

  // Save selected courses' IDs to SharedPreferences
  Future<void> _saveSelectedCourseIDs() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedCourseIDs = _selectedCourses.map((course) => course['CourseID'].toString()).toList();
    await prefs.setString('SelectedCourseIDs', jsonEncode(selectedCourseIDs));
    await prefs.setString('CourseIDs', jsonEncode(selectedCourseIDs)); // Save under 'CourseIDs'
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
            // Dropdown for selecting cohort
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
                      _coursesFuture = fetchCourses(value!); // Fetch courses when cohort is selected
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 20),

            // Display courses once cohort is selected
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
                      columns: const [
                        DataColumn(label: Text('Sr. No')),
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
                            onSelectChanged: (value) {
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
                              DataCell(Text(course['Name'], maxLines: 1)),
                              DataCell(Text(course['FacultyName'], maxLines: 1)),
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

            // Button to proceed to CreateSectionScreen if courses are selected
            if (_selectedCourses.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () async {
                    await _saveSelectedCourseIDs(); // Save selected course IDs before navigation
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateSectionScreen(
                          cohort: _selectedCohort!,
                          selectedCourses: _selectedCourses, // Pass selected courses to the next screen
                        ),
                      ),
                    );
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}