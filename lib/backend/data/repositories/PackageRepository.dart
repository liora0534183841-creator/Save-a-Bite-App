import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;
import '../models/package_model.dart';

class PackageRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _col = 'PACKAGE';
  // Creates a new package document.
  Future<void> savePackage(PackageModel pkg) async {
    try {
      await _db.collection(_col).doc(pkg.packageId).set(pkg.toMap());
      dev.log("Package saved: ${pkg.packageId}", name: "PackageRepository");
    } catch (e, stack) {
      dev.log("Save package failed", name: "PackageRepository", error: e, stackTrace: stack);
      rethrow;
    }
  }
  // Retrieves a specific package by its ID.
  Future<PackageModel?> getPackageById(String packageId) async {
    try {
      var doc = await _db.collection(_col).doc(packageId).get();
      return doc.exists ? PackageModel.fromMap(doc.data()!) : null;
    } catch (e, stack) {
      dev.log("Fetch package failed", name: "PackageRepository", error: e, stackTrace: stack);
      rethrow;
    }
  }
  // Fetches packages filtered by status .
  Future<List<PackageModel>> getPackagesByStatus(String status) async {
    try {
      var snap = await _db.collection(_col).where('status', isEqualTo: status).get();
      return snap.docs.map((d) => PackageModel.fromMap(d.data())).toList();
    } catch (e, stack) {
      dev.log("Fetch packages by status failed", name: "PackageRepository", error: e, stackTrace: stack);
      rethrow;
    }
  }
  // Fetches all packages offered by a specific business.
  Future<List<PackageModel>> getPackagesByBusiness(String businessId) async {
    try {
      var snap = await _db.collection(_col).where('businessId', isEqualTo: businessId).get();
      return snap.docs.map((d) => PackageModel.fromMap(d.data())).toList();
    } catch (e, stack) {
      dev.log("Fetch packages for business failed", name: "PackageRepository", error: e, stackTrace: stack);
      rethrow;
    }
  }
  // Updates specific fields in a package document.
  Future<void> updatePackageFields(String packageId, Map<String, dynamic> data) async {
    try {
      await _db.collection(_col).doc(packageId).update(data);
      dev.log("Package fields updated for $packageId", name: "PackageRepository");
    } catch (e, stack) {
      dev.log("Update package fields failed", name: "PackageRepository", error: e, stackTrace: stack);
      rethrow;
    }
  }
}