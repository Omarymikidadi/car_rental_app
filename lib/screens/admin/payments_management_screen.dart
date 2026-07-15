import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../providers/language_provider.dart';

class PaymentsManagementScreen extends StatefulWidget {
  const PaymentsManagementScreen({super.key});

  @override
  State<PaymentsManagementScreen> createState() => _PaymentsManagementScreenState();
}

class _PaymentsManagementScreenState extends State<PaymentsManagementScreen> {
  final NumberFormat _currencyFormat = NumberFormat.decimalPattern();

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Text(lang.translate('Payment Management', 'Usimamizi wa Malipo'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1D275F))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('bookings').orderBy('bookingDate', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return Center(child: Text(lang.translate('No payments found', 'Hakuna malipo yaliyopatikana')));

          // Calculate Revenue
          double totalRevenue = 0;
          double pendingRevenue = 0;
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final amount = (data['totalAmount'] ?? 0).toDouble();
            final status = data['status'] ?? 'pending';
            if (status != 'cancelled') {
              totalRevenue += amount;
              if (status == 'pending') pendingRevenue += amount;
            }
          }

          return Column(
            children: [
              _buildRevenueSummary(totalRevenue, pendingRevenue, lang),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  itemBuilder: (ctx, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final String status = data['status'] ?? 'pending';
                    final amount = (data['totalAmount'] ?? 0).toDouble();
                    final date = (data['bookingDate'] as Timestamp?)?.toDate() ?? DateTime.now();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(15),
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(status).withOpacity(0.1),
                          child: Icon(Icons.payments, color: _getStatusColor(status)),
                        ),
                        title: Text('${data['customerName']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${data['paymentMethod'] ?? 'Mobile Money'} - ${DateFormat('dd MMM yyyy, HH:mm').format(date)}'),
                            const SizedBox(height: 5),
                            _buildStatusBadge(status, lang),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Tsh ${_currencyFormat.format(amount)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1D275F))),
                            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                          ],
                        ),
                        onTap: () => _showPaymentDetails(docs[index].id, data, lang),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRevenueSummary(double total, double pending, LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildRevenueCard(
              lang.translate('Total Revenue', 'Jumla ya Mapato'),
              'Tsh ${_currencyFormat.format(total)}',
              Colors.green,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildRevenueCard(
              lang.translate('Pending Verification', 'Yanasubiri Uhakiki'),
              'Tsh ${_currencyFormat.format(pending)}',
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard(String title, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(amount, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, LanguageProvider lang) {
    Color color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'completed': return Colors.green;
      case 'pending': return Colors.orange;
      case 'cancelled': return Colors.red;
      default: return Colors.blue;
    }
  }

  void _showPaymentDetails(String id, Map<String, dynamic> data, LanguageProvider lang) {
    final status = data['status'] ?? 'pending';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text(lang.translate('Transaction Details', 'Maelezo ya Muamala'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Divider(height: 30),
            _buildDetailRow(lang.translate('Customer', 'Mteja'), data['customerName']),
            _buildDetailRow(lang.translate('Phone', 'Simu'), data['customerPhone']),
            _buildDetailRow(lang.translate('Vehicle', 'Gari'), '${data['carBrand']} ${data['carModel']}'),
            _buildDetailRow(lang.translate('Method', 'Njia'), data['paymentMethod']),
            _buildDetailRow(lang.translate('Amount', 'Kiasi'), 'Tsh ${_currencyFormat.format(data['totalAmount'])}'),
            _buildDetailRow(lang.translate('Status', 'Hali'), status.toUpperCase()),
            const SizedBox(height: 30),
            if (status == 'pending')
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await FirebaseFirestore.instance.collection('bookings').doc(id).update({'status': 'confirmed'});
                    
                    // Send Receipt Notification to Customer
                    await FirebaseFirestore.instance.collection('notifications').add({
                      'target': data['userId'],
                      'title': lang.translate('Payment Verified & Receipt', 'Malipo Yamethibitishwa na Risiti'),
                      'message': lang.translate(
                        'Your payment for ${data['carBrand']} ${data['carModel']} has been verified. Total Paid: Tsh ${_currencyFormat.format(data['totalAmount'])}. Order ID: ${id.substring(0, 8).toUpperCase()}',
                        'Malipo yako ya ${data['carBrand']} ${data['carModel']} yamethibitishwa. Jumla: Tsh ${_currencyFormat.format(data['totalAmount'])}. Namba ya Safari: ${id.substring(0, 8).toUpperCase()}'
                      ),
                      'type': 'receipt',
                      'bookingId': id,
                      'timestamp': FieldValue.serverTimestamp(),
                      'isRead': false,
                    });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  child: Text(lang.translate('Verify Payment', 'Hakiki Malipo'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showReceipt(data, lang),
                    icon: const Icon(Icons.receipt_long),
                    label: Text(lang.translate('View', 'Angalia')),
                    style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _generateAndDownloadPdf(data, lang),
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                    label: Text(lang.translate('Download', 'Pakua'), style: const TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
              ],
            ),
          ],
        ),
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

  void _showReceipt(Map<String, dynamic> data, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.car_rental, size: 50, color: Color(0xFF1D275F)),
                const SizedBox(height: 10),
                const Text('CARRENTAL PRO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const Text('OFFICIAL RECEIPT', style: TextStyle(letterSpacing: 2, fontSize: 10, color: Colors.grey)),
                const Divider(height: 40),
                _buildReceiptRow(lang.translate('Date', 'Tarehe'), DateFormat('dd/MM/yyyy').format((data['bookingDate'] as Timestamp).toDate())),
                _buildReceiptRow(lang.translate('Customer', 'Mteja'), data['customerName']),
                _buildReceiptRow(lang.translate('Vehicle', 'Gari'), '${data['carBrand']} ${data['carModel']}'),
                _buildReceiptRow(lang.translate('Days', 'Siku'), '${((data['endDate'] as Timestamp).toDate().difference((data['startDate'] as Timestamp).toDate()).inDays) + 1}'),
                const Divider(height: 30),
                _buildReceiptRow(lang.translate('Total', 'Jumla'), 'Tsh ${_currencyFormat.format(data['totalAmount'])}', isBold: true),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(border: Border.all(color: Colors.green), borderRadius: BorderRadius.circular(10)),
                  child: const Text('PAID', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, letterSpacing: 5)),
                ),
                const SizedBox(height: 20),
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Future<void> _generateAndDownloadPdf(Map<String, dynamic> data, LanguageProvider lang) async {
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

    // Share or Print the PDF
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
