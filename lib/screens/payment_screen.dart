import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../models/car.dart';
import 'package:intl/intl.dart';
import 'my_bookings_screen.dart';
import '../providers/language_provider.dart';

class PaymentScreen extends StatefulWidget {
  final Car car;
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  final String pickupLocation;
  final String dropoffLocation;
  final String customerName;
  final String customerPhone;
  final double distance;

  const PaymentScreen({
    super.key, 
    required this.car, 
    required this.amount,
    required this.startDate,
    required this.endDate,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.customerName,
    required this.customerPhone,
    required this.distance,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final NumberFormat _currencyFormat = NumberFormat.decimalPattern();
  bool _isProcessing = false;
  String? _selectedMethod;

  final Map<String, String> _lipaNambaDetails = {
    'M-Pesa': '556677',
    'Tigo Pesa': '889900',
    'Airtel Money': '112233',
    'HaloPesa': '445566',
  };

  Future<void> _processPayment() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.translate('Please select a payment method first', 'Tafadhali chagua njia ya malipo kwanza')), backgroundColor: Colors.orange),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.translate('Please login to your account first', 'Tafadhali ingia kwenye akaunti kwanza')), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // 1. Create the booking
      final bookingRef = await FirebaseFirestore.instance.collection('bookings').add({
        'userId': user.uid,
        'customerName': widget.customerName,
        'customerPhone': widget.customerPhone,
        'carId': widget.car.id,
        'carBrand': widget.car.brand,
        'carModel': widget.car.model,
        'carImage': widget.car.imageUrl,
        'driverId': widget.car.driverId, 
        'driverName': widget.car.driverName,
        'driverPhone': widget.car.driverPhone,
        'driverAge': widget.car.driverAge,
        'driverImage': widget.car.driverImage,
        'totalAmount': widget.amount,
        'distance': widget.distance,
        'startDate': Timestamp.fromDate(widget.startDate),
        'endDate': Timestamp.fromDate(widget.endDate),
        'pickupLocation': widget.pickupLocation,
        'dropoffLocation': widget.dropoffLocation,
        'bookingDate': Timestamp.now(), 
        'status': 'pending',
        'paymentMethod': _selectedMethod,
        'companyName': 'CARRENTAL PRO COMPANY LIMITED',
      });

      // 2. Notify the driver about the new request
      if (widget.car.driverId != null && widget.car.driverId!.isNotEmpty) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'target': widget.car.driverId,
          'title': lang.translate('New Booking Request', 'Ombi Jipya la Safari'),
          'message': lang.translate(
            '${widget.customerName} has requested a booking for ${widget.car.brand} ${widget.car.model}. Admin approval pending.',
            '${widget.customerName} ameomba safari ya ${widget.car.brand} ${widget.car.model}. Inasubiri idhini ya Admin.'
          ),
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'type': 'new_booking',
          'bookingId': bookingRef.id,
        });
      }

      if (mounted) {
        _showSuccessDialog(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lang.translate('Technical error: ', 'Kuna tatizo la kiufundi: ') + e.toString()), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(lang.translate('Trip Payment', 'Malipo ya Safari'), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isProcessing 
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const CircularProgressIndicator(), const SizedBox(height: 20), Text(lang.translate('Confirming Payment...', 'Tunathibitisha Malipo...'))]))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF003399), Color(0xFF0044BB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lang.translate('PAY TO THE NAME OF:', 'LIPA KWA JINA LA:'), style: const TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.2)),
                      const SizedBox(height: 4),
                      const Text('CARRENTAL PRO COMPANY LIMITED', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(lang.translate('Travel Distance:', 'Umbali wa Safari:'), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                          Text('${widget.distance.toStringAsFixed(1)} KM', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(lang.translate('Total Payment:', 'Jumla ya Malipo:'), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                          Text('${_currencyFormat.format(widget.amount)} Tsh', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                Text(lang.translate('Select Payment Method', 'Chagua Njia ya Malipo'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1D275F))),
                const SizedBox(height: 16),
                
                _buildMethod('M-Pesa', Icons.phone_android, Colors.red),
                _buildMethod('Tigo Pesa', Icons.phone_android, Colors.blue),
                _buildMethod('Airtel Money', Icons.phone_android, Colors.redAccent),
                _buildMethod('HaloPesa', Icons.phone_android, Colors.orange),

                if (_selectedMethod != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_rounded, color: Colors.blueAccent),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                lang.translate('Payment Instructions', 'Maelekezo ya Malipo') + ' ($_selectedMethod)',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1D275F)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          lang.translate('Pay Tsh ${_currencyFormat.format(widget.amount)} to Lipa Number: ${_lipaNambaDetails[_selectedMethod]} with the name CARRENTAL PRO COMPANY LIMITED.', 'Lipa Tsh ${_currencyFormat.format(widget.amount)} kwenda Lipa Namba: ${_lipaNambaDetails[_selectedMethod]} huku jina likisoma CARRENTAL PRO COMPANY LIMITED.'),
                          style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 0,
                    ),
                    child: Text(lang.translate('Confirm Payment (Pay Now)', 'Thibitisha Malipo (Pay Now)'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Widget _buildMethod(String name, IconData icon, Color color) {
    bool isSelected = _selectedMethod == name;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = name),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? Colors.blueAccent : Colors.transparent, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1D275F))),
            const Spacer(),
            Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: isSelected ? Colors.blueAccent : Colors.grey[300]),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 85),
            const SizedBox(height: 24),
            Text(lang.translate('Congratulations!', 'Hongera!'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1D275F))),
            const SizedBox(height: 12),
            Text(
              lang.translate('Your payment has been submitted. It is now pending Admin approval. You will see the update in your bookings page shortly.', 'Malipo yako yametumwa. Sasa yanasubiri kuthibitishwa na Admin. Utaona mabadiliko kwenye ukurasa wako wa safari hivi punde.'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); 
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const MyBookingsScreen()),
                    (route) => route.isFirst,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: Text(lang.translate('View My Trip', 'Angalia Safari Yangu'), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
