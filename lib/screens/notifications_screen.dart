import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return const Scaffold(body: Center(child: Text("Please login")));

    List<String> targets = [uid];
    if (userProvider.role == 'driver') {
      targets.add('all_drivers');
    }
    if (userProvider.role == 'admin') {
      targets.add('admin');
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Text(lang.translate('Notifications', 'Taarifa'), 
            style: const TextStyle(color: Color(0xFF1D275F), fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1D275F)),
        leading: Navigator.canPop(context) 
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1D275F), size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('target', whereIn: targets)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final List<QueryDocumentSnapshot> docs = snapshot.data!.docs;
          
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 15),
                  Text(lang.translate('No new notifications', 'Hakuna taarifa mpya'), 
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          docs.sort((a, b) {
            final t1 = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
            final t2 = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
            if (t1 == null) return 1;
            if (t2 == null) return -1;
            return t2.compareTo(t1);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (ctx, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final bool isRead = (data['readBy'] as List? ?? []).contains(uid) || (data['isRead'] ?? false);

              return _buildNotificationCard(context, doc.id, data, uid, isRead, lang);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, String docId, Map<String, dynamic> data, String uid, bool isRead, LanguageProvider lang) {
    final DateTime time = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final bool isCancellation = data['type'] == 'booking_cancelled';
    final bool isReceipt = data['type'] == 'receipt';
    
    Color baseColor;
    if (isRead) {
      baseColor = Colors.white;
    } else {
      if (isReceipt) {
        baseColor = Colors.green.shade50;
      } else {
        baseColor = const Color(0xFFE8F0FE);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : baseColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        border: !isRead ? Border.all(color: isCancellation ? Colors.red.withOpacity(0.3) : (isReceipt ? Colors.green.withOpacity(0.3) : Colors.blue.withOpacity(0.3))) : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isRead ? Colors.grey[100] : (isCancellation ? Colors.red.withOpacity(0.1) : (isReceipt ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1))),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCancellation ? Icons.cancel_outlined : (isReceipt ? Icons.receipt_long : (data['target'] == 'all_drivers' || data['target'] == 'admin' ? Icons.campaign_rounded : Icons.message_rounded)),
            color: isRead ? Colors.grey : (isCancellation ? Colors.red : (isReceipt ? Colors.green : const Color(0xFF1D275F))),
          ),
        ),
        title: Text(
          data['title'] ?? '',
          style: TextStyle(fontWeight: isRead ? FontWeight.bold : FontWeight.w900, fontSize: 14, color: isCancellation && !isRead ? Colors.red[900] : (isReceipt && !isRead ? Colors.green[900] : null)),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text(data['message'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Colors.blueGrey[700])),
            const SizedBox(height: 8),
            Text(DateFormat('dd MMM, HH:mm').format(time), style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        onTap: () => _showNotificationDetail(context, docId, data, uid, lang),
      ),
    );
  }

  void _showNotificationDetail(BuildContext context, String docId, Map<String, dynamic> data, String uid, LanguageProvider lang) async {
    if (data['target'] == 'all_drivers') {
      await FirebaseFirestore.instance.collection('notifications').doc(docId).update({
        'readBy': FieldValue.arrayUnion([uid])
      });
    } else {
      await FirebaseFirestore.instance.collection('notifications').doc(docId).update({'isRead': true});
    }

    if (!context.mounted) return;

    final bool isCancellation = data['type'] == 'booking_cancelled';
    final bool isReceipt = data['type'] == 'receipt';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 25),
            Row(
              children: [
                Icon(
                  isCancellation ? Icons.warning_rounded : (isReceipt ? Icons.verified_rounded : Icons.info_outline), 
                  color: isCancellation ? Colors.red : (isReceipt ? Colors.green : const Color(0xFF1D275F)), 
                  size: 28
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(data['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isCancellation ? Colors.red : (isReceipt ? Colors.green : const Color(0xFF1D275F)))),
                ),
              ],
            ),
            const Divider(height: 40),
            Text(data['message'] ?? '', style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87)),
            
            if (isReceipt && data['bookingId'] != null) ...[
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final bookingDoc = await FirebaseFirestore.instance.collection('bookings').doc(data['bookingId']).get();
                    if (bookingDoc.exists) {
                      _generateAndDownloadPdf(bookingDoc.data() as Map<String, dynamic>, lang);
                    }
                  },
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                  label: Text(lang.translate('Download Receipt (PDF)', 'Pakua Risiti (PDF)'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                ),
              ),
            ],

            if (isCancellation && data['routeDetails'] != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.red.withOpacity(0.1))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lang.translate('Route Details:', 'Maelezo ya Safari:'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red)),
                    const SizedBox(height: 10),
                    _buildDetailRow(Icons.location_on, '${data['routeDetails']['pickup']} → ${data['routeDetails']['dropoff']}'),
                    _buildDetailRow(Icons.calendar_today, DateFormat('dd MMM yyyy').format((data['routeDetails']['startDate'] as Timestamp).toDate())),
                    _buildDetailRow(Icons.directions_car, data['routeDetails']['car']),
                    _buildDetailRow(Icons.person, data['routeDetails']['customer']),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(lang.translate('Close', 'Funga'), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[800]))),
        ],
      ),
    );
  }

  Future<void> _generateAndDownloadPdf(Map<String, dynamic> data, LanguageProvider lang) async {
    final pdf = pw.Document();
    final NumberFormat currencyFormat = NumberFormat.decimalPattern();
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
                    pw.Text('Tsh ${currencyFormat.format(data['totalAmount'])}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
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
