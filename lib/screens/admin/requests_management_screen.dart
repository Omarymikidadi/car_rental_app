import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/language_provider.dart';

class RequestsManagementScreen extends StatelessWidget {
  const RequestsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Text(lang.translate('Availability Requests', 'Maombi ya Upatikanaji'), 
          style: const TextStyle(color: Color(0xFF1D275F), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1D275F)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('availability_requests')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mark_email_read_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(lang.translate('No requests found', 'Hakuna maombi yoyote'), 
                    style: const TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final requestId = docs[index].id;
              final status = data['status'] ?? 'pending';
              final isPending = status == 'pending';

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                ),
                child: ExpansionTile(
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                  collapsedShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                  backgroundColor: Colors.white,
                  leading: CircleAvatar(
                    backgroundColor: isPending ? Colors.orange.withOpacity(0.1) : (status == 'approved' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1)),
                    child: Icon(
                      isPending ? Icons.pending_outlined : (status == 'approved' ? Icons.check_circle_outline : Icons.cancel_outlined),
                      color: isPending ? Colors.orange : (status == 'approved' ? Colors.green : Colors.red),
                    ),
                  ),
                  title: Text(data['driverName'] ?? 'Unknown Driver', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(status.toUpperCase(), style: TextStyle(color: isPending ? Colors.orange : (status == 'approved' ? Colors.green : Colors.red), fontSize: 12, fontWeight: FontWeight.bold)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          const SizedBox(height: 10),
                          _buildInfoRow(lang.translate('Reason', 'Sababu'), data['reason'] ?? 'N/A'),
                          _buildInfoRow(lang.translate('Date', 'Tarehe'), data['timestamp'] != null ? DateFormat('dd MMM yyyy, HH:mm').format((data['timestamp'] as Timestamp).toDate()) : 'N/A'),
                          if (isPending) ...[
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _handleRequest(context, requestId, data, 'denied'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: Text(lang.translate('Deny', 'Kataa'), style: const TextStyle(color: Colors.white)),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _handleRequest(context, requestId, data, 'approved'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: Text(lang.translate('Approve', 'Thibitisha'), style: const TextStyle(color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text('$label:', style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }

  Future<void> _handleRequest(BuildContext context, String requestId, Map<String, dynamic> data, String newStatus) async {
    try {
      final driverId = data['driverId'];
      final carId = data['carId'];
      final finalStatus = newStatus == 'approved' ? 'unavailable' : 'available';

      // 1. Update the request status
      await FirebaseFirestore.instance.collection('availability_requests').doc(requestId).update({
        'status': newStatus,
        'processedAt': FieldValue.serverTimestamp(),
      });

      // 2. Update the user/driver status
      await FirebaseFirestore.instance.collection('users').doc(driverId).update({
        'availabilityStatus': finalStatus,
      });

      // 3. Update the car status
      if (carId != null) {
        await FirebaseFirestore.instance.collection('cars').doc(carId).update({
          'status': finalStatus,
          'unavailableReason': newStatus == 'approved' ? data['reason'] : '',
        });
      }

      // 4. Send notification back to driver
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': driverId,
        'title': newStatus == 'approved' ? 'Request Approved' : 'Request Denied',
        'message': newStatus == 'approved' 
            ? 'Your request to set the vehicle as unavailable has been approved.' 
            : 'Your request to set the vehicle as unavailable was denied.',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'type': 'request_result',
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request $newStatus successfully'))
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
