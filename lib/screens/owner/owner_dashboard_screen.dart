import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../providers/language_provider.dart';
import '../../providers/user_provider.dart';

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final currencyFormat = NumberFormat.decimalPattern();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      appBar: AppBar(
        title: Text(lang.translate('Owner Dashboard', 'Dashboard ya Mmiliki'), 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // WELCOME SECTION
            Text(
              '${lang.translate('Hello', 'Habari')}, ${userProvider.name.split(' ')[0]}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1D275F)),
            ),
            Text(
              lang.translate('Here is your business overview today.', 'Hapa ni muhtasari wa biashara yako leo.'),
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 25),

            // STATS GRID
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('ownerId', isEqualTo: userId) // Tunahitaji kuhifadhi ownerId kwenye bookings pia baadae
                  .snapshots(),
              builder: (context, snapshot) {
                double totalEarnings = 0;
                int totalBookings = 0;
                
                if (snapshot.hasData) {
                  totalBookings = snapshot.data!.docs.length;
                  for (var doc in snapshot.data!.docs) {
                    totalEarnings += (doc.data() as Map<String, dynamic>)['totalAmount'] ?? 0;
                  }
                }

                return Column(
                  children: [
                    // EARNINGS CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF003399), Color(0xFF001F5C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF003399).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(lang.translate('Total Earnings', 'Jumla ya Mapato'), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                              const Icon(Icons.account_balance_wallet_outlined, color: Colors.white70),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${currencyFormat.format(totalEarnings)} Tsh',
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '+12% ${lang.translate('from last month', 'kutoka mwezi uliopita')}',
                            style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        _buildStatSmallCard(
                          lang.translate('Active Cars', 'Magari Hewani'), 
                          '--', // Tutapata hii kutoka kwa cars collection
                          Icons.directions_car_filled_rounded, 
                          Colors.blue,
                          FirebaseFirestore.instance.collection('cars').where('ownerId', isEqualTo: userId).snapshots(),
                        ),
                        const SizedBox(width: 15),
                        _buildStatSmallCard(
                          lang.translate('Bookings', 'Safari'), 
                          totalBookings.toString(), 
                          Icons.calendar_today_rounded, 
                          Colors.orange,
                          null,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 30),

            // RECENT BOOKINGS SECTION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lang.translate('Recent Requests', 'Maombi ya Karibuni'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1D275F)),
                ),
                TextButton(
                  onPressed: () {}, // Hamia kwenye Requests Tab
                  child: Text(lang.translate('View All', 'Ona Zote'), style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            
            // Tutatengeneza list hapa baadae tunapoanza kupokea bookings halisi
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: Center(
                child: Text(lang.translate('No new requests today.', 'Hakuna maombi mapya leo.')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatSmallCard(String title, String value, IconData icon, Color color, Stream<QuerySnapshot>? stream) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 15),
            stream != null 
              ? StreamBuilder<QuerySnapshot>(
                  stream: stream,
                  builder: (ctx, snap) {
                    return Text(
                      snap.hasData ? snap.data!.docs.length.toString() : '...',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    );
                  },
                )
              : Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
