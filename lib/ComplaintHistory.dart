import 'package:flutter/material.dart';
import 'api_service.dart';

class ComplaintHistory extends StatefulWidget {
  final int complaintID;

  const ComplaintHistory({Key? key, required this.complaintID}) : super(key: key);

  @override
  _ComplaintHistoryState createState() => _ComplaintHistoryState();
}

class _ComplaintHistoryState extends State<ComplaintHistory> {
  List<dynamic> complaintHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchComplaintHistory();
  }

  Future<void> _fetchComplaintHistory() async {
    final fetchedHistory = await ApiService().fetchComplaintHistory(
      complainID: widget.complaintID,
    );
    setState(() {
      complaintHistory = fetchedHistory;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint History'),
        backgroundColor: Colors.orange[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: complaintHistory.isEmpty
            ? Center(
          child: Text(
            'No history available',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        )
            : ListView.builder(
          itemCount: complaintHistory.length,
          itemBuilder: (context, index) {
            final historyItem = complaintHistory[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHistoryRow('S.No', historyItem['SNO']),
                    _buildHistoryRow('Date Updated', historyItem['DU']),
                    _buildStatusRow(historyItem['Status']),
                    _buildHistoryRow('Remarks', historyItem['Remarks']),
                    _buildHistoryRow('Remarks By', historyItem['RemarksBy']),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHistoryRow(String label, dynamic value) {
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
              value?.toString() ?? 'N/A',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String? status) {
    Color statusColor = Colors.orange;
    if (status?.toLowerCase() == 'resolved') statusColor = Colors.green;
    if (status?.toLowerCase() == 'rejected') statusColor = Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Status:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
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