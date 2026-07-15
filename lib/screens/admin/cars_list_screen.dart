import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/language_provider.dart';

class CarsListScreen extends StatelessWidget {
  const CarsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final NumberFormat currencyFormat = NumberFormat.decimalPattern();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Text(lang.translate('Total Cars', 'Magari Yote'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1D275F))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1D275F)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('cars').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text(lang.translate('No cars found', 'Hakuna magari yaliyopatikana')));
          }

          final cars = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: cars.length,
            itemBuilder: (ctx, index) {
              final carData = cars[index].data() as Map<String, dynamic>;
              final String imageUrl = carData['imageUrl'] ?? '';
              final bool isAvailable = carData['isAvailable'] ?? true;
              final String assignedDriver = carData['driverName'] ?? lang.translate('Not Assigned', 'Hajapangiwa');

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 90, height: 70,
                        decoration: BoxDecoration(color: const Color(0xFFF5F6F9), borderRadius: BorderRadius.circular(15)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: _buildCarImage(imageUrl),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${carData['brand']} ${carData['model']}', 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1D275F))),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.person_outline, size: 12, color: Colors.blueGrey),
                                const SizedBox(width: 4),
                                Text('${lang.translate('Driver', 'Dereva')}: $assignedDriver',
                                    style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isAvailable ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isAvailable ? lang.translate('Available', 'Lipo') : lang.translate('Rented', 'Limekodishwa'),
                                    style: TextStyle(color: isAvailable ? Colors.green : Colors.red, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text('Tsh ${currencyFormat.format(carData['pricePerDay'])}', 
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCarImage(String path) {
    if (path.isEmpty) return const Icon(Icons.directions_car, color: Colors.grey);
    if (path.startsWith('http')) return Image.network(path, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.directions_car));
    return Image.asset(path, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.directions_car));
  }
}
