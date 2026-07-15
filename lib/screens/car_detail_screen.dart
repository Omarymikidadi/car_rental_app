import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/car.dart';
import 'booking_screen.dart';
import 'package:intl/intl.dart';
import '../providers/language_provider.dart';

class CarDetailScreen extends StatelessWidget {
  final Car car;

  CarDetailScreen({super.key, required this.car});

  final NumberFormat _currencyFormat = NumberFormat.decimalPattern();

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: const Color(0xFF003399),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.white,
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new, color: theme.brightness == Brightness.dark ? Colors.white : Colors.black, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: car.id,
                child: Container(
                  color: theme.brightness == Brightness.dark ? Colors.white10 : Colors.white,
                  child: car.imageUrl.startsWith('http')
                      ? Image.network(car.imageUrl, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.car_rental, size: 100))
                      : Image.asset(car.imageUrl, fit: BoxFit.contain, errorBuilder: (c,e,s) => const Icon(Icons.car_rental, size: 100)),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${car.brand} ${car.model}',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color),
                        ),
                      ),
                      _buildRatingBadge(car.rating),
                    ],
                  ),
                  
                  const SizedBox(height: 25),
                  Text(lang.translate('Vehicle Specifications', 'Sifa za Gari'), 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.brightness == Brightness.dark ? Colors.blueAccent : const Color(0xFF1D275F))),
                  const SizedBox(height: 16),
                  
                  _buildSpecsRow(lang, context),

                  const SizedBox(height: 32),
                  Text(lang.translate('Description', 'Maelezo'), 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.brightness == Brightness.dark ? Colors.blueAccent : const Color(0xFF1D275F))),
                  const SizedBox(height: 12),
                  Text(
                    car.description,
                    style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7), fontSize: 15, height: 1.7),
                  ),

                  const SizedBox(height: 32),
                  _buildSectionTitle(lang.translate('Meet Your Driver', 'Mfahamu Dereva Wako'), context),
                  const SizedBox(height: 16),
                  _buildEnhancedDriverCard(context, lang),
                  
                  const SizedBox(height: 120), 
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomBar(context, lang),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.blueAccent : const Color(0xFF1D275F)));
  }

  Widget _buildEnhancedDriverCard(BuildContext context, LanguageProvider lang) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.blueGrey[50],
            backgroundImage: car.driverImage.startsWith('http') 
                ? NetworkImage(car.driverImage) as ImageProvider 
                : AssetImage(car.driverImage),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(car.driverName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.textTheme.titleMedium?.color)),
                    const SizedBox(width: 5),
                    const Icon(Icons.verified, color: Colors.blue, size: 16),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${lang.translate('Age', 'Umri')}: ${car.driverAge}', style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(car.driverPhone, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _makeCall(car.driverPhone),
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.phone_forwarded_rounded, color: Colors.green, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makeCall(String phone) async {
    final Uri url = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(url)) { await launchUrl(url); }
  }

  Widget _buildBottomBar(BuildContext context, LanguageProvider lang) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
      decoration: BoxDecoration(
        color: theme.cardColor, 
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))]
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
              children: [
                Text(lang.translate('Price', 'Bei'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text('${_currencyFormat.format(car.pricePerDay)} Tsh', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.brightness == Brightness.dark ? Colors.white : const Color(0xFF003399))),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: () => _handleBooking(context, lang),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.brightness == Brightness.dark ? Colors.blueAccent : Colors.black, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                ),
                child: Text(lang.translate('Book Now', 'Kodi Sasa'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBooking(BuildContext context, LanguageProvider lang) async {
    try {
      // FIX: Force server fetch to check live status
      final doc = await FirebaseFirestore.instance.collection('cars').doc(car.id).get(const GetOptions(source: Source.server));
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final String status = data['status'] ?? 'available';
        if (status == 'unavailable') {
          if (context.mounted) { _showAlternativeBottomSheet(context, lang, data['unavailableReason']); }
          return;
        }
      }
      if (context.mounted) { Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => BookingScreen(car: car))); }
    } catch (e) {
      debugPrint("Check failed: $e");
    }
  }

  void _showAlternativeBottomSheet(BuildContext context, LanguageProvider lang, String? reason) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 60),
                  const SizedBox(height: 15),
                  Text(lang.translate('Car Currently Unavailable', 'Gari Halipatikani kwa Sasa'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  Text('${lang.translate('Reason', 'Sababu')}: ${reason ?? "Matengenezo"}', textAlign: TextAlign.center),
                ],
              ),
            ),
            const Divider(),
            Padding(padding: const EdgeInsets.all(20), child: Text(lang.translate('Alternative Suggestions', 'Magari Mengine Mbadala'), style: const TextStyle(fontWeight: FontWeight.bold))),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('cars').where('category', isEqualTo: car.category.index).where('status', isEqualTo: 'available').limit(5).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs.where((doc) => doc.id != car.id).toList();
                  if (docs.isEmpty) return Center(child: Text(lang.translate('No alternatives found', 'Hakuna magari mbadala')));
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: docs.length,
                    itemBuilder: (context, index) => _buildAltCarItem(context, Car.fromFirestore(docs[index]), lang),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAltCarItem(BuildContext context, Car altCar, LanguageProvider lang) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 15), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(altCar.imageUrl, width: 80, height: 60, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.car_rental))),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${altCar.brand} ${altCar.model}', style: const TextStyle(fontWeight: FontWeight.bold)), Text('${_currencyFormat.format(altCar.pricePerDay)} Tsh', style: const TextStyle(color: Colors.blueAccent, fontSize: 12))])),
          ElevatedButton(onPressed: () { Navigator.pop(context); Navigator.pushReplacement(context, MaterialPageRoute(builder: (ctx) => CarDetailScreen(car: altCar))); }, child: Text(lang.translate('View', 'Angalia'))),
        ],
      ),
    );
  }

  Widget _buildRatingBadge(double rating) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Row(children: [const Icon(Icons.star, color: Colors.orange, size: 16), const SizedBox(width: 5), Text(rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold))]));
  }

  Widget _buildSpecsRow(LanguageProvider lang, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSpecItem(Icons.people_alt_outlined, '${car.seats} ${lang.translate('Seats', 'Viti')}', context),
        _buildSpecItem(Icons.settings_input_component_outlined, car.transmission.name.toUpperCase(), context),
        _buildSpecItem(Icons.local_gas_station_outlined, car.fuelType.name.toUpperCase(), context),
      ],
    );
  }

  Widget _buildSpecItem(IconData icon, String value, BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 100, 
      padding: const EdgeInsets.symmetric(vertical: 15), 
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20)), 
      child: Column(children: [Icon(icon, color: const Color(0xFF2E82F2), size: 24), const SizedBox(height: 8), Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: theme.textTheme.titleMedium?.color))])
    );
  }
}
