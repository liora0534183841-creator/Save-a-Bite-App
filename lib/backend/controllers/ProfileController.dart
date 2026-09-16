import 'package:flutter/material.dart';
import 'dart:developer' as dev;
import '../data/models/user_model.dart';
import '../data/models/business_model.dart';
import '../data/services/profile_service.dart';

// Manages user and business profile data, including updates, deletion, and file uploads.
class ProfileController extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();

  bool _isLoading = false;
  // Returns whether an authentication process is currently running.
  bool get isLoading => _isLoading;

  UserModel? _currentUserData;
  // The loaded data of the current user.
  UserModel? get currentUserData => _currentUserData;

  BusinessModel? _currentBusinessData;
  // The loaded profile data of the current business provider.
  BusinessModel? get currentBusinessData => _currentBusinessData;

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

  // Loads profile data for a specific user.
  Future<void> loadUserData(String uid) async {
    _setLoading(true);
    clearError();
    try {
      dev.log("Request to controller: Load user profile", name: "ProfileController");
      _currentUserData = await _profileService.getBasicUserData(uid);
    } catch (e, stack) {
      dev.log("Error loading user profile", name: "ProfileController", error: e, stackTrace: stack);
      _currentUserData = null;
      _errorMessage = e.toString().replaceAll("Exception: ", "");
    } finally {
      _setLoading(false);
    }
  }

 // Loads profile data for a business provider based on their owner UID.
  Future<void> loadBusinessData(String ownerUid) async {
    _setLoading(true);
    clearError();
    try {
      dev.log("Request to Controller: Load Business by Owner ID", name: "ProfileController");
      _currentBusinessData = await _profileService.getBusinessProviderData(ownerUid);
    } catch (e, stack) {
      dev.log("Error loading business profile", name: "ProfileController", error: e, stackTrace: stack);
      _currentBusinessData = null;
      _errorMessage = e.toString().replaceAll("Exception: ", "");
    } finally {
      _setLoading(false);
    }
  }

  // Updates a customer's profile information.
  Future<bool> updateCustomer({
    required String uid,
    required String fullName,
    required String phoneNumber,
    required String city,
    required String streetAddress,
  }) async {
    _setLoading(true);
    clearError();
    try {
      dev.log("Request to controller: Update customer profile", name: "ProfileController");
      bool success = await _profileService.updateCustomerProfile(
        uid, fullName, phoneNumber, city, streetAddress,
      );
      if (success) {
        await loadUserData(uid);
      }
      return success;
    } catch (e, stack) {
      dev.log("Error updating customer profile", name: "ProfileController", error: e, stackTrace: stack);
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Updates a business's profile details.
  Future<bool> updateBusinessDetails({
    required String businessId,
    required String ownerUid,
    required String businessName,
    required String businessPhone,
    required String city,
    required String streetAddress,
    required String logoUrl,
  }) async {
    _setLoading(true);
    clearError();
    try {
      dev.log("Request to controller: Update business details", name: "ProfileController");
      bool success = await _profileService.updateBusinessProfileDetails(
        businessId, businessName, businessPhone, city, streetAddress, logoUrl,
      );
      if (success) {
        await loadBusinessData(ownerUid);
      }
      return success;
    } catch (e, stack) {
      dev.log("Error updating business details", name: "ProfileController", error: e, stackTrace: stack);
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Changes the authenticated user's password.
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    _setLoading(true);
    clearError();
    try {
      dev.log("Request to controller: Change password", name: "ProfileController");
      bool success = await _profileService.changeUserPassword(oldPassword, newPassword);
      return success;
    } catch (e, stack) {
      dev.log("Error changing password", name: "ProfileController", error: e, stackTrace: stack);
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Deleted a user account and clears cached data on success.
  Future<bool> deleteUserAccount(String uid, String role) async {
    _setLoading(true);
    clearError();
    try {
      dev.log("Request to controller: Delete account", name: "ProfileController");
      bool success = await _profileService.deleteAccount(uid, role);
      if (success) {
        _currentUserData = null;
        _currentBusinessData = null;
      }
      return success;
    } catch (e, stack) {
      dev.log("Error deleting account", name: "ProfileController", error: e, stackTrace: stack);
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Uploads an image or file to the specified storage folder.
  Future<String?> uploadFile(
    dynamic file,
    String folderPath,
    String fileName,
  ) async {
    _setLoading(true);
    clearError();
    try {
      dev.log("Request to controller: Upload file", name: "ProfileController");
      String? url = await _profileService.uploadImageOrFile(file, folderPath, fileName);
      return url;
    } catch (e, stack) {
      dev.log("Error uploading file", name: "ProfileController", error: e, stackTrace: stack);
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Retrieves the current city of a customer by their ID.
  Future<String?> getCustomerCity(String uid) async {
    clearError();
    try {
      dev.log("Request to the controller: Retrieve the customer's city", name: "ProfileController");
      return await _profileService.getCurrentCustomerCity(uid);
    } catch (e, stack) {
      dev.log("Error retrieving customer city", name: "ProfileController", error: e, stackTrace: stack);
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      notifyListeners();
      return null;
    }
  }

  // Retrieves detailed information for a specific business.
  Future<Map<String, dynamic>?> getBusinessDetails(String businessId) async {
    _setLoading(true);
    clearError();
    try {
      dev.log("Request to the controller: Retrieve business details", name: "ProfileController");
      return await _profileService.getBusinessDetailsById(businessId);
    } catch (e, stack) {
      dev.log("Error retrieving business details", name: "ProfileController", error: e, stackTrace: stack);
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      return null;
    } finally {
      _setLoading(false);
    }
  }
}