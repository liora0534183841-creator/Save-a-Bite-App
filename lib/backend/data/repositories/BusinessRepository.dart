import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;
import '../models/business_model.dart';

class BusinessRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _col = 'BUSINESS';
  // Creates or overwrites a business document.
  Future<void> saveBusiness(BusinessModel biz) async {
    try {
      await _db.collection(_col).doc(biz.businessId).set(biz.toMap());
      dev.log("Business saved: ${biz.businessId}", name: "BusinessRepository");
    } catch (e, stack) {
      dev.log("Save business failed", name: "BusinessRepository", error: e, stackTrace: stack);
      rethrow;
    }
  }
  // Retrieves a business by its document ID.
  Future<BusinessModel?> getBusinessById(String businessId) async {
    try {
      var doc = await _db.collection(_col).doc(businessId).get();
      return doc.exists ? BusinessModel.fromMap(doc.data()!) : null;
    } catch (e, stack) {
      dev.log("Fetch business failed", name: "BusinessRepository", error: e, stackTrace: stack);
      rethrow;
    }
  }
  // Retrieves a business linked to a specific user UID. Limits to 1 (1:1 relation).
  Future<BusinessModel?> getBusinessByOwnerUid(String ownerUid) async {
    try {
      var snap = await _db.collection(_col).where('ownerUid', isEqualTo: ownerUid).limit(1).get();
      if (snap.docs.isNotEmpty) {
        return BusinessModel.fromMap(snap.docs.first.data());
      }
      return null;
    } catch (e, stack) {
      dev.log("Fetch business by ownerUid failed", name: "BusinessRepository", error: e, stackTrace: stack);
      rethrow;
    }
  }
  // Updates specific fields in a business document without overwriting it entirely.
  Future<void> updateBusinessFields(String businessId, Map<String, dynamic> data) async {
    try {
      await _db.collection(_col).doc(businessId).update(data);
      dev.log("Business fields updated for $businessId", name: "BusinessRepository");
    } catch (e, stack) {
      dev.log("Update business fields failed", name: "BusinessRepository", error: e, stackTrace: stack);
      rethrow;
    }
  }
  // Deletes a business document.
  Future<void> deleteBusinessDoc(String businessId) async {
    try {
      await _db.collection(_col).doc(businessId).delete();
      dev.log("Business document deleted: $businessId", name: "BusinessRepository");
    } catch (e, stack) {
      dev.log("Delete business doc failed", name: "BusinessRepository", error: e, stackTrace: stack);
      rethrow;
    }
  }
}