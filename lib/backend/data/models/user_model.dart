import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;         
  final String email;       
  final String role;  // ADMIN, PROV, CUST     
  final String fullName;    
  final String phoneNumber; 
  final bool isActive;     
  final String city;
  final String streetAddress;
  final GeoPoint? coordinates;
  

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.fullName,
    required this.phoneNumber,
    required this.isActive,
    required this.city,
    required this.streetAddress,
    required this.coordinates,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'CUST',
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      isActive: map['isActive'] ?? true,
      city: map['city'] ?? '',
      streetAddress: map['streetAddress'] ?? '',
      coordinates: map['coordinates'] as GeoPoint?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'isActive': isActive,
      'city': city,
      'streetAddress': streetAddress,
      'coordinates': coordinates,
    };
  }
}