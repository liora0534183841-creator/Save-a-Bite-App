
import 'package:flutter/material.dart';
import 'dart:developer' as dev;
import '../data/models/order_model.dart';
import '../data/services/order_service.dart';

// Manages state and logic for handling orders, including creation, history, and filtering.
class OrderController extends ChangeNotifier {
  final OrderService _orderService = OrderService();

  bool _isLoading = false;
  // Returns whether an authentication process is currently running.
  bool get isLoading => _isLoading;

  List<OrderModel> _orderHistory = [];
  // The loaded order history for the current user.
  List<OrderModel> get orderHistory => _orderHistory;

  Map<String, dynamic>? _popupSummary;

  // Summary details of a package used for popup displays.
  Map<String, dynamic>? get popupSummary => _popupSummary;

  String? _errorMessage;
  // Holds the latest error message, or `null` if no error exists.
  String? get errorMessage => _errorMessage;

  // Updates the loading status and notifies about it.
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Clears the current error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Places a new order and refreshes the customer's order history on success.
  Future<bool> placeOrder(
    String customerUid,
    String packageId,
    String businessId,
  ) async {
    _setLoading(true);
    clearError();
    try {
      dev.log("Request to controller: Create order", name: "OrderController");
      bool success = await _orderService.createNewOrder(customerUid, packageId, businessId);
      if (success) {
        await loadCustomerHistory(customerUid);
      }
      return success;
    } catch (e, stack) {
      dev.log("Error creating order", name: "OrderController", error: e, stackTrace: stack);
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Marks a specific order as picked up by the customer.
  Future<bool> markOrderAsPickedUp(String orderId) async {
    _setLoading(true);
    clearError();
    try {
      dev.log("Request to Controller: Order Pick Completed $orderId", name: "OrderController");
      bool success = await _orderService.completeOrderPickup(orderId);
      return success;
    } catch (e, stack) {
      dev.log("Error completing collection", name: "OrderController", error: e, stackTrace: stack);
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Loads the entire order history for a customer.
  Future<void> loadCustomerHistory(String uid) async {
    _setLoading(true);
    clearError();
    try {
      dev.log("Request to Controller: Load Customer History", name: "OrderController");
      _orderHistory = await _orderService.getCustomerOrderHistory(uid);
    } catch (e, stack) {
      dev.log("Error loading customer order history", name: "OrderController", error: e, stackTrace: stack);
      _orderHistory = [];
      _errorMessage = e.toString().replaceAll("Exception: ", "");
    } finally {
      _setLoading(false);
    }
  }

  // Filters a customer's order history within a specific date range.
  Future<void> filterHistoryByDate(
    String uid,
    DateTime start,
    DateTime end,
  ) async {
    _setLoading(true);
    clearError();
    try {
      dev.log("Request to Controller: Filter Orders", name: "OrderController");
      _orderHistory = await _orderService.filterCustomerHistoryByDate(uid, start, end);
    } catch (e, stack) {
      dev.log("Error filtering orders", name: "OrderController", error: e, stackTrace: stack);
      _errorMessage = e.toString().replaceAll("Exception: ", "");
    } finally {
      _setLoading(false);
    }
  }

  // Loads the summary details of a specific package for a popup view.
  Future<void> loadPopupSummary(String packageId) async {
    _setLoading(true);
    clearError();
    try {
      dev.log("Request to Controller: Load Popup", name: "OrderController");
      _popupSummary = await _orderService.getPackageSummaryForPopup(packageId);
    } catch (e, stack) {
      dev.log("Error loading popup", name: "OrderController", error: e, stackTrace: stack);
      _popupSummary = null;
      _errorMessage = e.toString().replaceAll("Exception: ", "");
    } finally {
      _setLoading(false);
    }
  }
}