import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AddComplaintRemarks extends StatefulWidget {
  final int complaintID;
  final String email;
  final String name;
  final String department;
  final bool isReadOnly;

  const AddComplaintRemarks({
    Key? key,
    required this.complaintID,
    required this.email,
    required this.name,
    required this.department,
    this.isReadOnly = false,
  }) : super(key: key);

  @override
  _AddComplaintRemarksState createState() => _AddComplaintRemarksState();
}

class _AddComplaintRemarksState extends State<AddComplaintRemarks> {
  final _formKey = GlobalKey<FormState>();
  final _remarksController = TextEditingController();
  String? _selectedStatus;
  final List<String> _statusOptions = ['In Process', 'False', 'Resolved'];

  @override
  void initState() {
    super.initState();
    if (widget.isReadOnly) {
      _selectedStatus = 'Challenged';
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _submitRemarks() async {
    if (_formKey.currentState!.validate()) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int userID = int.parse(prefs.getString('AdminID') ?? '0');

      ApiService apiService = ApiService();

      String statusToSend = widget.isReadOnly ? 'Challenged' : _selectedStatus ?? 'In Process';

      bool success = await apiService.addComplaintRemarks(
        userID: userID,
        complaintID: widget.complaintID,
        status: statusToSend,
        remarks: _remarksController.text,
        name: widget.name,
        email: widget.email,
        department: widget.department,
      );

      if (success) {
        print('Remarks submitted successfully.');
        Navigator.pop(context);
      } else {
        print('Failed to submit remarks.');
      }
    } else {
      print('Please fill in all fields.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Remarks'),
        backgroundColor: Colors.orange[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Your Remarks',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Name: ${widget.name}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Email: ${widget.email}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Department: ${widget.department}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (widget.isReadOnly)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status: Challenged',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Select Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.orange[700]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.orange[700]!),
                          ),
                        ),
                        items: _statusOptions.map((String status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedStatus = newValue;
                          });
                        },
                        validator: (value) {
                          if (!widget.isReadOnly && value == null) {
                            return 'Please select a status';
                          }
                          return null;
                        },
                      ),
                    const SizedBox(height: 20),
                    // Remarks Text Field
                    TextFormField(
                      controller: _remarksController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: 'Enter Remarks',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.orange[700]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.orange[700]!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter remarks';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Submit Button
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitRemarks,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        child: const Text(
                          'Submit Remarks',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}