import 'package:cloud_firestore/cloud_firestore.dart';

class PackageModel {
  final String packageId;     
  final String businessId;    
  final String title;         
  final double originalPrice; 
  final double salePrice;     
  final int quantity;         
  final DateTime pickupStart; 
  final DateTime pickupEnd;   
  final DateTime createdAt;
  final String status;      // AVAILABLE, UNAVAILABLE  

  PackageModel({
    required this.packageId,
    required this.businessId,
    required this.title,
    required this.originalPrice, 
    required this.salePrice,
    required this.quantity,
    required this.pickupStart,
    required this.pickupEnd,
    required this.createdAt,     
    required this.status,
  });

  factory PackageModel.fromMap(Map<String, dynamic> map) {
    return PackageModel(
      packageId: map['packageId'] ?? '',
      businessId: map['businessId'] ?? '',
      title: map['title'] ?? '',
      originalPrice: (map['originalPrice'] ?? 0.0).toDouble(), 
      salePrice: (map['salePrice'] ?? 0.0).toDouble(),
      quantity: (map['quantity'] ?? 0).toInt(),
      pickupStart: map['pickupStart'] != null 
          ? (map['pickupStart'] as Timestamp).toDate() 
          : DateTime.now(),
      pickupEnd: map['pickupEnd'] != null 
          ? (map['pickupEnd'] as Timestamp).toDate() 
          : DateTime.now(),
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),          
      status: map['status'] ?? 'AVAILABLE',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'packageId': packageId,
      'businessId': businessId,
      'title': title,
      'originalPrice': originalPrice, 
      'salePrice': salePrice,
      'quantity': quantity,
      'pickupStart': pickupStart,
      'pickupEnd': pickupEnd,
      'createdAt': createdAt,
      'status': status,
    };
  }
}