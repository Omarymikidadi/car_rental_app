import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/car.dart';
import '../add_car_screen.dart';
import '../car_detail_screen.dart';
import '../../providers/language_provider.dart';
import 'package:provider/provider.dart';

class MyCarsScreen extends StatelessWidget {
  const MyCarsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      appBar: AppBar(
        title: Text(lang.translate('My Cars', 'Magari Yangu'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const AddCarScreen())),
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF003399)),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('cars')
            .where('ownerId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.car_repair_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 20),
                  Text(lang.translate('No cars added yet.', 'Hujapaki gari lolote bado.')),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const AddCarScreen())),
                    child: Text(lang.translate('Add First Car', 'Ongeza Gari la Kwanza')),
                  )
                ],
              ),
            );
          }

          final cars = snapshot.data!.docs.map((doc) => Car.fromFirestore(doc)).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: cars.length,
            itemBuilder: (ctx, i) {
              final car = cars[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(car.imageUrl, width: 80, height: 60, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.directions_car)),
                  ),
                  title: Text('${car.brand} ${car.model}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(car.isAvailable ? lang.translate('Available', 'Lipo') : lang.translate('Booked', 'Limekodishwa')),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => CarDetailScreen(car: car))),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
