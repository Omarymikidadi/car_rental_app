import 'package:cloud_firestore/cloud_firestore.dart';

enum FuelType { petrol, diesel, electric, hybrid }
enum Transmission { manual, automatic }
enum CarCategory { all, suv, sedan, luxury, sports, bus }

class Car {
  final String id;
  final String brand;
  final String model;
  final double pricePerDay;
  final String imageUrl;
  final String description;
  final bool isAvailable;
  final String status; // 'available' au 'unavailable'
  final String? unavailableReason;
  final int seats;
  final Transmission transmission;
  final FuelType fuelType;
  final double rating;
  final CarCategory category;
  final String? ownerId;
  final String? vendorName;
  
  // TAARIFA ZA DEREVA
  final String? driverId; 
  final String driverName;
  final String driverPhone;
  final int driverAge;
  final String driverImage;

  Car({
    required this.id,
    required this.brand,
    required this.model,
    required this.pricePerDay,
    required this.imageUrl,
    required this.description,
    this.isAvailable = true,
    this.status = 'available',
    this.unavailableReason,
    required this.seats,
    required this.transmission,
    required this.fuelType,
    this.rating = 4.5,
    required this.category,
    this.ownerId,
    this.vendorName,
    this.driverId,
    required this.driverName,
    required this.driverPhone,
    required this.driverAge,
    required this.driverImage,
  });

  factory Car.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Car(
      id: doc.id,
      brand: data['brand'] ?? '',
      model: data['model'] ?? '',
      pricePerDay: (data['pricePerDay'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      status: data['status'] ?? 'available',
      unavailableReason: data['unavailableReason'],
      seats: data['seats'] ?? 5,
      transmission: Transmission.values[data['transmission'] ?? 1],
      fuelType: FuelType.values[data['fuelType'] ?? 0],
      rating: (data['rating'] ?? 4.5).toDouble(),
      category: CarCategory.values[data['category'] ?? 0],
      ownerId: data['ownerId'],
      vendorName: data['vendorName'],
      driverId: data['driverId'],
      driverName: data['driverName'] ?? 'John Doe',
      driverPhone: data['driverPhone'] ?? '0700 000 000',
      driverAge: data['driverAge'] ?? 30,
      driverImage: data['driverImage'] ?? 'assets/app_icon.png',
    );
  }
}

final List<Car> dummyCars = [
  Car(
    id: '1',
    brand: 'Toyota',
    model: 'Camry',
    pricePerDay: 75000.0,
    imageUrl: 'assets/car1.png',
    description: 'A comfortable and reliable sedan for your daily needs.',
    seats: 5,
    transmission: Transmission.automatic,
    fuelType: FuelType.petrol,
    rating: 4.8,
    category: CarCategory.sedan,
    vendorName: 'Global Rentals',
    driverName: 'Bakari Juma',
    driverPhone: '0712 345 678',
    driverAge: 32,
    driverImage: 'assets/driver1.png',
  ),
  Car(
    id: '2',
    brand: 'Mercedes-Benz',
    model: 'S-Class',
    pricePerDay: 450000.0,
    imageUrl: 'assets/car2.png',
    description: 'Ultimate luxury and comfort for executive travel.',
    seats: 5,
    transmission: Transmission.automatic,
    fuelType: FuelType.petrol,
    rating: 4.9,
    category: CarCategory.luxury,
    vendorName: 'Elite Car Services',
    driverName: 'John Masanja',
    driverPhone: '0788 123 456',
    driverAge: 38,
    driverImage: 'assets/driver2.png',
  ),
];
