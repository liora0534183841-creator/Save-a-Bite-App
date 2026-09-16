import 'package:flutter/material.dart';
import 'dart:developer' as dev;
import '../data/services/admin_service.dart';

// Controller for admin operations like managing users and business approvals.
mixin AdminController implements ChangeNotifier {
  final AdminService _adminService = AdminService();

  bool _isLoading = false;
  // Returns whether an authentication process is currently running.
  bool get isLoading => _isLoading;

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

  // Enables or disables a customer account by [uid].
  Future<bool> toggleCustomerActivity(String uid, bool isActive) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      dev.log("Controller request: Change customer status $uid to $isActive", name: "AdminController");
      bool success = await _adminService.toggleCustomerActivityStatus(uid, isActive);
      return success;
    } catch (e, stack) {
      dev.log("Error in AdminController: Change customer status", name: "AdminController", error: e, stackTrace: stack);
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Updates the approval status of a business.
  Future<bool> updateBusinessRegistrationStatus(
    String businessId,
    String ownerUid,
    String newStatus,
  ) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      dev.log("Request to the Controller: Change of Business Status $businessId", name: "AdminController");
      bool success = await _adminService.updateBusinessStatus(businessId, ownerUid, newStatus);
      return success;
    } catch (e, stack) {
      dev.log("Error in AdminController: Change business status", name: "AdminController", error: e, stackTrace: stack);
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      return false;
    } finally {
      _setLoading(false);
    }
  }
}