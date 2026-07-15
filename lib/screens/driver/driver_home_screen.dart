import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../my_bookings_screen.dart';
import '../notifications_screen.dart';
import 'package:geolocator/geolocator.dart';

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

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
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    final currencyFormat = NumberFormat.decimalPattern();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Column(
        children: [
          // 1. FIXED HEADER
          _buildFixedHeader(context, userProvider, lang),
          
          // 2. SCROLLABLE CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildMyVehicleCard(userProvider, lang, currencyFormat),
                  const SizedBox(height: 25),
                  _buildQuickActions(context, lang, userProvider),
                  const SizedBox(height: 30),
                  _buildSectionHeader(lang.translate('Today\'s Scheduling', 'Ratiba ya Leo'), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen()))),
                  const SizedBox(height: 15),
                  _buildNextBookingCard(uid, lang, currencyFormat),
                  const SizedBox(height: 30),
                  _buildSectionHeader(lang.translate('Quick Overview', 'Maelezo ya Haraka'), null),
                  const SizedBox(height: 15),
                  _buildQuickOverview(userProvider, lang),
                  const SizedBox(height: 30),
                  _buildKeepCarAvailableCard(lang),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedHeader(BuildContext context, UserProvider user, LanguageProvider lang) {
    String memberSince = user.createdAt != null 
        ? DateFormat('MMM yyyy').format(user.createdAt!) 
        : 'Jan 2024';
    final topPadding = MediaQuery.of(context).padding.top;
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding + 20, 20, 25),
      decoration: const BoxDecoration(
        color: Color(0xFF001F54),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(35), bottomRight: Radius.circular(35)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
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
                      Text(
                        _getGreeting(lang),
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.verified, color: Colors.blue, size: 14),
                      ),
                    ],
                  ),
                ],
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where('target', whereIn: [uid, 'all_drivers'])
                    .snapshots(),
                builder: (context, snapshot) {
                  int unreadCount = 0;
                  if (snapshot.hasData) {
                    unreadCount = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      if (data['target'] == 'all_drivers') {
                        return !(data['readBy'] as List? ?? []).contains(uid);
                      } else {
                        return !(data['isRead'] ?? false);
                      }
                    }).length;
                  }
                  
                  return Stack(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                        icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8, top: 8,
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
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeaderStat(lang.translate('Rating', 'Ukadiriaji'), '4.8', Icons.star, Colors.orange),
              // REAL-TIME CONFIRMED TRIPS COUNT
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('driverId', isEqualTo: uid)
                    .where('status', isEqualTo: 'confirmed')
                    .snapshots(),
                builder: (context, snapshot) {
                  String count = snapshot.hasData ? snapshot.data!.docs.length.toString() : '0';
                  return _buildHeaderStat(lang.translate('Trips', 'Safari'), count, Icons.directions_car, Colors.pinkAccent);
                },
              ),
              _buildHeaderStat(lang.translate('Since', 'Tangu'), memberSince, Icons.calendar_today, Colors.blueAccent),
              _buildOnlineStatusBadge(user.availabilityStatus, lang),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }

  Widget _buildOnlineStatusBadge(String status, LanguageProvider lang) {
    bool isOnline = status == 'available';
    bool isPending = status == 'pending';
    
    Color baseColor = isOnline ? Colors.green : (isPending ? Colors.orange : Colors.red);
    String label = isOnline ? 'Online' : (isPending ? 'Pending' : 'Offline');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: baseColor, width: 1),
      ),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: baseColor, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: baseColor, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildMyVehicleCard(UserProvider user, LanguageProvider lang, NumberFormat format) {
    bool isAvailable = user.availabilityStatus == 'available';
    double percentage = isAvailable ? 0.88 : 0.42;

    if (user.assignedCarId == null) {
      return Container(
        width: double.infinity, padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
        child: Text(lang.translate('No car assigned yet', 'Bado hujapangiwa gari na Admin')),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('cars').doc(user.assignedCarId).snapshots(),
      builder: (context, snapshot) {
        String carName = user.assignedCar;
        String plateNumber = '---';
        String carImage = '';

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          carName = "${data['brand']} ${data['model']}";
          plateNumber = data['plateNumber'] ?? '---';
          carImage = data['imageUrl'] ?? '';
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(
            children: [
              if (carImage.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Image.network(carImage, height: 180, width: double.infinity, fit: BoxFit.cover, 
                    errorBuilder: (c, e, s) => Container(height: 180, color: const Color(0xFFF0F2F8), child: const Icon(Icons.directions_car, size: 60, color: Color(0xFF001F54)))),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lang.translate('My Vehicle', 'Gari Langu'), style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                            Text(carName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF001F54))),
                            Text(plateNumber, style: const TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        _buildAvailabilityIndicator(percentage, user.availabilityStatus),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1, color: Color(0xFFF0F0F0)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _buildVehicleSubStat(lang.translate('Status', 'Hali'), isAvailable ? lang.translate('Available', 'Lipo Tayari') : (user.availabilityStatus == 'pending' ? lang.translate('Pending', 'Inasubiri') : lang.translate('Unavailable', 'Haipatikani')), isAvailable ? Colors.green : (user.availabilityStatus == 'pending' ? Colors.orange : Colors.red))),
                        Expanded(child: _buildVehicleSubStat(lang.translate('This Month', 'Mwezi Huu'), 'TZS ${format.format(user.monthlyEarnings)}', Colors.black)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildAvailabilityIndicator(double percentage, String status) {
    Color color = status == 'available' ? Colors.green : (status == 'pending' ? Colors.orange : Colors.red);
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 55, height: 55,
          child: CircularProgressIndicator(
            value: percentage, 
            strokeWidth: 6, 
            backgroundColor: const Color(0xFFF0F2F8), 
            color: color
          ),
        ),
        Text('${(percentage * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _buildVehicleSubStat(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        const SizedBox(height: 5),
        FittedBox(child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: valueColor))),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, LanguageProvider lang, UserProvider user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionItem(Icons.assignment_outlined, lang.translate('My Bookings', 'Safari Zangu'), Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen()))),
        _buildActionItem(Icons.calendar_month_outlined, lang.translate('Availability', 'Upatikanaji'), Colors.green, () => _showAvailabilityDialog(context, lang, user)),
        _buildActionItem(Icons.location_on_outlined, lang.translate('Update Location', 'Sasisha Mahali'), Colors.purple, () => _updateLocation(context, user, lang)),
        _buildActionItem(Icons.build_outlined, lang.translate('Vehicle Status', 'Hali ya Gari'), Colors.blueAccent, () => _showVehicleStatusDialog(context, lang, user)),
      ],
    );
  }

  Widget _buildActionItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            FittedBox(child: Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blueGrey), textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }

  void _showAvailabilityDialog(BuildContext context, LanguageProvider lang, UserProvider user) {
    String status = user.availabilityStatus;
    bool isAvailable = status == 'available';
    bool isPending = status == 'pending';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15)]
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 25),
            Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                color: (isAvailable ? Colors.green : (isPending ? Colors.orange : Colors.red)).withOpacity(0.1),
                shape: BoxShape.circle
              ),
              child: Icon(
                isAvailable ? Icons.check_circle_outline : (isPending ? Icons.hourglass_empty : Icons.error_outline),
                color: isAvailable ? Colors.green : (isPending ? Colors.orange : Colors.red),
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isAvailable 
                ? lang.translate('Vehicle is Available', 'Gari Lipo Tayari')
                : (isPending ? lang.translate('Pending Approval', 'Inasubiri Idhini') : lang.translate('Vehicle is Unavailable', 'Gari Halipatikani')),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF001F54)),
            ),
            const SizedBox(height: 10),
            Text(
              isAvailable 
                ? lang.translate('Your car is currently visible to customers.', 'Gari lako linaonekana kwa wateja kwa sasa.')
                : (isPending 
                    ? lang.translate('Your request is being reviewed by the admin.', 'Ombi lako linakaguliwa na admin.')
                    : lang.translate('Your car is currently hidden from search results.', 'Gari lako limefichwa kwenye matokeo ya utafutaji.')),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
            ),
            const SizedBox(height: 30),
            Text(
              lang.translate('Change status via "Vehicle Status" button', 'Badilisha hali kupitia button ya "Hali ya Gari"'),
              style: const TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  side: BorderSide(color: Colors.grey[300]!)
                ),
                child: Text(
                  lang.translate('Close', 'Funga'),
                  style: const TextStyle(color: Color(0xFF001F54), fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnavailabilityRequestCard(BuildContext context, LanguageProvider lang, UserProvider user, {String? customTitle, String? customReasonPrefix}) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 25),
              Icon(Icons.report_problem_outlined, color: Colors.orange[700], size: 50),
              const SizedBox(height: 15),
              Text(
                customTitle ?? lang.translate('Set as Unavailable', 'Weka kama Haipatikani'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001F54)),
              ),
              const SizedBox(height: 10),
              Text(
                lang.translate('Explain the reason for this change', 'Elezea sababu ya mabadiliko haya'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: ctrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: lang.translate('Reason...', 'Sababu...'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey[200]!)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey[200]!)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    if (ctrl.text.isEmpty) return;
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid == null) return;

                    try {
                      // 1. Send request directly to Admin
                      await FirebaseFirestore.instance.collection('availability_requests').add({
                        'driverId': uid,
                        'driverName': user.name,
                        'carId': user.assignedCarId,
                        'requestedStatus': 'unavailable',
                        'reason': customReasonPrefix != null ? '$customReasonPrefix: ${ctrl.text}' : ctrl.text,
                        'timestamp': FieldValue.serverTimestamp(),
                        'status': 'pending'
                      });

                      // 2. Add to Admin Notifications
                      await FirebaseFirestore.instance.collection('notifications').add({
                        'userId': 'admin', // assuming 'admin' is the target or handled by cloud functions
                        'title': 'New Availability Request',
                        'message': '${user.name} requested to set vehicle as unavailable: ${ctrl.text}',
                        'type': 'availability_request',
                        'timestamp': FieldValue.serverTimestamp(),
                        'read': false,
                        'driverId': uid,
                      });

                      // 3. Update status to 'pending' immediately
                      await user.updateAvailability('pending', reason: ctrl.text);

                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(lang.translate('Request submitted for Admin approval. Status is pending.', 'Ombi limetumwa. Hali ni pending hadi Admin athibitishe.')))
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF001F54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Text(
                    lang.translate('Submit Request', 'Tuma Ombi'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  void _showVehicleStatusDialog(BuildContext context, LanguageProvider lang, UserProvider user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(lang.translate('Vehicle Status', 'Hali ya Gari')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.build, color: Colors.orange),
              title: Text(lang.translate('Under Maintenance', 'Kwenye Matengenezo')),
              onTap: () {
                Navigator.pop(ctx);
                _showUnavailabilityRequestCard(
                  context, 
                  lang, 
                  user, 
                  customTitle: lang.translate('Vehicle Maintenance', 'Matengenezo ya Gari'),
                  customReasonPrefix: 'Maintenance'
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text(lang.translate('In Good Condition', 'Lipo Salama')),
              onTap: () {
                user.updateAvailability('available');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateLocation(BuildContext context, UserProvider user, LanguageProvider lang) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(lang.translate('Location services are disabled.', 'Huduma ya mahali imezimwa.'))));
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(lang.translate('Location permissions are denied', 'Ruhusa ya mahali imekataliwa'))));
        return;
      }
    }
    Position position = await Geolocator.getCurrentPosition();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({'lastLocation': GeoPoint(position.latitude, position.longitude), 'lastLocationUpdate': Timestamp.now()});
      if (user.assignedCarId != null) {
        await FirebaseFirestore.instance.collection('cars').doc(user.assignedCarId).update({'currentLocation': GeoPoint(position.latitude, position.longitude)});
      }
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(lang.translate('Location updated successfully', 'Mahali pamesasishwa kikamilifu'))));
    }
  }

  Widget _buildSectionHeader(String title, VoidCallback? onViewAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001F54))),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: const Text('View All', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
      ],
    );
  }

  Widget _buildNextBookingCard(String? uid, LanguageProvider lang, NumberFormat format) {
    if (uid == null) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('driverId', isEqualTo: uid)
          .where('status', whereIn: ['confirmed', 'started'])
          .orderBy('bookingDate', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(width: double.infinity, padding: const EdgeInsets.all(30), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)), child: Text(lang.translate('No active trips assigned', 'Hakuna safari uliyopangiwa kwa sasa')));
        }
        final doc = snapshot.data!.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        _autoUpdateInHome(doc.id, data);
        final status = data['status'] ?? 'pending';
        final price = (data['totalAmount'] ?? 0).toDouble();
        final pickup = data['pickupLocation'] ?? 'N/A';
        final dropoff = data['dropoffLocation'] ?? 'N/A';
        final DateTime startTime = (data['startDate'] as Timestamp).toDate();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        Text(DateFormat('HH:mm').format(startTime), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.green)),
                        Text(DateFormat('a').format(startTime).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['customerName'] ?? 'Customer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF001F54))),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                            const SizedBox(width: 5),
                            Expanded(child: Text('$pickup → $dropoff', style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildStatusBadgeSmall(status, lang),
                      const SizedBox(height: 10),
                      Text('TZS ${format.format(price)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF001F54))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(lang.translate('Recent trip details', 'Maelezo ya safari ya hivi karibuni'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Row(
                    children: [
                      _buildActionButton(Icons.map_outlined, Colors.blue, () => _openGoogleMapsRoute(pickup, dropoff)),
                      const SizedBox(width: 10),
                      _buildActionButton(Icons.phone_outlined, Colors.green, () => _makeCall(data['customerPhone'])),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _autoUpdateInHome(String id, Map<String, dynamic> data) {
    final status = data['status'] ?? 'pending';
    if (status == 'completed' || status == 'cancelled') return;
    final Timestamp? startTs = data['startDate'] as Timestamp?;
    final Timestamp? endTs = data['endDate'] as Timestamp?;
    if (startTs == null || endTs == null) return;
    final DateTime now = DateTime.now();
    final DateTime tripStartDay = DateTime(startTs.toDate().year, startTs.toDate().month, startTs.toDate().day);
    final DateTime today = DateTime(now.year, now.month, now.day);
    if (status == 'confirmed' && (today.isAtSameMomentAs(tripStartDay) || today.isAfter(tripStartDay))) {
      FirebaseFirestore.instance.collection('bookings').doc(id).update({'status': 'started'});
    }
    final DateTime completionTime = DateTime(endTs.toDate().year, endTs.toDate().month, endTs.toDate().day, 23, 59, 59);
    if (status == 'started' && now.isAfter(completionTime)) {
      FirebaseFirestore.instance.collection('bookings').doc(id).update({'status': 'completed'});
    }
  }

  Widget _buildStatusBadgeSmall(String status, LanguageProvider lang) {
    Color color = Colors.orange;
    if (status == 'confirmed') color = Colors.green;
    if (status == 'started') color = Colors.blue;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)));
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)));
  }

  Future<void> _makeCall(String? phone) async { if (phone == null || phone.isEmpty) return; final Uri url = Uri(scheme: 'tel', path: phone); if (await canLaunchUrl(url)) await launchUrl(url); }

  Future<void> _openGoogleMapsRoute(String pickup, String dropoff) async {
    final String url = "https://www.google.com/maps/dir/?api=1&origin=${Uri.encodeComponent(pickup)}&destination=${Uri.encodeComponent(dropoff)}";
    if (await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Widget _buildQuickOverview(UserProvider user, LanguageProvider lang) {
    bool isAvailable = user.availabilityStatus == 'available';
    String availability = isAvailable ? '88%' : '45%';
    return Row(
      children: [
        Expanded(child: _buildOverviewItem('${user.confirmedBookingCount}', lang.translate('Confirmed Trips', 'Safari Zilizothibitishwa'), Icons.check_circle_outline, Colors.green)),
        const SizedBox(width: 15),
        Expanded(child: _buildOverviewItem('4.8', lang.translate('Your Rating', 'Ukadiriaji'), Icons.star_border, Colors.orange)),
        const SizedBox(width: 15),
        Expanded(child: _buildOverviewItem(availability, lang.translate('Availability', 'Upatikanaji'), Icons.pie_chart_outline, Colors.purple)),
      ],
    );
  }

  Widget _buildOverviewItem(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(height: 15),
          FittedBox(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF001F54)))),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9), maxLines: 2),
        ],
      ),
    );
  }

  Widget _buildKeepCarAvailableCard(LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFE8F0FE), borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lang.translate('Keep Your Car Available', 'Weka Gari Lako Tayari'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF001F54))),
                const SizedBox(height: 8),
                Text(lang.translate('More availability means more bookings', 'Upatikanaji zaidi unamaanisha safari nyingi zaidi'), style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF001F54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: Text(lang.translate('Update Availability', 'Sasisha Upatikanaji'), style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
          ),
          const Icon(Icons.directions_car, size: 80, color: Colors.blue),
        ],
      ),
    );
  }
}
