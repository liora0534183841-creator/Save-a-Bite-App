import 'package:flutter/material.dart';
import 'dart:developer' as dev;
import '../data/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:typed_data';

// Controller handling user authentication, registration, password resets, and file uploads.
class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  // Returns whether an authentication process is currently running.
  bool get isLoading => _isLoading;

  String? _userRole;
  // Holds the role of the currently logged-in user.
  String? get userRole => _userRole;

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

  // Logs in a user with email and password and saves their role.
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    clearError();
    try {
      dev.log("Request to controller: login $email", name: "AuthController");
      String? role = await _authService.loginUser(email, password);
      if (role != null) {
        _userRole = role;
        return true;
      } else {
        _errorMessage = "Login failed. Please check your details or account status.";
        return false;
      }
    } catch (e, stack) {
      dev.log("Error in AuthController: login", name: "AuthController", error: e, stackTrace: stack);
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Registers a new customer account.
  Future<bool> registerCustomer(String email, String password, String fullName, String phone, String city) async {
    _setLoading(true);
    clearError();
    try {
      dev.log("Request to controller: Register customer $email", name: "AuthController");
      String? uid = await _authService.registerCustomer(
        email: email, 
        password: password, 
        fullName: fullName, 
        phoneNumber: phone, 
        city: city
      );
      return uid != null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Registers a new business account with business details and location coordinates.
  Future<bool> registerBusiness(
    String email, String password, String fullName, String phone,
    String businessPhone, String personalCity, String businessCity,
    String businessName, String streetAddress, String licenseUrl,
    String logoUrl, GeoPoint coordinates,
  ) async {
    _setLoading(true);
    clearError();
    try {
      dev.log("Request to the Controller: Business Registration $businessName", name: "AuthController");
      String? uid = await _authService.registerBusinessProvider(
        email: email, password: password, fullName: fullName, phoneNumber: phone,
        businessPhone: businessPhone, personalCity: personalCity, businessCity: businessCity,
        businessName: businessName, streetAddress: streetAddress, licenseUrl: licenseUrl,
        logoUrl: logoUrl, coordinates: coordinates,
      );
      return uid != null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sends a password reset link to the specified email.
  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    clearError();
    try {
      bool success = await _authService.sendPasswordResetEmail(email);
      if (!success) {
        _errorMessage = "Sending the password reset email failed.";
      }
      return success;
    } catch (e, stack) {
      dev.log("Error in AuthController: send password reset", name: "AuthController", error: e, stackTrace: stack);
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logs out the current user and clears the saved user role.
  Future<bool> logout() async {
    _setLoading(true);
    clearError();
    try {
      bool success = await _authService.logoutUser();
      if (success) {
        _userRole = null;
      }
      return success;
    } catch (e, stack) {
      dev.log("Error in AuthController: logout", name: "AuthController", error: e, stackTrace: stack);
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      return false;
    } finally {
      _setLoading(false);
    }
  }
  // Uploads a file to the cloud service and returns the uploaded file URL.
  Future<String?> uploadFileToCloud(File file) async {
    return await _authService.uploadToUploadcare(file);
  }

  /// Uploads raw bytes (Used for Web to prevent path errors)
  Future<String?> uploadBytesToCloud(Uint8List bytes, String fileName) async {
    return await _authService.uploadBytesToCloud(bytes, fileName);
  }
}