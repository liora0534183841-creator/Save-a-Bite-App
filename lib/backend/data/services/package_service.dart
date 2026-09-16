import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;

import '../models/package_model.dart';
import '../repositories/PackageRepository.dart';

class PackageService {
  final PackageRepository _packageRepo = PackageRepository();
  // Fetches currently available packages relevant to the customer's city.
  Future<List<PackageModel>> getAvailablePackages(String customerCity) async {
    try {
      dev.log("Fetching available packages for city: $customerCity", name: "PackageService");
      List<PackageModel> availablePackages = await _packageRepo.getPackagesByStatus('AVAILABLE');
      
      DateTime now = DateTime.now();
      return availablePackages.where((pkg) => pkg.pickupEnd.isAfter(now)).toList();
    } on FirebaseException catch (e) {
      dev.log("Firebase error fetching packages: ${e.message}", name: "PackageService");
      throw Exception("Server error fetching packages: ${e.message}");
    } catch (e, stack) {
      dev.log("General error fetching home packages", name: "PackageService", error: e, stackTrace: stack);
      throw Exception("Unexpected error fetching packages: $e");
    }
  }
  // Publishes a new food rescue package for a specific business.
  Future<bool> addNewBusinessPackage({
    required String businessId, required String title, required double originalPrice,
    required double salePrice, required int quantity, required DateTime pickupStart, required DateTime pickupEnd,
  }) async {
    try {
      dev.log("Adding new package for business: $businessId", name: "PackageService");
      String newPackageId = FirebaseFirestore.instance.collection('PACKAGE').doc().id;
      
      PackageModel newPkg = PackageModel(
        packageId: newPackageId, businessId: businessId, title: title, originalPrice: originalPrice,
        salePrice: salePrice, quantity: quantity, pickupStart: pickupStart, pickupEnd: pickupEnd,
        createdAt: DateTime.now(), status: 'AVAILABLE',
      );

      await _packageRepo.savePackage(newPkg);
      return true;
    } on FirebaseException catch (e) {
      dev.log("Firebase error creating package: ${e.message}", name: "PackageService");
      throw Exception("Server error creating package: ${e.message}");
    } catch (e, stack) {
      dev.log("General error creating package", name: "PackageService", error: e, stackTrace: stack);
      throw Exception("Unexpected error adding package: $e");
    }
  }
  // Updates a package's availability status and adjusts inventory if cancelled.
  Future<bool> setPackageStatus(String packageId, String newStatus) async {
    try {
      dev.log("Updating package $packageId status to $newStatus", name: "PackageService");
      Map<String, dynamic> updateData = {'status': newStatus};
      
      if (newStatus == 'UNAVAILABLE' || newStatus == 'CANCELLED') {
        updateData['quantity'] = 0;
      }

      await _packageRepo.updatePackageFields(packageId, updateData);
      return true;
    } on FirebaseException catch (e) {
      dev.log("Firebase error updating status: ${e.message}", name: "PackageService");
      throw Exception("Server error updating package status: ${e.message}");
    } catch (e, stack) {
      dev.log("General error updating package status", name: "PackageService", error: e, stackTrace: stack);
      throw Exception("Failed to update package: $e");
    }
  }
  // Retrieves a specific package without filtering by time or status.
  Future<PackageModel?> getRawPackageById(String packageId) async {
    try {
      dev.log("Fetching raw package: $packageId", name: "PackageService");
      return await _packageRepo.getPackageById(packageId);
    } on FirebaseException catch (e) {
      dev.log("Firebase error fetching package: ${e.message}", name: "PackageService");
      throw Exception("Server error fetching package: ${e.message}");
    } catch (e) {
      dev.log("General error fetching raw package", name: "PackageService", error: e);
      throw Exception("Failed to fetch package details: $e");
    }
  }
  // Retrieves all packages associated with a specific business for management views.
  Future<List<PackageModel>> getBusinessDashboardPackages(String businessId) async {
    try {
      dev.log("Fetching management packages for business: $businessId", name: "PackageService");
      return await _packageRepo.getPackagesByBusiness(businessId);
    } on FirebaseException catch (e) {
      dev.log("Firebase error fetching business packages: ${e.message}", name: "PackageService");
      throw Exception("Server error fetching dashboard data: ${e.message}");
    } catch (e, stack) {
      dev.log("General error fetching business packages", name: "PackageService", error: e, stackTrace: stack);
      throw Exception("Failed to fetch business packages: $e");
    }
  }
  // Filters available city packages by a keyword search string.
  Future<List<PackageModel>> searchPackagesByKeyword(String customerCity, String searchQuery) async {
    try {
      dev.log("Searching '$searchQuery' in city $customerCity", name: "PackageService");
      List<PackageModel> cityPackages = await getAvailablePackages(customerCity);
      
      return cityPackages.where((pkg) => pkg.title.toLowerCase().contains(searchQuery.toLowerCase())).toList();
    } catch (e, stack) {
      dev.log("Error searching packages", name: "PackageService", error: e, stackTrace: stack);
      throw Exception("Error during search operation: $e");
    }
  }
  // Filters a business's packages based on their creation date.
  Future<List<PackageModel>> filterBusinessPackagesByDate(String businessId, DateTime startDate, DateTime endDate) async {
    try {
      dev.log("Filtering packages by date for business: $businessId", name: "PackageService");
      List<PackageModel> allBusinessPkgs = await _packageRepo.getPackagesByBusiness(businessId);
      
      return allBusinessPkgs.where((pkg) => pkg.createdAt.isAfter(startDate) && pkg.createdAt.isBefore(endDate)).toList();
    } on FirebaseException catch (e) {
      dev.log("Firebase error filtering dates: ${e.message}", name: "PackageService");
      throw Exception("Server error filtering packages: ${e.message}");
    } catch (e, stack) {
      dev.log("General error filtering business packages", name: "PackageService", error: e, stackTrace: stack);
      throw Exception("Failed to filter packages: $e");
    }
  }
}