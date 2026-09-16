import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'dart:developer' as dev;

import '../models/order_model.dart';
import '../models/package_model.dart';
import '../repositories/OrderRepository.dart';
import '../repositories/PackageRepository.dart';

class OrderService {
  final OrderRepository _orderRepo = OrderRepository();
  final PackageRepository _packageRepo = PackageRepository();
  // Processes a new order, generates an OTP, and updates package availability.
  Future<bool> createNewOrder(String customerUid, String packageId, String businessId) async {
    try {
      dev.log("Starting order creation for customer $customerUid", name: "OrderService");      
      String generatedOtp = (Random().nextInt(9000) + 1000).toString();
      String newOrderId = FirebaseFirestore.instance.collection('ORDER').doc().id;

      OrderModel newOrder = OrderModel(
        orderId: newOrderId, customerId: customerUid, businessId: businessId,
        packageId: packageId, status: 'PENDING', otpCode: generatedOtp, createdAt: DateTime.now(),
      );

      await _orderRepo.saveOrder(newOrder);
      await _packageRepo.updatePackageFields(packageId, {'status': 'UNAVAILABLE', 'quantity': 0});

      dev.log("Order $newOrderId created successfully with OTP: $generatedOtp", name: "OrderService");     
      return true;
    } catch (e, stack) {
      dev.log("Error creating order", name: "OrderService", error: e, stackTrace: stack);
      throw Exception("Failed to process order: $e");
    }
  }

  Future<bool> completeOrderPickup(String orderId) async {
    try {
      dev.log("Marking order $orderId as collected", name: "OrderService");
      await _orderRepo.updateOrderFields(orderId, {'status': 'COMPLETED'});
      return true;
    } catch (e, stack) {
      dev.log("Error updating pickup status", name: "OrderService", error: e, stackTrace: stack);
      throw Exception("Failed to update pickup status: $e");
    }
  }

  Future<List<OrderModel>> getCustomerOrderHistory(String uid) async {
    try {
      dev.log("Fetching order history for customer: $uid", name: "OrderService");
      return await _orderRepo.getOrdersByCustomer(uid);
    } catch (e, stack) {
      dev.log("Error fetching history", name: "OrderService", error: e, stackTrace: stack);
      throw Exception("Failed to fetch order history: $e");
    }
  }
  // Extracts essential package details formatted for UI summary popups.
  Future<Map<String, dynamic>?> getPackageSummaryForPopup(String packageId) async {
    try {
      dev.log("Preparing popup summary for package: $packageId", name: "OrderService");
      PackageModel? pkg = await _packageRepo.getPackageById(packageId);
      if (pkg == null) return null;
      
      return {
        'title': pkg.title,
        'price': pkg.salePrice,
        'pickupHours': "${pkg.pickupStart} - ${pkg.pickupEnd}",
        'businessId': pkg.businessId
      };
    } catch (e, stack) {
      dev.log("Error preparing popup", name: "OrderService", error: e, stackTrace: stack);
      throw Exception("Failed to fetch package details: $e");
    }
  }
  // Filters a customer's order history within a specific date range.
  Future<List<OrderModel>> filterCustomerHistoryByDate(String uid, DateTime startDate, DateTime endDate) async {
    try {
      dev.log("Filtering history for customer $uid by date", name: "OrderService");
      List<OrderModel> history = await _orderRepo.getOrdersByCustomer(uid);
      
      return history.where((order) {
        return order.createdAt.isAfter(startDate) && order.createdAt.isBefore(endDate);
      }).toList();
    } catch (e, stack) {
      dev.log("Error filtering history", name: "OrderService", error: e, stackTrace: stack);
      throw Exception("Failed to filter orders: $e");
    }
  }
}