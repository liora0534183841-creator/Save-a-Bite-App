import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessModel {
  final String businessId;   
  final String ownerUid;     
  final String businessName; 
  final String city;        
  final String streetAddress; 
  final String phoneNumber;    
  final String licenseUrl;   
  final String v_status;   // PENDING, APPROVED, REJECTED  
  final double rating;     
  final GeoPoint coordinates;
  final String logoUrl;

  BusinessModel({
    required this.businessId,
    required this.ownerUid,
    required this.businessName,
    required this.city,
    required this.streetAddress,
    required this.phoneNumber,
    required this.licenseUrl,
    required this.v_status,
    required this.rating,
    required this.coordinates,
    required this.logoUrl,
  });

  factory BusinessModel.fromMap(Map<String, dynamic> map) {
    return BusinessModel(
      businessId: map['businessId'] ?? '',
      ownerUid: map['ownerUid'] ?? '',
      businessName: map['businessName'] ?? '',
      city: map['city'] ?? '',
      streetAddress: map['streetAddress'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      licenseUrl: map['licenseUrl'] ?? '',
      v_status: map['v_status'] ?? 'PEND',
      rating: (map['rating'] ?? 0.0).toDouble(),
      coordinates: map['coordinates'] ?? const GeoPoint(0,0),
      logoUrl: map['logoUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'ownerUid': ownerUid,
      'businessName': businessName,
      'city': city,
      'streetAddress': streetAddress,
      'phoneNumber': phoneNumber,
      'licenseUrl': licenseUrl,
      'v_status': v_status,
      'rating': rating,
      'coordinates': coordinates,
      'logoUrl': logoUrl,
    };
  }
}