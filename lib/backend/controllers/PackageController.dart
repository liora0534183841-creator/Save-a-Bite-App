import 'package:flutter/material.dart';
import 'dart:developer' as dev;
import '../data/models/package_model.dart';
import '../data/services/package_service.dart';

// Manages state and logic for packages, including fetching, searching, and business dashboards.
class PackageController extends ChangeNotifier {
  final PackageService _packageService = PackageService();

  bool _isLoading = false;
  // Returns whether an authentication process is currently running.
  bool get isLoading => _isLoading;

  List<PackageModel> _availablePackages = [];
  // The list of currently available packages in the selected city.
  List<PackageModel> get availablePackages => _availablePackages;

  List<PackageModel> _businessPackages = [];
  // The list of packages associated with the current business.
  List<PackageModel> get businessPackages => _businessPackages;

  PackageModel? _currentPackage;
  // The currently selected package data.
  PackageModel? get currentPackage => _currentPackage;

  String? _errorMessage;
  // Holds the last error message, or null if there is no error.
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

  // Loads all available packages for a given city.
  Future<void> loadAvailablePackages(String customerCity) async {
    _setLoading(true);
    clearError();
    try {
      dev.log("Request to controller: Loading available packages for the city $customerCity", name: "PackageController");
      _availablePackages = await _packageService.getAvailablePackages(customerCity);
    } catch (e, stack) {
      dev.log("Error loading packages", name: "PackageController", error: e, stackTrace: stack);
      _availablePackages = [];
      _errorMessage = e.toString().replaceAll("Exception: ", "");
    } finally {
      _setLoading(false);
    }
  }

   // Searches for available packages in the city by search.
  Future<void> searchPackages(String customerCity, String query) async {
    _setLoading(true);
    clearError();
    try {
      dev.log("Request to controller: Search packages $query", name: "PackageController");
      if (query.isEmpty) {
        _availablePackages = await _packageService.getAvailablePackages(customerCity);
      } else {
        _availablePackages = await _packageService.searchPackagesByKeyword(customerCity, query);
      }
    } catch (e, stack) {
      dev.log("Error searching packages", name: "PackageController", error: e, stackTrace: stack);
      _errorMessage = e.toString().replaceAll("Exception: ", "");
    } finally {
      _setLoading(false);
    }
  }

  // Loads all packages belonging to a specific business for its dashboard.
  Future<void> loadBusinessDashboard(String businessId) async {
    _setLoading(true);
    clearError();
    try {
      dev.log("Request to controller: Loading business dashboard", name: "PackageController");
      _businessPackages = await _packageService.getBusinessDashboardPackages(businessId);
    } catch (e, stack) {
      dev.log("Error loading business dashboard", name: "PackageController", error: e, stackTrace: stack);
      _businessPackages = [];
      _errorMessage = e.toString().replaceAll("Exception: ", "");
    } finally {
      _setLoading(false);
    }
  }

  // Filters a business's packages by a specified date range.
  Future<void> filterBusinessDashboardByDate(
    String businessId,
    DateTime start,
    DateTime end,
  ) async {
    _setLoading(true);
    clearError();
    try {
      dev.log("Request to controller: Filtering business packages", name: "PackageController");
      _businessPackages = await _packageService.filterBusinessPackagesByDate(businessId, start, end);
    } catch (e, stack) {
      dev.log("Error filtering business dashboard", name: "PackageController", error: e, stackTrace: stack);
      _errorMessage = e.toString().replaceAll("Exception: ", "");
    } finally {
      _setLoading(false);
    }
  }

  // Creates a new package for a business and refreshes the dashboard data.
  Future<bool> createPackage({
    required String businessId,
    required String title,
    required double originalPrice,
    required double salePrice,
    required int quantity,
    required DateTime pickupStart,
    required DateTime pickupEnd,
  }) async {
    _setLoading(true);
    clearError();
    try {
      dev.log("Request to controller: Creating new package", name: "PackageController");
      bool success = await _packageService.addNewBusinessPackage(
        businessId: businessId,
        title: title,
        originalPrice: originalPrice,
        salePrice: salePrice,
        quantity: quantity,
        pickupStart: pickupStart,
        pickupEnd: pickupEnd,
      );
      if (success) {
        await loadBusinessDashboard(businessId);
      }
      return success;
    } catch (e, stack) {
      dev.log("Error creating package", name: "PackageController", error: e, stackTrace: stack);
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Updates the status of a specific package and refreshes the dashboard.
  Future<bool> updateStatus(
    String packageId,
    String newStatus,
    String businessId,
  ) async {
    _setLoading(true);
    clearError();
    try {
      dev.log("Request to controller: Update package status $packageId", name: "PackageController");
      bool success = await _packageService.setPackageStatus(packageId, newStatus);
      if (success) {
        await loadBusinessDashboard(businessId); 
      }
      return success;
    } catch (e, stack) {
      dev.log("Error updating package status", name: "PackageController", error: e, stackTrace: stack);
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Loads the details of a single package by its ID.
  Future<void> loadRawPackage(String packageId) async {
    _setLoading(true);
    clearError();
    try {
      dev.log("Request to controller: Loading raw package", name: "PackageController");
      _currentPackage = await _packageService.getRawPackageById(packageId);
    } catch (e, stack) {
      dev.log("Error loading raw package", name: "PackageController", error: e, stackTrace: stack);
      _currentPackage = null;
      _errorMessage = e.toString().replaceAll("Exception: ", "");
    } finally {
      _setLoading(false);
    }
  }
}