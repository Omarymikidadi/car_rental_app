import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
  Stream<QuerySnapshot>? _bookingsStream;
  final User? _user = FirebaseAuth.instance.currentUser;
  late TabController _tabController;
  final NumberFormat _currencyFormat = NumberFormat.decimalPattern();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.delayed(Duration.zero, () => _setupStream());
  }

  void _setupStream() {
    if (_user == null || !mounted) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    Query query = FirebaseFirestore.instance.collection('bookings');
    
    if (userProvider.role == 'driver') {
      query = query.where('driverId', isEqualTo: _user!.uid);
    } else if (userProvider.role == 'customer') {
      query = query.where('userId', isEqualTo: _user!.uid);
    }
    
    setState(() {
      _bookingsStream = query.orderBy('bookingDate', descending: true).snapshots();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    String title = lang.translate('My Bookings', 'Safari Zangu');
    if (userProvider.role == 'driver') title = lang.translate('Assigned Trips', 'Safari Nilizopangiwa');
    else if (userProvider.role == 'admin') title = lang.translate('All Bookings', 'Safari Zote');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        backgroundColor: const Color(0xFF1D275F),
        elevation: 0,
        centerTitle: true,
        leading: Navigator.canPop(context) 
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: lang.translate('Active', 'Zilizopo')),
            Tab(text: lang.translate('History', 'Zilizopita')),
          ],
        ),
      ),
      body: _user == null
          ? Center(child: Text(lang.translate('Please login', 'Tafadhali ingia')))
          : StreamBuilder<QuerySnapshot>(
              stream: _bookingsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) return _buildErrorState(lang);
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF1D275F)));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState(lang);

                final allDocs = snapshot.data!.docs;
                
                final activeBookings = allDocs.where((doc) {
                  final status = (doc.data() as Map<String, dynamic>)['status'] ?? 'pending';
                  return status == 'pending' || status == 'confirmed' || status == 'started';
                }).toList();

                final pastBookings = allDocs.where((doc) {
                  final status = (doc.data() as Map<String, dynamic>)['status'] ?? 'pending';
                  return status == 'completed' || status == 'cancelled';
                }).toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBookingsList(activeBookings, userProvider.role, lang, _currencyFormat),
                    _buildBookingsList(pastBookings, userProvider.role, lang, _currencyFormat),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildBookingsList(List<QueryDocumentSnapshot> docs, String role, LanguageProvider lang, NumberFormat format) {
    if (docs.isEmpty) return _buildEmptyState(lang);

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: docs.length,
      itemBuilder: (ctx, index) {
        final doc = docs[index];
        final data = doc.data() as Map<String, dynamic>;
        _autoUpdateTripStatus(doc.id, data);
        return _buildModernBookingCard(doc.id, data, role, lang, format);
      },
    );
  }

  void _autoUpdateTripStatus(String id, Map<String, dynamic> data) {
    final status = data['status'] ?? 'pending';
    if (status == 'completed' || status == 'cancelled') return;
    final Timestamp? startTs = data['startDate'] as Timestamp?;
    final Timestamp? endTs = data['endDate'] as Timestamp?;
    if (startTs == null || endTs == null) return;
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime tripStartDay = DateTime(startTs.toDate().year, startTs.toDate().month, startTs.toDate().day);
    
    if (status == 'confirmed' && (today.isAtSameMomentAs(tripStartDay) || today.isAfter(tripStartDay))) {
      _updateBookingStatus(id, 'started');
    }
    
    final DateTime completionTime = DateTime(endTs.toDate().year, endTs.toDate().month, endTs.toDate().day, 23, 59, 59);
    if (status == 'started' && now.isAfter(completionTime)) {
      _updateBookingStatus(id, 'completed');
    }
  }

  Widget _buildModernBookingCard(String bookingId, Map<String, dynamic> data, String role, LanguageProvider lang, NumberFormat format) {
    final String status = data['status'] ?? 'pending';
    final DateTime startDate = (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    final DateTime endDate = (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    final double price = (data['totalAmount'] ?? 0).toDouble();
    final String pickup = data['pickupLocation'] ?? 'N/A';
    final String dropoff = data['dropoffLocation'] ?? 'N/A';
    final String carName = '${data['carBrand'] ?? ''} ${data['carModel'] ?? ''}';

    Color statusColor = _getStatusColor(status);
    bool isPast = status == 'completed' || status == 'cancelled';
    bool showReceipt = (status == 'confirmed' || status == 'started' || status == 'completed') && role == 'customer';

    bool canCustomerCancel = false;
    final Timestamp? bookingTs = data['bookingDate'] as Timestamp?;
    if (role == 'customer' && bookingTs != null && (status == 'pending' || status == 'confirmed')) {
      final DateTime bookingTime = bookingTs.toDate();
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(bookingTime);
      if (difference.inHours < 5) {
        canCustomerCancel = true;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_month_outlined, size: 16, color: statusColor),
                    const SizedBox(width: 8),
                    Text(
                      '${DateFormat('dd MMM').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: statusColor),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildModernStatusBadge(status, lang),
                    if (showReceipt) ...[
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => _generateAndDownloadPdf(bookingId, data, lang),
                        child: Icon(Icons.receipt_long, color: statusColor, size: 20),
                      ),
                    ],
                    if ((role == 'customer' || role == 'admin') && isPast) ...[
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => _showDeleteConfirmation(bookingId, lang),
                        child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 50, width: 50,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : const Color(0xFFF1F4F9), 
                        borderRadius: BorderRadius.circular(15)
                      ),
                      child: const Icon(Icons.directions_car_filled_rounded, color: Color(0xFF1D275F), size: 28),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(carName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.titleLarge?.color)),
                          const SizedBox(height: 2),
                          Text(
                            role == 'customer' 
                              ? '${lang.translate('Driver', 'Dereva')}: ${data['driverName'] ?? 'N/A'}'
                              : '${lang.translate('Client', 'Mteja')}: ${data['customerName'] ?? 'N/A'}',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(lang.translate('Total', 'Jumla'), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                        Text(format.format(price), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF003399))),
                        const Text('TZS', style: TextStyle(color: Color(0xFF003399), fontSize: 9, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                ),

                Row(
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.circle, color: Colors.blue, size: 10),
                        Container(width: 1, height: 20, color: Colors.grey[300]),
                        const Icon(Icons.location_on, color: Colors.redAccent, size: 12),
                      ],
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pickup, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 12),
                          Text(dropoff, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),

                if (status == 'confirmed' || status == 'started' || status == 'pending') ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (status == 'confirmed' || status == 'started') ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _openGoogleMapsRoute(pickup, dropoff),
                            icon: const Icon(Icons.map_outlined, size: 18),
                            label: Text(lang.translate('Route', 'Ramani')),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue,
                              side: const BorderSide(color: Colors.blue),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              String? phone = role == 'customer' ? data['driverPhone'] : data['customerPhone'];
                              _makeCall(phone);
                            },
                            icon: const Icon(Icons.phone_outlined, size: 18, color: Colors.white),
                            label: Text(lang.translate('Call', 'Pigia Simu'), style: const TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                      if ((role == 'driver' && (status == 'confirmed' || status == 'pending')) || canCustomerCancel) ...[
                         if (status == 'confirmed' || status == 'started') const SizedBox(width: 12),
                         Expanded(
                           child: OutlinedButton.icon(
                             onPressed: () => _showCancelConfirmation(bookingId, status, data, lang),
                             icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                             label: Text(lang.translate('Cancel', 'Ghairi')),
                             style: OutlinedButton.styleFrom(
                               foregroundColor: Colors.red,
                               side: const BorderSide(color: Colors.red),
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                             ),
                           ),
                         ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String bookingId, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang.translate('Delete History', 'Futa Historia')),
        content: Text(lang.translate('Are you sure you want to delete this booking from your history?', 'Je, una uhakika unataka kufuta safari hii kwenye historia yako?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(lang.translate('Cancel', 'Ghairi')),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('bookings').doc(bookingId).delete();
              if (mounted) Navigator.pop(ctx);
            },
            child: Text(lang.translate('Delete', 'Futa'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmation(String bookingId, String currentStatus, Map<String, dynamic> data, LanguageProvider lang) {
    if (currentStatus == 'started') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.translate('Cannot cancel a trip that has already started', 'Huwezi kughairi safari ambayo tayari imeanza')))
      );
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String role = userProvider.role;

    String warningMessage = role == 'customer'
        ? lang.translate(
            'Canceling this trip will result in a penalty or removal of offers until a month passes.',
            'Kughairi safari hii kutasababisha kupunguziwa au kuondolewa offa mpaka baada ya mwezi kupita.'
          )
        : lang.translate(
            'Canceling this trip will result in a penalty according to company policy.', 
            'Kughairi safari hii kutasababisha kutozwa faini/penati kulingana na sera ya kampuni.'
          );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 10),
            Text(lang.translate('Warning!', 'Onyo!'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              warningMessage,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Text(lang.translate('Are you sure you want to proceed?', 'Je, una uhakika unataka kuendelea?')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(lang.translate('No, Go Back', 'Hapana, Rudi')),
          ),
          ElevatedButton(
            onPressed: () {
              _handleCancellation(bookingId, data, lang);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(lang.translate('Yes, Cancel', 'Ndiyo, Ghairi'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCancellation(String bookingId, Map<String, dynamic> data, LanguageProvider lang) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final String role = userProvider.role;
      
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({'status': 'cancelled'});
      
      String notificationTitle = role == 'customer' ? 'Booking Cancelled by Customer' : 'Booking Cancelled by Driver';
      String cancelerName = role == 'customer' ? (data['customerName'] ?? 'Unknown') : (data['driverName'] ?? 'Unknown');
      
      await FirebaseFirestore.instance.collection('notifications').add({
        'target': 'admin',
        'userId': 'admin',
        'title': notificationTitle,
        'message': '${role == 'customer' ? 'Customer' : 'Driver'} $cancelerName cancelled trip: ${data['carBrand']} ${data['carModel']}. Route: ${data['pickupLocation']} to ${data['dropoffLocation']}. Date: ${DateFormat('dd MMM yyyy').format((data['startDate'] as Timestamp).toDate())}.',
        'type': 'booking_cancelled',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'bookingId': bookingId,
        'driverId': data['driverId'],
        'userId': data['userId'],
        'routeDetails': {
          'pickup': data['pickupLocation'],
          'dropoff': data['dropoffLocation'],
          'startDate': data['startDate'],
          'endDate': data['endDate'],
          'car': '${data['carBrand']} ${data['carModel']}',
          'customer': data['customerName']
        }
      });

      if (mounted) {
        userProvider.fetchBookingCount();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lang.translate('Booking cancelled and admin notified', 'Safari imehairiwa na admin amejulishwa')))
        );
      }
    } catch (e) {
      debugPrint("Cancellation error: $e");
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed': return Colors.green;
      case 'started': return Colors.blue;
      case 'completed': return Colors.teal;
      case 'cancelled': return Colors.red;
      default: return Colors.orange;
    }
  }

  Widget _buildModernStatusBadge(String status, LanguageProvider lang) {
    Color color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(
        status.toUpperCase(), 
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  Future<void> _makeCall(String? phone) async { 
    if (phone == null || phone.isEmpty) return; 
    final Uri url = Uri(scheme: 'tel', path: phone); 
    if (await canLaunchUrl(url)) await launchUrl(url); 
  }

  Future<void> _openGoogleMapsRoute(String pickup, String dropoff) async {
    final String url = "https://www.google.com/maps/dir/?api=1&origin=${Uri.encodeComponent(pickup)}&destination=${Uri.encodeComponent(dropoff)}";
    if (await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Widget _buildEmptyState(LanguageProvider lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, 
        children: [
          Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey[200]), 
          const SizedBox(height: 20), 
          Text(lang.translate('No bookings found', 'Hakuna safari zilizopatikana'), style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w500))
        ]
      ),
    );
  }

  Widget _buildErrorState(LanguageProvider lang) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.error_outline, size: 60, color: Colors.redAccent), const SizedBox(height: 15), Text(lang.translate('Error loading bookings', 'Hitilafu kupakia safari'), style: const TextStyle(color: Colors.grey))]));
  }

  Future<void> _updateBookingStatus(String id, String status) async {
    try { 
      await FirebaseFirestore.instance.collection('bookings').doc(id).update({'status': status}); 
      if (mounted) {
        Provider.of<UserProvider>(context, listen: false).fetchBookingCount();
      }
    } catch (e) { 
      debugPrint("Update failed: $e"); 
    }
  }

  Future<void> _generateAndDownloadPdf(String id, Map<String, dynamic> data, LanguageProvider lang) async {
    final pdf = pw.Document();
    final date = (data['bookingDate'] as Timestamp).toDate();
    final startDate = (data['startDate'] as Timestamp).toDate();
    final endDate = (data['endDate'] as Timestamp).toDate();
    final days = endDate.difference(startDate).inDays + 1;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text('CARRENTAL PRO COMPANY LIMITED', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 5),
                      pw.Text('OFFICIAL PAYMENT RECEIPT', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Divider(),
                pw.SizedBox(height: 20),
                _buildPdfRow('Receipt Date:', DateFormat('dd/MM/yyyy HH:mm').format(date)),
                _buildPdfRow('Customer Name:', data['customerName'] ?? 'N/A'),
                _buildPdfRow('Customer Phone:', data['customerPhone'] ?? 'N/A'),
                pw.SizedBox(height: 15),
                _buildPdfRow('Vehicle:', '${data['carBrand']} ${data['carModel']}'),
                _buildPdfRow('Rental Period:', '${DateFormat('dd MMM').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)} ($days Days)'),
                _buildPdfRow('Payment Method:', data['paymentMethod'] ?? 'Mobile Money'),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL AMOUNT PAID:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Tsh ${_currencyFormat.format(data['totalAmount'])}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                  ],
                ),
                pw.SizedBox(height: 60),
                pw.Center(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.green, width: 2)),
                    child: pw.Text('PAID & VERIFIED', style: pw.TextStyle(color: PdfColors.green, fontWeight: pw.FontWeight.bold, fontSize: 18)),
                  ),
                ),
                pw.Spacer(),
                pw.Center(
                  child: pw.Text('Thank you for choosing CarRental Pro!', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Receipt_${data['customerName']}_${DateFormat('ddMMyy').format(date)}.pdf',
    );
  }

  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
          pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}
