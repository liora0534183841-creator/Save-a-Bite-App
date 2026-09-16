import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;
import '../models/order_model.dart';

class OrderRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _col = 'ORDER';
  // Creates a new order document.
  Future<void> saveOrder(OrderModel order) async {
    try {
      await _db.collection(_col).doc(order.orderId).set(order.toMap());
      dev.log("Order saved: ${order.orderId}", name: "OrderRepository");
    } catch (e, stack) {
      dev.log("Save order failed", name: "OrderRepository", error: e, stackTrace: stack);
      rethrow;
    }
  }
  // Fetches all orders placed by a specific customer.
  Future<List<OrderModel>> getOrdersByCustomer(String customerId) async {
    try {
      var snap = await _db.collection(_col).where('customerId', isEqualTo: customerId).get();
      return snap.docs.map((d) => OrderModel.fromMap(d.data())).toList();
    } catch (e, stack) {
      dev.log("Fetch customer orders failed", name: "OrderRepository", error: e, stackTrace: stack);
      rethrow;
    }
  }
  // Updates order fields (changing status to COLLECTED or CANCELLED).
  Future<void> updateOrderFields(String orderId, Map<String, dynamic> data) async {
    try {
      await _db.collection(_col).doc(orderId).update(data);
      dev.log("Order fields updated for $orderId", name: "OrderRepository");
    } catch (e, stack) {
      dev.log("Update order fields failed", name: "OrderRepository", error: e, stackTrace: stack);
      rethrow;
    }
  }
}