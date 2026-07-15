import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/language_provider.dart';
import '../add_car_screen.dart';
import '../../models/car.dart';

class CarsManagementScreen extends StatefulWidget {
  const CarsManagementScreen({super.key});

  @override
  State<CarsManagementScreen> createState() => _CarsManagementScreenState();
}

class _CarsManagementScreenState extends State<CarsManagementScreen> {
  final NumberFormat _currencyFormat = NumberFormat.decimalPattern();

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Text(lang.translate('Car Management', 'Usimamizi wa Magari'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1D275F))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Color(0xFF1D275F)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const AddCarScreen())),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('cars').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text(lang.translate('No cars registered yet', 'Hakuna magari yaliyopatikana')),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const AddCarScreen())),
                    child: Text(lang.translate('Add First Car', 'Sajili Gari la Kwanza')),
                  )
                ],
              ),
            );
          }

          final cars = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: cars.length,
            itemBuilder: (ctx, index) {
              final carData = cars[index].data() as Map<String, dynamic>;
              final String carId = cars[index].id;
              final String imageUrl = carData['imageUrl'] ?? '';
              final bool isAvailable = carData['isAvailable'] ?? true;
              final String assignedDriver = carData['driverName'] ?? lang.translate('Not Assigned', 'Hajapangiwa');

              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey.withOpacity(0.1)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 90,
                        height: 70,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F6F9),
                          borderRadius: BorderRadius.circular(15),
                        ),
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
                            Text(
                              '${carData['brand']} ${carData['model']}', 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1D275F))
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.person_outline, size: 12, color: Colors.blueGrey),
                                const SizedBox(width: 4),
                                Text(
                                  '${lang.translate('Driver', 'Dereva')}: $assignedDriver',
                                  style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.w500),
                                ),
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
                                const SizedBox(width: 8),
                                Text(
                                  'Tsh ${_currencyFormat.format(carData['pricePerDay'])}', 
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        onSelected: (val) {
                          if (val == 'edit') {
                            Navigator.push(context, MaterialPageRoute(builder: (ctx) => AddCarScreen(car: Car.fromFirestore(cars[index]))));
                          } else if (val == 'delete') {
                            _confirmDelete(context, carId, lang);
                          }
                        },
                        itemBuilder: (ctx) => [
                          PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit, size: 18), const SizedBox(width: 8), Text(lang.translate('Edit', 'Hariri'))])),
                          PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete, color: Colors.red, size: 18), const SizedBox(width: 8), Text(lang.translate('Delete', 'Futa'), style: const TextStyle(color: Colors.red))])),
                        ],
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
    if (path.isEmpty) return const Icon(Icons.directions_car, color: Colors.grey, size: 30);
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.directions_car, size: 30));
    }
    return Image.asset(path, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.directions_car, size: 30));
  }

  void _confirmDelete(BuildContext context, String carId, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(lang.translate('Delete Car?', 'Futa Gari?')),
        content: Text(lang.translate('Are you sure you want to delete this vehicle?', 'Je, una uhakika unataka kufuta gari hili?')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(lang.translate('Cancel', 'Ghairi'))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('cars').doc(carId).delete();
            },
            child: Text(lang.translate('Delete', 'Futa'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
