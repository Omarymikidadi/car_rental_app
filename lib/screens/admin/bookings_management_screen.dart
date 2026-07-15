import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/language_provider.dart';

class BookingsManagementScreen extends StatefulWidget {
  final int initialIndex;
  const BookingsManagementScreen({super.key, this.initialIndex = 0});

  @override
  State<BookingsManagementScreen> createState() => _BookingsManagementScreenState();
}

class _BookingsManagementScreenState extends State<BookingsManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NumberFormat _currencyFormat = NumberFormat.decimalPattern();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Text(lang.translate('Booking Management', 'Usimamizi wa Safari'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1D275F))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF1D275F),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1D275F),
          tabs: [
            Tab(text: lang.translate('Requests', 'Maombi')),
            Tab(text: lang.translate('Active', 'Zinazoendelea')),
            Tab(text: lang.translate('Completed', 'Zilizokamilika')),
            Tab(text: lang.translate('Cancelled', 'Zilizofutwa')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingList(['pending'], lang),
          _buildBookingList(['confirmed', 'started', 'on_the_way'], lang),
          _buildBookingList(['completed'], lang),
          _buildBookingList(['cancelled'], lang),
        ],
      ),
    );
  }

  Widget _buildBookingList(List<String> statuses, LanguageProvider lang) {
    bool isHistory = statuses.contains('completed') || statuses.contains('cancelled');

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('status', whereIn: statuses)
          .orderBy('bookingDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(25.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_sync_outlined, size: 50, color: Colors.orange),
                  const SizedBox(height: 15),
                  Text(
                    lang.translate(
                      'Setting up database index. Please click the link in your console to enable this view.', 
                      'Tunatengeneza mfumo wa kuchuja safari. Tafadhali bonyeza link kwenye log kuitengeneza.'
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(child: Text(lang.translate('No bookings found', 'Hakuna safari zilizopatikana')));
        }

        return Column(
          children: [
            if (isHistory) 
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _deleteAllHistory(statuses, lang),
                      icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red, size: 20),
                      label: Text(lang.translate('Clear All History', 'Futa Historia Yote'), 
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.05),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: docs.length,
                itemBuilder: (ctx, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final String status = data['status'] ?? 'pending';
                  final startDate = (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now();
                  final endDate = (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      leading: Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(color: const Color(0xFFF0F2F8), borderRadius: BorderRadius.circular(10)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _buildCarImage(data['carImage']),
                        ),
                      ),
                      title: Text('${data['carBrand'] ?? ''} ${data['carModel'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['customerName'] ?? 'Customer', style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          _buildStatusBadge(status, lang),
                        ],
                      ),
                      trailing: isHistory 
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                            onPressed: () => _deleteBooking(doc.id, lang),
                          )
                        : null,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(),
                              _buildDetailRow(Icons.person, lang.translate('Customer', 'Mteja'), '${data['customerName']} (${data['customerPhone']})'),
                              _buildDetailRow(Icons.drive_eta, lang.translate('Driver', 'Dereva'), '${data['driverName'] ?? 'N/A'}'),
                              _buildDetailRow(Icons.calendar_today, lang.translate('Period', 'Muda'), '${DateFormat('dd MMM').format(startDate)} - ${DateFormat('dd MMM').format(endDate)}'),
                              _buildDetailRow(Icons.payments, lang.translate('Total Price', 'Gharama'), 'Tsh ${_currencyFormat.format(data['totalAmount'] ?? 0)}'),
                              const SizedBox(height: 15),
                              Row(
                                children: [
                                  if (status == 'pending') ...[
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _updateStatus(doc.id, 'confirmed', data, lang),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                        child: Text(lang.translate('Confirm', 'Thibitisha')),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                  if (status == 'pending' || status == 'confirmed') ...[
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _confirmCancel(doc.id, lang),
                                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                                        child: Text(lang.translate('Cancel', 'Futa')),
                                      ),
                                    ),
                                  ],
                                  if (isHistory) ...[
                                    Expanded(
                                      child: TextButton.icon(
                                        onPressed: () => _deleteBooking(doc.id, lang),
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        label: Text(lang.translate('Delete Permanently', 'Futa Kabisa'), style: const TextStyle(color: Colors.red)),
                                      ),
                                    )
                                  ]
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCarImage(dynamic path) {
    if (path == null || path.toString().isEmpty) return const Icon(Icons.directions_car);
    final String sPath = path.toString();
    if (sPath.startsWith('http')) return Image.network(sPath, fit: BoxFit.cover, errorBuilder: (_,__,___)=>const Icon(Icons.directions_car));
    return Image.asset(sPath, fit: BoxFit.cover, errorBuilder: (_,__,___)=>const Icon(Icons.directions_car));
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, LanguageProvider lang) {
    Color color = Colors.amber;
    if (['confirmed', 'started', 'on_the_way'].contains(status)) color = Colors.green;
    if (status == 'completed') color = Colors.blue;
    if (status == 'cancelled') color = Colors.red;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _updateStatus(String id, String status, Map<String, dynamic> bookingData, LanguageProvider lang) async {
    await FirebaseFirestore.instance.collection('bookings').doc(id).update({'status': status});
    
    if (status == 'confirmed') {
      // Send Receipt Notification to Customer
      await FirebaseFirestore.instance.collection('notifications').add({
        'target': bookingData['userId'],
        'title': lang.translate('Booking Confirmed & Receipt', 'Safari Imethibitishwa na Risiti'),
        'message': lang.translate(
          'Your booking for ${bookingData['carBrand']} ${bookingData['carModel']} is confirmed. Total Paid: Tsh ${_currencyFormat.format(bookingData['totalAmount'])}. Order ID: ${id.substring(0, 8).toUpperCase()}',
          'Safari yako ya ${bookingData['carBrand']} ${bookingData['carModel']} imethibitishwa. Malipo: Tsh ${_currencyFormat.format(bookingData['totalAmount'])}. Namba ya Safari: ${id.substring(0, 8).toUpperCase()}'
        ),
        'type': 'receipt',
        'bookingId': id,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }
  }

  void _confirmCancel(String id, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang.translate('Cancel Booking?', 'Futa Safari?')),
        content: Text(lang.translate('Are you sure you want to cancel this booking request?', 'Je, una uhakika unataka kufuta ombi hili la safari?')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(lang.translate('No', 'Hapana'))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              FirebaseFirestore.instance.collection('bookings').doc(id).update({'status': 'cancelled'});
            },
            child: Text(lang.translate('Yes, Cancel', 'Ndiyo, Futa'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteBooking(String id, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang.translate('Delete Permanently?', 'Futa Kabisa?')),
        content: Text(lang.translate('This will remove the booking record forever.', 'Hii itaondoa kumbukumbu ya safari hii milele.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(lang.translate('Cancel', 'Ghairi'))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('bookings').doc(id).delete();
            },
            child: Text(lang.translate('Delete', 'Futa'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllHistory(List<String> statuses, LanguageProvider lang) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang.translate('Clear All History?', 'Futa Historia Yote?')),
        content: Text(lang.translate('Are you sure you want to delete ALL booking records in this category? This action cannot be undone.', 'Je, una uhakika unataka kufuta rekodi ZOTE za safari katika kundi hili? Hatua hii haiwezi kubadilishwa.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(lang.translate('Cancel', 'Ghairi'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(lang.translate('Delete All', 'Futa Zote'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('status', whereIn: statuses)
          .get();
      
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(lang.translate('History cleared', 'Historia imesafishwa'))));
      }
    }
  }
}
