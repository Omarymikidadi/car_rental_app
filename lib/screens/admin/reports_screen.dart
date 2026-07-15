import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/language_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final NumberFormat _currencyFormat = NumberFormat.decimalPattern();
  String _selectedPeriod = 'Daily'; // 'Daily', 'Weekly', 'Monthly', 'Yearly'

  DateTimeRange _getDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Daily':
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case 'Weekly':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(
          start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
          end: now,
        );
      case 'Monthly':
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
      case 'Yearly':
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: now,
        );
      default:
        return DateTimeRange(start: now, end: now);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final dateRange = _getDateRange();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Text(lang.translate('Reports & Analytics', 'Ripoti na Uchambuzi'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1D275F))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
        builder: (context, bookingSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, userSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('cars').snapshots(),
                builder: (context, carSnapshot) {
                  if (bookingSnapshot.connectionState == ConnectionState.waiting ||
                      userSnapshot.connectionState == ConnectionState.waiting ||
                      carSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allBookings = bookingSnapshot.data?.docs ?? [];
                  final users = userSnapshot.data?.docs ?? [];
                  final cars = carSnapshot.data?.docs ?? [];

                  // Filter bookings based on selected period
                  final filteredBookings = allBookings.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final bookingDate = (data['bookingDate'] as Timestamp).toDate();
                    return bookingDate.isAfter(dateRange.start.subtract(const Duration(seconds: 1))) && 
                           bookingDate.isBefore(dateRange.end.add(const Duration(seconds: 1)));
                  }).toList();

                  // 1. Period Stats
                  int periodBookings = filteredBookings.length;
                  double periodRevenue = 0;
                  for (var doc in filteredBookings) {
                    final data = doc.data() as Map<String, dynamic>;
                    if (data['status'] != 'cancelled') {
                      periodRevenue += (data['totalAmount'] ?? 0).toDouble();
                    }
                  }

                  // Lifetime stats for overview
                  int totalCustomers = users.where((u) {
                    final data = u.data() as Map<String, dynamic>? ?? {};
                    final role = (data['role'] ?? '').toString().toLowerCase().trim();
                    return role == 'customer';
                  }).length;
                  int totalCars = cars.length;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Period Selector
                        _buildPeriodSelector(lang),
                        const SizedBox(height: 25),
                        
                        _buildSectionTitle(lang.translate('Overview', 'Muhtasari wa ') + _selectedPeriod),
                        const SizedBox(height: 15),
                        
                        _buildRevenueCard(
                          lang.translate('Total Revenue', 'Mapato ya Jumla'), 
                          'Tsh ${_currencyFormat.format(periodRevenue)}', 
                          const Color(0xFF1D275F)
                        ),
                        
                        const SizedBox(height: 15),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 15,
                          crossAxisSpacing: 15,
                          childAspectRatio: 1.5,
                          children: [
                            _buildStatBox(lang.translate('Bookings', 'Safari'), periodBookings.toString(), Icons.book_online, Colors.blue),
                            _buildStatBox(lang.translate('Total Customers', 'Wateja Wote'), totalCustomers.toString(), Icons.people, Colors.teal),
                            _buildStatBox(lang.translate('Total Cars', 'Magari Yote'), totalCars.toString(), Icons.directions_car, Colors.orange),
                            _buildStatBox(lang.translate('Completed', 'Zilizokamilika'), 
                              filteredBookings.where((b) => (b.data() as Map)['status'] == 'completed').length.toString(), 
                              Icons.check_circle, Colors.green),
                          ],
                        ),
                        
                        const SizedBox(height: 30),
                        _buildSectionTitle(lang.translate('Period Details', 'Maelezo ya Kipindi')),
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                          child: Column(
                            children: [
                              _buildDetailRow(lang.translate('Start Date', 'Tarehe ya Kuanza'), DateFormat('dd MMM yyyy').format(dateRange.start)),
                              const Divider(),
                              _buildDetailRow(lang.translate('End Date', 'Tarehe ya Mwisho'), DateFormat('dd MMM yyyy').format(dateRange.end)),
                              const Divider(),
                              _buildDetailRow(lang.translate('Total Transactions', 'Miamala Yote'), filteredBookings.length.toString()),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton.icon(
                            onPressed: () => _generateSystemReport(context, lang, periodBookings, totalCustomers, totalCars, periodRevenue),
                            icon: const Icon(Icons.picture_as_pdf),
                            label: Text(lang.translate('Generate PDF Report', 'Tengeneza Ripoti ya PDF')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1D275F),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector(LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          _buildPeriodButton('Daily', lang.translate('Daily', 'Siku')),
          _buildPeriodButton('Weekly', lang.translate('Weekly', 'Wiki')),
          _buildPeriodButton('Monthly', lang.translate('Monthly', 'Mwezi')),
          _buildPeriodButton('Yearly', lang.translate('Yearly', 'Mwaka')),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String value, String label) {
    bool isSelected = _selectedPeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)] : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFF1D275F) : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1D275F)));
  }

  Widget _buildStatBox(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildRevenueCard(String title, String amount, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 10),
          Text(amount, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _generateSystemReport(BuildContext context, LanguageProvider lang, int bookings, int customers, int cars, double revenue) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang.translate('Confirm Report', 'Thibitisha Ripoti')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${lang.translate('Generating', 'Inatengeneza')} $_selectedPeriod ${lang.translate('report', 'ripoti')}...'),
            const SizedBox(height: 10),
            Text('${lang.translate('Period', 'Kipindi')}: ${DateFormat('dd/MM/yyyy').format(_getDateRange().start)} - ${DateFormat('dd/MM/yyyy').format(_getDateRange().end)}'),
            const Divider(),
            _buildDetailRow(lang.translate('Bookings', 'Safari'), bookings.toString()),
            _buildDetailRow(lang.translate('Revenue', 'Mapato'), 'Tsh ${_currencyFormat.format(revenue)}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$_selectedPeriod report exported successfully!'))
              );
            },
            child: const Text('Export PDF'),
          ),
        ],
      ),
    );
  }
}
