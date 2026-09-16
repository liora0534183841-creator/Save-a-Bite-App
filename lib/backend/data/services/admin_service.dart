import 'dart:developer' as dev;
import '../repositories/UserRepository.dart';
import '../repositories/BusinessRepository.dart';

class AdminService {
  final UserRepository _userRepo = UserRepository();
  final BusinessRepository _bizRepo = BusinessRepository();
  // Toggles a customer's active status.
  Future<bool> toggleCustomerActivityStatus(String uid, bool isActive) async {
    try {
      dev.log("Admin updating customer activity status for $uid to $isActive", name: "AdminService");
      await _userRepo.updateUserFields(uid, {'isActive': isActive});
      return true;
    } catch (e, stack) {
      dev.log("Error updating customer status", name: "AdminService", error: e, stackTrace: stack);
      throw Exception("Failed to update customer status: $e");
    }
  }
  // Updates a business verification status and adjusts the owner's active status accordingly.
  Future<bool> updateBusinessStatus(String businessId, String ownerUid, String newStatus) async {
    try {
      dev.log("Admin updating business status for $businessId to $newStatus", name: "AdminService");
      
      await _bizRepo.updateBusinessFields(businessId, {'v_status': newStatus});
      
      if (newStatus == 'APPR') {
        await _userRepo.updateUserFields(ownerUid, {'isActive': true});
      } else if (newStatus == 'REJ' || newStatus == 'BLOCKED') {
        await _userRepo.updateUserFields(ownerUid, {'isActive': false});
      }
      
      return true;
    } catch (e, stack) {
      dev.log("Error updating business status", name: "AdminService", error: e, stackTrace: stack);
      throw Exception("Failed to update business status: $e");
    }
  }
}