import 'package:flutter/material.dart';
import 'car.dart';

class Booking {
  final String id;
  final Car car;
  final DateTime bookingDate;
  final DateTime startDate;
  final DateTime endDate;
  final TimeOfDay pickUpTime; // Added pickUpTime
  final String pickUpLocation;
  final String dropOffLocation;
  final double distance; // in kilometers
  final double totalAmount;

  Booking({
    required this.id,
    required this.car,
    required this.bookingDate,
    required this.startDate,
    required this.endDate,
    required this.pickUpTime,
    required this.pickUpLocation,
    required this.dropOffLocation,
    required this.distance,
    required this.totalAmount,
  });
}

List<Booking> userBookings = [];
