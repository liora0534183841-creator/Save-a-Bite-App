import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String orderId;      
  final String customerId;   
  final String businessId;   
  final String packageId; // Unique FK - sold only once  
  final String status;  // ON_THE_WAY, COLLECTED, CANCELLED     
  final String otpCode;      
  final DateTime createdAt;  
  final bool hasReview;

  OrderModel({
    required this.orderId,
    required this.customerId,
    required this.businessId,
    required this.packageId,
    required this.status,
    required this.otpCode,
    required this.createdAt,
    this.hasReview = false,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      orderId: map['orderId'] ?? '',
      customerId: map['customerId'] ?? '',
      businessId: map['businessId'] ?? '',
      packageId: map['packageId'] ?? '',
      status: map['status'] ?? 'PENDING',
      otpCode: map['otpCode'] ?? '',
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      hasReview: map['hasReview'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'customerId': customerId,
      'businessId': businessId,
      'packageId': packageId,
      'status': status,
      'otpCode': otpCode,
      'createdAt': createdAt,
      'hasReview': hasReview,
    };
  }
}