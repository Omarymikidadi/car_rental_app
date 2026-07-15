import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../providers/language_provider.dart';
import '../../providers/user_provider.dart';
import '../add_car_screen.dart';
import 'add_driver_screen.dart';
import 'manage_banners_screen.dart';
import 'users_management_screen.dart';
import 'cars_management_screen.dart';
import 'bookings_management_screen.dart';
import 'payments_management_screen.dart';
import 'reports_screen.dart';
import 'requests_management_screen.dart';
import 'send_notification_screen.dart';
import 'cars_list_screen.dart';
import '../notifications_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  String _getGreeting(LanguageProvider lang) {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return lang.translate('Good Morning', 'Habari za Asubuhi');
    } else if (hour >= 12 && hour < 17) {
      return lang.translate('Good Afternoon', 'Habari za Mchana');
    } else if (hour >= 17 && hour < 21) {
      return lang.translate('Good Evening', 'Habari za Jioni');
    } else {
      return lang.translate('Good Night', 'Habari za Usiku');
    }
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return Icons.wb_sunny_outlined;
    if (hour >= 12 && hour < 17) return Icons.wb_sunny;
    if (hour >= 17 && hour < 21) return Icons.wb_twilight;
    return Icons.nightlight_round;
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FF),
      body: Column(
        children: [
          // FIXED HEADER
          _buildHeader(context, userProvider, lang),
          
          // SCROLLABLE CONTENT
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 25),
                  _buildSectionHeader(lang.translate('System Overview', 'Muhtasari wa Mfumo')),
                  const SizedBox(height: 15),
                  _buildStatsGrid(context, lang),
                  
                  const SizedBox(height: 30),
                  _buildSectionHeader(lang.translate('Pending Actions', 'Hatua Zinazosubiri')),
                  const SizedBox(height: 15),
                  _buildPendingRequestsCard(context, lang),
                  
                  const SizedBox(height: 30),
                  _buildSectionHeader(lang.translate('Management Hub', 'Kituo cha Usimamizi')),
                  const SizedBox(height: 15),
                  _buildManagementGrid(context, lang),
                  
                  const SizedBox(height: 30),
                  _buildSectionHeader(lang.translate('Recent Activities', 'Shughuli za Hivi Karibuni')),
                  const SizedBox(height: 15),
                  _buildRecentActivitiesList(lang),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserProvider user, LanguageProvider lang) {
    final DateTime now = DateTime.now();
    final DateTime startOfToday = DateTime(now.year, now.month, now.day);
    final DateTime twoDaysAgo = now.subtract(const Duration(days: 2));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(25, 60, 25, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1D275F), Color(0xFF003399)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 15,
            offset: Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_getGreetingIcon(), color: Colors.orangeAccent.withOpacity(0.8), size: 14),
                      const SizedBox(width: 6),
                      Text(_getGreeting(lang), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where('target', isEqualTo: 'admin')
                    .where('isRead', isEqualTo: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  int unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                  return Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                        child: IconButton(
                          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                }
              ),
            ],
          ),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Active Cars Stat
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('cars').snapshots(),
                  builder: (context, snapshot) {
                    String count = snapshot.hasData ? snapshot.data!.docs.length.toString() : '0';
                    return _buildHeaderStat(lang.translate('Active Cars', 'Magari'), count, Icons.car_rental);
                  },
                ),
                Container(height: 30, width: 1, color: Colors.white24),
                
                // Today Jobs Stat
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('bookings')
                      .where('bookingDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
                      .snapshots(),
                  builder: (context, snapshot) {
                    String count = snapshot.hasData ? snapshot.data!.docs.length.toString() : '0';
                    return _buildHeaderStat(lang.translate('Today Jobs', 'Kazi Leo'), count, Icons.task_alt);
                  },
                ),
                Container(height: 30, width: 1, color: Colors.white24),
                
                // New Users Stat
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users')
                      .where('role', isEqualTo: 'customer')
                      .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(twoDaysAgo))
                      .snapshots(),
                  builder: (context, snapshot) {
                    String count = snapshot.hasData ? snapshot.data!.docs.length.toString() : '0';
                    return _buildHeaderStat(lang.translate('New Customers', 'Wateja Wapya'), count, Icons.person_add);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, LanguageProvider lang) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 1.4,
      children: [
        _buildModernStatCard(
          'cars', 
          lang.translate('Total Cars', 'Magari Yote'), 
          Icons.directions_car_rounded, 
          Colors.blue,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const CarsListScreen())),
        ),
        _buildModernStatCard(
          'bookings', 
          lang.translate('Total Trips', 'Safari Zote'), 
          Icons.map_rounded, 
          Colors.orange,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const BookingsManagementScreen(initialIndex: 2))),
        ),
        _buildModernStatCard(
          'users', 
          lang.translate('Customers', 'Wateja'), 
          Icons.people_rounded, 
          Colors.teal,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const UsersManagementScreen(initialIndex: 2))),
        ),
        _buildModernStatCard('revenue', lang.translate('Net Profit', 'Faida Halisi'), Icons.payments_rounded, Colors.indigo, isCurrency: true),
      ],
    );
  }

  Widget _buildModernStatCard(String coll, String label, IconData icon, Color color, {bool isCurrency = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Icon(Icons.trending_up, color: Colors.green, size: 16),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection(coll == 'revenue' ? 'bookings' : coll).snapshots(),
                  builder: (ctx, snap) {
                    String value = '0';
                    if (coll == 'revenue') {
                      double total = 0;
                      if (snap.hasData) {
                        for (var doc in snap.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          if (data['status'] == 'completed') total += (data['totalAmount'] ?? 0).toDouble();
                        }
                      }
                      value = NumberFormat.compact().format(total);
                    } else if (coll == 'users') {
                       if (snap.hasData) {
                         value = snap.data!.docs.where((u) => (u.data() as Map)['role'] == 'customer').length.toString();
                       }
                    } else if (coll == 'bookings') {
                       if (snap.hasData) {
                         value = snap.data!.docs.where((b) {
                           final s = (b.data() as Map)['status'];
                           return s == 'confirmed' || s == 'completed' || s == 'started';
                         }).length.toString();
                       }
                    } else {
                      value = snap.hasData ? snap.data!.docs.length.toString() : '0';
                    }
                    return Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1D275F)));
                  },
                ),
                Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingRequestsCard(BuildContext context, LanguageProvider lang) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('availability_requests').where('status', isEqualTo: 'pending').snapshots(),
      builder: (context, snapshot) {
        int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const RequestsManagementScreen())),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Colors.orangeAccent, Colors.deepOrange], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.notification_important_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lang.translate('Driver Status Requests', 'Maombi ya Upatikanaji'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('$count ${lang.translate('requests need your attention', 'maombi yanahitaji usimamizi wako')}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildManagementGrid(BuildContext context, LanguageProvider lang) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 2.2,
      children: [
        _buildMenuOption(context, lang.translate('Add New Car', 'Weka Gari'), Icons.add_box_rounded, Colors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const AddCarScreen()))),
        _buildMenuOption(context, lang.translate('Add Driver', 'Weka Staff'), Icons.person_add_rounded, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const AddDriverScreen()))),
        _buildMenuOption(context, lang.translate('Manage Cars', 'Wasimamie Magari'), Icons.directions_car_rounded, Colors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const CarsManagementScreen()))),
        _buildMenuOption(context, lang.translate('Manage Drivers', 'Wasimamie Madereva'), Icons.engineering_rounded, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const UsersManagementScreen(initialIndex: 0)))),
        _buildMenuOption(context, lang.translate('Manage Customers', 'Wasimamie Wateja'), Icons.people_alt_rounded, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const UsersManagementScreen(initialIndex: 2)))),
        _buildMenuOption(context, lang.translate('Send Broadcast', 'Tangazo kwa Wote'), Icons.campaign_rounded, Colors.redAccent, () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const SendNotificationScreen()))),
        _buildMenuOption(context, lang.translate('Banners', 'Mabango'), Icons.image_aspect_ratio_rounded, Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const ManageBannersScreen()))),
        _buildMenuOption(context, lang.translate('Reports', 'Ripoti'), Icons.insert_chart_rounded, Colors.pink, () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const ReportsScreen()))),
        _buildMenuOption(context, lang.translate('Bookings', 'Safari'), Icons.book_rounded, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const BookingsManagementScreen()))),
        _buildMenuOption(context, lang.translate('Payments', 'Malipo'), Icons.account_balance_rounded, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const PaymentsManagementScreen()))),
      ],
    );
  }

  Widget _buildMenuOption(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[200]!)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1D275F))),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitiesList(LanguageProvider lang) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').orderBy('bookingDate', descending: true).limit(3).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final docs = snapshot.data!.docs;
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  CircleAvatar(backgroundColor: Colors.blue.withOpacity(0.1), child: const Icon(Icons.history_rounded, color: Colors.blue, size: 18)),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${data['customerName']} booked ${data['carModel']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(DateFormat('dd MMM, HH:mm').format((data['bookingDate'] as Timestamp).toDate()), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                  _buildSmallBadge(data['status'] ?? 'pending'),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSmallBadge(String status) {
    Color color = Colors.orange;
    if (status == 'confirmed') color = Colors.green;
    if (status == 'completed') color = Colors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1D275F)));
  }
}
