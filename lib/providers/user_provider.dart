import 'dart:async';
import 'dart:io' show File;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String _name = 'User';
  String _email = '';
  String _phone = 'Phone Number';
  String? _imagePath;
  String _role = 'customer'; 
  bool _isLoading = true;
  bool _notificationsEnabled = true;
  String _assignedCar = 'No car assigned';
  String? _assignedCarId;
  String _availabilityStatus = 'available'; 
  String _availabilityReason = '';
  int _bookingCount = 0;
  int _confirmedBookingCount = 0;
  int _todayBookingCount = 0;
  double _totalEarnings = 0.0;
  double _todayEarnings = 0.0;
  double _monthlyEarnings = 0.0;
  DateTime? _createdAt;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot>? _userDocSubscription;

  String get name => _name;
  String get email => _email;
  String get phone => _phone;
  String? get imagePath => _imagePath;
  String get role => _role;
  bool get isLoading => _isLoading;
  bool get notificationsEnabled => _notificationsEnabled;
  String get assignedCar => _assignedCar;
  String? get assignedCarId => _assignedCarId;
  String get availabilityStatus => _availabilityStatus;
  String get availabilityReason => _availabilityReason;
  int get bookingCount => _bookingCount;
  int get confirmedBookingCount => _confirmedBookingCount;
  int get todayBookingCount => _todayBookingCount;
  double get totalEarnings => _totalEarnings;
  double get todayEarnings => _todayEarnings;
  double get monthlyEarnings => _monthlyEarnings;
  DateTime? get createdAt => _createdAt;

  UserProvider() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        _email = user.email ?? '';
        _startUserDocListener(user.uid);
        await fetchBookingCount();
      } else {
        _resetUser();
      }
    });
  }

  void _startUserDocListener(String uid) {
    _userDocSubscription?.cancel();
    _userDocSubscription = FirebaseFirestore.instance.collection('users').doc(uid).snapshots().listen((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        _name = data['name'] ?? 'User';
        _phone = data['phone'] ?? 'Phone Number';
        _imagePath = data['profileImage'];
        _role = (data['role'] ?? 'customer').toString().trim().toLowerCase();
        _assignedCar = data['assignedCar'] ?? 'No car assigned';
        _assignedCarId = data['assignedCarId'];
        _availabilityStatus = data['availabilityStatus'] ?? 'available';
        _availabilityReason = data['availabilityReason'] ?? '';
        if (data['createdAt'] != null) {
          _createdAt = (data['createdAt'] as Timestamp).toDate();
        }
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  void _resetUser() {
    _userDocSubscription?.cancel();
    _name = 'User';
    _email = '';
    _phone = 'Phone Number';
    _imagePath = null;
    _role = 'customer';
    _bookingCount = 0;
    _confirmedBookingCount = 0;
    _todayBookingCount = 0;
    _totalEarnings = 0.0;
    _todayEarnings = 0.0;
    _monthlyEarnings = 0.0;
    _createdAt = null;
    _assignedCar = 'No car assigned';
    _assignedCarId = null;
    _availabilityStatus = 'available';
    _availabilityReason = '';
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userDocSubscription?.cancel();
    super.dispose();
  }

  Future<void> fetchFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          _name = data['name'] ?? 'User';
          _phone = data['phone'] ?? 'Phone Number';
          _imagePath = data['profileImage'];
          _role = (data['role'] ?? 'customer').toString().trim().toLowerCase();
          _assignedCar = data['assignedCar'] ?? 'No car assigned';
          _assignedCarId = data['assignedCarId'];
          _availabilityStatus = data['availabilityStatus'] ?? 'available';
          _availabilityReason = data['availabilityReason'] ?? '';
          if (data['createdAt'] != null) {
            _createdAt = (data['createdAt'] as Timestamp).toDate();
          }
          notifyListeners();
        }
      } catch (e) {
        debugPrint("Error fetching profile: $e");
      }
    }
  }

  Future<void> updateAvailability(String status, {String reason = ''}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'availabilityStatus': status,
          'availabilityReason': reason,
        });

        if (_assignedCarId != null) {
          await FirebaseFirestore.instance.collection('cars').doc(_assignedCarId).update({
            'status': status,
            'unavailableReason': reason,
          });
        }
      } catch (e) {
        debugPrint("Error updating availability: $e");
      }
    }
  }

  Future<void> fetchBookingCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        Query query = FirebaseFirestore.instance.collection('bookings');
        if (_role == 'driver') {
          query = query.where('driverId', isEqualTo: user.uid);
        } else if (_role == 'admin') {
          // No filter
        } else {
          query = query.where('userId', isEqualTo: user.uid);
        }
        
        final snapshot = await query.get();
        _bookingCount = snapshot.docs.length;

        double earnings = 0;
        double tEarnings = 0;
        double mEarnings = 0;
        int tCount = 0;
        int cCount = 0;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final firstDayOfMonth = DateTime(now.year, now.month, 1);

        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final amount = (data['totalAmount'] ?? 0).toDouble();
          final status = data['status'];
          
          if (status == 'confirmed') {
            cCount++;
          }

          if (data['bookingDate'] != null) {
            final bDate = (data['bookingDate'] as Timestamp).toDate();
            final bookingDay = DateTime(bDate.year, bDate.month, bDate.day);

            if (status == 'completed') {
              earnings += amount;
              if (bookingDay.isAtSameMomentAs(today)) {
                tEarnings += amount;
              }
              if (bDate.isAfter(firstDayOfMonth) || bDate.isAtSameMomentAs(firstDayOfMonth)) {
                mEarnings += amount;
              }
            }
            
            if (bookingDay.isAtSameMomentAs(today)) {
              tCount++;
            }
          }
        }
        _confirmedBookingCount = cCount;
        _totalEarnings = earnings;
        _todayEarnings = tEarnings;
        _monthlyEarnings = mEarnings;
        _todayBookingCount = tCount;
        
        notifyListeners();
      } catch (e) {
        debugPrint("Error fetching bookings count: $e");
      }
    }
  }

  Future<void> updateName(String newName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'name': newName});
    }
  }

  Future<void> updateEmail(String newEmail) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.updateEmail(newEmail);
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'email': newEmail});
    }
  }

  Future<void> updatePhone(String newPhone) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'phone': newPhone});
    }
  }

  Future<void> updatePassword(String newPassword) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    }
  }

  Future<void> uploadProfileImage(File imageFile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final storageRef = FirebaseStorage.instance.ref().child('user_profiles').child('${user.uid}.jpg');
      await storageRef.putFile(imageFile);
      final imageUrl = await storageRef.getDownloadURL();
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'profileImage': imageUrl});
    } catch (e) {
      debugPrint("Upload error: $e");
    }
  }

  Future<void> uploadProfileImageWeb(dynamic bytes, String fileName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final storageRef = FirebaseStorage.instance.ref().child('user_profiles').child('${user.uid}.jpg');
      await storageRef.putData(bytes);
      final imageUrl = await storageRef.getDownloadURL();
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'profileImage': imageUrl});
    } catch (e) {
      debugPrint("Web Upload error: $e");
    }
  }

  void toggleNotifications(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }
}
