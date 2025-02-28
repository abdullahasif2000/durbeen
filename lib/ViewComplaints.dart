import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'ComplaintHistory.dart';
import 'AddComplaintRemarks.dart';

class ViewComplaints extends StatefulWidget {
  const ViewComplaints({Key? key}) : super(key: key);

  @override
  _ViewComplaintsState createState() => _ViewComplaintsState();
}

class _ViewComplaintsState extends State<ViewComplaints> {
  String? role;
  String? department;
  String selectedStatus = 'In Process';
  List<dynamic> complaints = [];
  final Set<int> _expandedCards = {};

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      role = prefs.getString('Role');
      department = prefs.getString('Department');
    });
    _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    if (role != null && department != null) {
      final fetchedComplaints = await ApiService().fetchDepartmentsComplaints(
        role: role!,
        department: department!,
        status: selectedStatus,
      );

      // Decode the complaint strings
      for (var complaint in fetchedComplaints) {
        if (complaint['Complaint'] != null) {
          complaint['Complaint'] = Uri.decodeComponent(complaint['Complaint']);
        }
      }

      setState(() {
        complaints = fetchedComplaints;
      });
    }
  }

  void _toggleCard(int index) {
    setState(() {
      if (_expandedCards.contains(index)) {
        _expandedCards.remove(index);
      } else {
        _expandedCards.add(index);
      }
    });
  }

  void _navigateToHistory(int complaintID) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComplaintHistory(complaintID: complaintID),
      ),
    );
  }

  void _navigateToAddRemarks(int complaintID, String email, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddComplaintRemarks(
          complaintID: complaintID,
          email: email,
          name: name, department: '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Complaints'),
        backgroundColor: Colors.orange[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: selectedStatus,
              onChanged: (String? newValue) {
                setState(() {
                  selectedStatus = newValue!;
                });
                _fetchComplaints();
              },
              items: <String>['In Process', 'Resolved', 'False']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: complaints.isEmpty
                  ? Center(
                child: Text(
                  'No data available',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              )
                  : ListView.builder(
                itemCount: complaints.length,
                itemBuilder: (context, index) {
                  final complaint = complaints[index];
                  final isExpanded = _expandedCards.contains(index);

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Section
                          GestureDetector(
                            onTap: () => _toggleCard(index),
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ID: ${complaint['id'] ?? 'N/A'}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    Text(
                                      'Complainant ID: ${complaint['ComplainantID'] ?? 'N/A'}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  isExpanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                          ),

                          // Collapsible Content
                          AnimatedCrossFade(
                            duration: const Duration(milliseconds: 300),
                            crossFadeState: isExpanded
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            firstChild: Container(),
                            secondChild: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 12),
                                _buildInfoRow('Entry Date',
                                    complaint['EntryDate']?.toString()),
                                _buildInfoRow('Resolve Date',
                                    complaint['ResolveDate']?.toString()),
                                _buildStatusRow(
                                    complaint['Status']?.toString()),
                                const Divider(),
                                _buildInfoRow(
                                    'Name', complaint['Name']?.toString()),
                                _buildInfoRow('Email',
                                    complaint['Email']?.toString()),
                                _buildInfoRow('Mobile',
                                    complaint['Mobile']?.toString()),
                                _buildInfoRow('Request Type',
                                    complaint['RequestType']?.toString()),
                                _buildInfoRow('Department',
                                    complaint['Department']?.toString()),
                                const SizedBox(height: 10),
                                Text(
                                  'Complaint:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  complaint['Complaint']?.toString() ?? '',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 10),

                                if (complaint['Status'] == 'In Process')
                                  GestureDetector(
                                    onTap: () {
                                      final complaintId = complaint['id'];
                                      final email = complaint['Email']?.toString() ?? '';
                                      final name = complaint['Name']?.toString() ?? '';
                                      if (complaintId != null) {
                                        final id = int.tryParse(complaintId.toString());
                                        if (id != null) {
                                          _navigateToAddRemarks(id, email, name);
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Invalid complaint ID format')),
                                          );
                                        }
                                      }
                                    },
                                    child: Row(
                                      children: [
                                        const Icon(Icons.add_comment, color: Colors.green),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Add Remarks',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          GestureDetector(
                            onTap: () {
                              final complaintId = complaint['id'];
                              if (complaintId != null) {
                                final id = int.tryParse(complaintId.toString());
                                if (id != null) {
                                  _navigateToHistory(id);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Invalid complaint ID format')),
                                  );
                                }
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Icon(Icons.history, color: Colors.blue),
                                const SizedBox(width: 4),
                                Text(
                                  'View Complaint History',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String? status) {
    Color statusColor = Colors.orange;
    if (status == 'Complete') statusColor = Colors.green;
    if (status == 'False') statusColor = Colors.red;
    if (status == 'In Process') statusColor = Colors.yellow;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Expanded(
            flex: 2,
            child: Text(
              'Status:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                status ?? 'N/A',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}