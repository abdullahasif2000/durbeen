import 'package:flutter/material.dart';

class CreateSectionScreen extends StatefulWidget {
  final String cohort;
  final List<Map<String, dynamic>> selectedCourses;

  const CreateSectionScreen({
    required this.cohort,
    required this.selectedCourses,
    super.key,
  });

  @override
  _CreateSectionScreenState createState() => _CreateSectionScreenState();
}

class _CreateSectionScreenState extends State<CreateSectionScreen> {
  final TextEditingController sectionController = TextEditingController();
  String? selectedRollNumber; // Variable to store selected roll number
  List<String> studentRollNumbers = [];
  bool isSectionCreated = false; // Flag to control the visibility of roll number field

  // Placeholder list of roll numbers (replace with API data in the future)
  List<String> rollNumberOptions = [
    '12345',
    '23456',
    '34567',
    '45678',
    '56789',
  ];

  // Function to create the section
  void createSection() {
    String section = sectionController.text.trim();

    if (section.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Section name is required')),
      );
      return;
    }

    setState(() {
      isSectionCreated = true; // Set flag to true when section is created
    });

    // Debugging: Print the details
    print("Cohort: ${widget.cohort}");
    print("Selected Courses: ${widget.selectedCourses.map((course) => course['Name']).join(', ')}");
    print("Section: $section");

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Section "$section" created!')),
    );
  }

  // Function to add student roll number to the section
  void addRollNumber() {
    if (selectedRollNumber != null) {
      setState(() {
        studentRollNumbers.add(selectedRollNumber!);
        selectedRollNumber = null; // Clear selection after adding
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Roll Number added!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a roll number')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Section',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 24),
        ),
        backgroundColor: Colors.orange[700],
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
      ),
      resizeToAvoidBottomInset: true, // Make the screen resize when the keyboard appears
      body: SingleChildScrollView(  // Allow the screen to scroll when the keyboard is open
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display cohort dynamically (non-editable)
              TextField(
                controller: TextEditingController(text: widget.cohort),
                decoration: const InputDecoration(
                  labelText: 'Cohort',
                  border: OutlineInputBorder(),
                ),
                readOnly: true, // Make cohort read-only
              ),
              const SizedBox(height: 20),
              // Section Name TextField
              TextField(
                controller: sectionController,
                decoration: const InputDecoration(
                  labelText: 'Section Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: createSection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Create Section',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Show created section details in a Card after section is created
              if (isSectionCreated) ...[
                Card(
                  elevation: 5,
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cohort: ${widget.cohort}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Section: ${sectionController.text}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Selected Courses:',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        ...widget.selectedCourses.map(
                              (course) => Text(
                            '- ${course['Name']} (Faculty: ${course['FacultyName']})',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Display added student roll numbers in the same card
                        if (studentRollNumbers.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Text(
                            'Students in Section:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          ...studentRollNumbers.map(
                                (rollNumber) => Text(
                              '- $rollNumber',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Dropdown for roll number input after section is created
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedRollNumber,
                        decoration: const InputDecoration(
                          labelText: 'Select Roll Number',
                          border: OutlineInputBorder(),
                        ),
                        items: rollNumberOptions.map((rollNumber) {
                          return DropdownMenuItem<String>(
                            value: rollNumber,
                            child: Text(rollNumber),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedRollNumber = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: addRollNumber,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[700],
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Add Student',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
