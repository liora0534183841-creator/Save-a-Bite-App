import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as dev;

import '../models/user_model.dart';
import '../models/business_model.dart';
import '../repositories/UserRepository.dart';
import '../repositories/BusinessRepository.dart';
import '../repositories/AuthRepository.dart';
import '../repositories/StorageRepository.dart';

// Handles business logic for managing user and business profiles, passwords, and account deletion.
class ProfileService {
  final UserRepository _userRepo = UserRepository();
  final BusinessRepository _bizRepo = BusinessRepository();
  final AuthRepository _authRepo = AuthRepository();
  final StorageRepository _storageRepo = StorageRepository();

  // Fetches user profile data by UID.
  Future<UserModel?> getBasicUserData(String uid) async {
    try {
      dev.log("Extracts user data for: $uid", name: "ProfileService");
      return await _userRepo.getUserById(uid);
    } on FirebaseException catch (e) {
      dev.log("Firebase error retrieving user data: ${e.message}", name: "ProfileService");
      throw Exception("Server error retrieving user information: ${e.message}");
    } catch (e, stack) {
      dev.log("Error retrieving user data", name: "ProfileService", error: e, stackTrace: stack);
      throw Exception("Error loading user profile: $e");
    }
  }

  // Fetches business provider details using the owner's UID.
  Future<BusinessModel?> getBusinessProviderData(String ownerUid) async {
    try {
      dev.log("Extracts business data by owner ID: $ownerUid", name: "ProfileService");
      return await _bizRepo.getBusinessByOwnerUid(ownerUid);
    } on FirebaseException catch (e) {
      dev.log("Firebase error retrieving business data: ${e.message}", name: "ProfileService");
      throw Exception("Server error retrieving business information: ${e.message}");
    } catch (e, stack) {
      dev.log("Error retrieving business data", name: "ProfileService", error: e, stackTrace: stack);
      throw Exception("Error loading business profile: $e");
    }
  }

  // Updates profile details for a customer.
  Future<bool> updateCustomerProfile(String uid, String fullName, String phoneNumber, String city, String streetAddress) async {
    try {
      dev.log("Updating a customer profile: $uid", name: "ProfileService");
      Map<String, dynamic> updateData = {
        'fullName': fullName, 'phoneNumber': phoneNumber, 'city': city, 'streetAddress': streetAddress,
      };
      await _userRepo.updateUserFields(uid, updateData);
      return true;
    } on FirebaseException catch (e) {
      dev.log("Firebase error updating customer profile: ${e.message}", name: "ProfileService");
      throw Exception("Server error updating customer profile: ${e.message}");
    } catch (e, stack) {
      dev.log("Error updating customer profile", name: "ProfileService", error: e, stackTrace: stack);
      throw Exception("Error updating customer profile: $e");
    }
  }

  // Re-authenticates the current user and changes their password.
  Future<bool> changeUserPassword(String currentPassword, String newPassword) async {
    try {
      User? currentUser = _authRepo.currentUser;
      if (currentUser == null || currentUser.email == null) return false;

      dev.log("Starting password change process", name: "ProfileService");
      bool isReauthenticated = await _authRepo.reauthenticateUser(currentUser.email!, currentPassword);
      if (!isReauthenticated) {
        dev.log("Error: Re-authentication failed", name: "ProfileService");
        throw Exception("The current password you entered is incorrect.");
      }

      await _authRepo.updatePassword(newPassword);
      dev.log("Password changed successfully", name: "ProfileService");
      return true;

    } on FirebaseException catch (e) {
      dev.log("Firebase error changing password: ${e.message}", name: "ProfileService");
      throw Exception("Server error updating password: ${e.message}");
    } catch (e, stack) {
      dev.log("Error changing password", name: "ProfileService", error: e, stackTrace: stack);
      throw Exception("Error in password change process: $e");
    }
  }

  // Deletes user data, business documents, and authentication credentials.
  Future<bool> deleteAccount(String uid, String role) async {
    try {
      dev.log("Starting account deletion for: $uid", name: "ProfileService");
      if (role == 'PROV') {
        BusinessModel? biz = await _bizRepo.getBusinessByOwnerUid(uid);
        if (biz != null) {
          await _bizRepo.deleteBusinessDoc(biz.businessId);
        }
      }

      await _userRepo.deleteUserDoc(uid);
      await _authRepo.deleteUserAuth();
      dev.log("The account has been completely deleted from the system.", name: "ProfileService");
      return true;
    } on FirebaseException catch (e) {
      dev.log("Firebase error in account deletion: ${e.message}", name: "ProfileService");
      throw Exception("Server error in account deletion: ${e.message}");
    } catch (e, stack) {
      dev.log("Error in account deletion process", name: "ProfileService", error: e, stackTrace: stack);
      throw Exception("Error in account deletion process: $e");
    }
  }

  // Updates information for a business.
  Future<bool> updateBusinessProfileDetails(String businessId, String businessName, String businessPhone, String city, String streetAddress, String logoUrl) async {
    try {
      dev.log("Updating business details for: $businessId", name: "ProfileService");
      await _bizRepo.updateBusinessFields(businessId, {
        'businessName': businessName, 'phoneNumber': businessPhone, 'city': city,
        'streetAddress': streetAddress, 'logoUrl': logoUrl,
      });
      return true;
    } on FirebaseException catch (e) {
      dev.log("Firebase error updating business details: ${e.message}", name: "ProfileService");
      throw Exception("Server error updating business details: ${e.message}");
    } catch (e, stack) {
      dev.log("Error updating business details", name: "ProfileService", error: e, stackTrace: stack);
      throw Exception("Error updating business profile: $e");
    }
  }

  // Retrieves the city associated with a customer account.
  Future<String?> getCurrentCustomerCity(String uid) async {
    try {
      dev.log("Retrieves a city for a user: $uid", name: "ProfileService");
      UserModel? user = await _userRepo.getUserById(uid);
      return user?.city;
    } on FirebaseException catch (e) {
      dev.log("Firebase error retrieving user city: ${e.message}", name: "ProfileService");
      throw Exception("Server error retrieving user location: ${e.message}");
    } catch (e, stack) {
      dev.log("Error retrieving user city", name: "ProfileService", error: e, stackTrace: stack);
      throw Exception("Error finding the user's city: $e");
    }
  }

  // Upload an image or document file to cloud storage.
  Future<String?> uploadImageOrFile(dynamic file, String folderPath, String fileName) async {
    try {
      return await _storageRepo.uploadFile(file, folderPath, fileName);
    } on FirebaseException catch (e) {
      dev.log("Firebase error uploading file: ${e.message}", name: "ProfileService");
      throw Exception("Server error uploading the file: ${e.message}");
    } catch (e) {
      dev.log("Error uploading file", name: "ProfileService", error: e);
      throw Exception("Error during file upload: $e");
    }
  }

  // Retrieves display details for a business by its ID.
  Future<Map<String, dynamic>?> getBusinessDetailsById(String businessId) async {
    try {
      dev.log("Extracts business details for data enrichment: $businessId", name: "ProfileService");
      BusinessModel? biz = await _bizRepo.getBusinessById(businessId);
      if (biz == null) return null;

      return {
        'businessName': biz.businessName, 'logoUrl': biz.logoUrl, 'rating': biz.rating,
        'city': biz.city, 'streetAddress': biz.streetAddress
      };
    } on FirebaseException catch (e) {
      dev.log("Firebase error retrieving business details: ${e.message}", name: "ProfileService");
      throw Exception("Server error retrieving business information: ${e.message}");
    } catch (e, stack) {
      dev.log("Error retrieving business details", name: "ProfileService", error: e, stackTrace: stack);
      throw Exception("Error finding the business details: $e");
    }
  } 
}