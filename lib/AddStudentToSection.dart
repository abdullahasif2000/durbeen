import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:data_table_2/data_table_2.dart';

class AddStudentToSectionScreen extends StatefulWidget {
  final String cohort;

  AddStudentToSectionScreen({required this.cohort});

  @override
  _AddStudentToSectionScreenState createState() =>
      _AddStudentToSectionScreenState();
}

class _AddStudentToSectionScreenState extends State<AddStudentToSectionScreen> {
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> addedStudents = [];
  List<String> selectedRollNumbers = [];
  List<String> sectionIDs = [];
  List<String> courseIDs = [];
  String? sessionID;
  bool isStudentMapped = false;
  bool isLoading = false;


  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      sessionID = prefs.getString('SessionID');

      final sectionData = prefs.getString('CreatedSectionIDs');
      if (sectionData != null) {
        try {
          sectionIDs = List<String>.from(jsonDecode(sectionData));
        } catch (e) {
          print("Error parsing SectionIDs: $e");
          sectionIDs = [];
        }
      }

      final courseData = prefs.getString('CourseIDs');
      if (courseData != null) {
        try {
          courseIDs = List<String>.from(jsonDecode(courseData));
        } catch (e) {
          print("Error parsing CourseIDs: $e");
          courseIDs = [];
        }
      }
    });

    print("SessionID: $sessionID");
    print("SectionIDs: $sectionIDs");
    print("CourseIDs: $courseIDs");

    await _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      final fetchedStudents =
      await ApiService().fetchStudentsByCohort(widget.cohort);
      setState(() {
        students = fetchedStudents;
      });
    } catch (e) {
      print('Error fetching students: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch students')),
      );
    }
  }

  Future<void> _fetchMappedStudents() async {
    if (sessionID == null || sessionID!.isEmpty || sectionIDs.isEmpty ||
        courseIDs.isEmpty) {
      print(
          'Validation failed: sessionID=$sessionID, sectionIDs=$sectionIDs, courseIDs=$courseIDs');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid SessionID, SectionIDs, or CourseIDs.')),
      );
      return;
    }

    try {
      List<Map<String, dynamic>> allMappedStudents = [];
      for (int i = 0; i < sectionIDs.length; i++) {
        final sectionID = sectionIDs[i];
        final courseID = courseIDs[i];

        if (sectionID.isEmpty || courseID.isEmpty) {
          print(
              'Invalid SectionID or CourseID at index $i. SectionID=$sectionID, CourseID=$courseID');
          continue;
        }

        print(
            'Fetching students: SessionID=$sessionID, SectionID=$sectionID, CourseID=$courseID');

        final mappedStudents = await ApiService().fetchMappedStudents(
          SessionID: sessionID!,
          SectionID: sectionID,
          CourseID: courseID,
        );

        if (mappedStudents == null || mappedStudents.isEmpty) {
          print(
              'No students returned for SectionID=$sectionID, CourseID=$courseID');
          continue;
        }

        allMappedStudents.addAll(mappedStudents);
      }

      setState(() {
        addedStudents = allMappedStudents;
      });
    } catch (e, stackTrace) {
      print('Error fetching mapped students: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch mapped students: $e')),
      );
    }
  }

  Future<void> _mapStudentsToSections() async {
    if (sessionID == null || sectionIDs.isEmpty || courseIDs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid SessionID, SectionIDs, or CourseIDs.')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      for (String rollNumber in selectedRollNumbers) {
        for (int i = 0; i < sectionIDs.length; i++) {
          final sectionID = sectionIDs[i];
          final courseID = courseIDs[i];
          final success = await ApiService().addStudentToSection(
            sessionID: sessionID!,
            sectionID: sectionID,
            courseID: courseID,
            rollNumber: rollNumber,
          );

          if (success) {
            print(
                'Student $rollNumber added successfully to Section $sectionID for Course $courseID!');
          } else {
            print(
                'Failed to add student $rollNumber to Section $sectionID for Course $courseID.');
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected students mapped to all sections successfully!')),
      );

      setState(() {
        isStudentMapped = true;
      });

      await _fetchMappedStudents();
    } catch (e) {
      print('Error mapping students: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error mapping students to sections.')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _confirmAndRemoveStudent(String sessionID, String courseID,
      String rollNumber) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Removal'),
          content: Text(
              'Are you sure you want to remove the student with Roll Number $rollNumber?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _removeStudentFromSection(
                    sessionID, courseID, rollNumber);
              },
              child: Text('Remove', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }

  // Remove student from section
  Future<void> _removeStudentFromSection(String sessionID, String courseID,
      String rollNumber) async {
    try {
      final success = await ApiService().removeStudentFromSection(
        sessionID: sessionID,
        courseID: courseID,
        rollNumber: rollNumber,
      );

      if (success) {
        Fluttertoast.showToast(msg: 'Student removed successfully!');
        // Refresh the mapped students list
        await _fetchMappedStudents();
      } else {
        Fluttertoast.showToast(msg: 'Failed to remove student.');
      }
    } catch (e) {
      print('Error removing student: $e');
      Fluttertoast.showToast(msg: 'Error removing student.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: AppBar(
          title: Text('Map Students to Sections'),
          backgroundColor: Colors.orange[700],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Students to Map to Sections'),
              SizedBox(height: 10),
              // Multi select students using MultiSelectDropdown
              MultiSelectDialogField(
                items: students.map((student) {
                  return MultiSelectItem(student['RollNumber'],
                      '${student['RollNumber']} - ${student['Name']}');
                }).toList(),
                title: Text("Select Students"),
                selectedColor: Colors.orange,
                buttonText: Text("Select Students"),
                onConfirm: (values) {
                  setState(() {
                    selectedRollNumbers = List<String>.from(values);
                  });
                },
                searchable: true,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: selectedRollNumbers.isEmpty || isLoading
                    ? null
                    : () async {
                  await _mapStudentsToSections();
                },
                child: isLoading
                    ? CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
                    : Text('Map Selected Students to All Sections'),
              ),
              SizedBox(height: 20),
              Text(
                'Mapped Students in Sections',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Container(
                height: 300,
                child: DataTable2(
                  columnSpacing: 12,
                  horizontalMargin: 12,
                  minWidth: 600,
                  columns: [
                    DataColumn2(
                        label: Text('Roll Number'), size: ColumnSize.M),
                    DataColumn2(label: Text('Name'), size: ColumnSize.L),
                    DataColumn2(
                        label: Text('Session ID'), size: ColumnSize.M),
                    DataColumn2(
                        label: Text('Section ID'), size: ColumnSize.M),
                    DataColumn2(label: Text('Course ID'), size: ColumnSize.M),
                    DataColumn2(label: Text('Actions'), size: ColumnSize.S),
                  ],
                  rows: addedStudents.map((student) {
                    return DataRow2(cells: [
                      DataCell(Text(student['RollNumber'])),
                      DataCell(Text(student['Name'])),
                      DataCell(Text(student['SessionID'])),
                      DataCell(Text(student['SectionID'])),
                      DataCell(Text(student['CourseID'])),
                      DataCell(
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await _confirmAndRemoveStudent(
                              student['SessionID'],
                              student['CourseID'],
                              student['RollNumber'],
                            );
                          },
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}