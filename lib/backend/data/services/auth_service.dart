import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_model.dart';
import '../models/business_model.dart';
import '../repositories/AuthRepository.dart';
import '../repositories/UserRepository.dart';
import '../repositories/BusinessRepository.dart';
import 'dart:typed_data';

class AuthService {
  final AuthRepository _authRepo = AuthRepository();
  final UserRepository _userRepo = UserRepository();
  final BusinessRepository _bizRepo = BusinessRepository();

  // Authenticates a user and verifies their system role and approval status.
  Future<String?> loginUser(String email, String password) async {
    try {
      dev.log("Starting login process for: $email", name: "AuthService");

      UserCredential? cred = await _authRepo.signInAuth(email, password);
      if (cred == null || cred.user == null) {
        dev.log("Error: Invalid login credentials", name: "AuthService");
        return null;
      }

      String uid = cred.user!.uid;

      UserModel? user = await _userRepo.getUserById(uid);
      if (user == null) {
        dev.log("Error: User not found in USER table", name: "AuthService");
        await _authRepo.signOutAuth();
        return null;
      }

      if (!user.isActive) {
        dev.log("Error: User is blocked or pending approval",
            name: "AuthService");
        await _authRepo.signOutAuth();
        throw Exception("Account is pending admin approval or blocked.");
      }

      if (user.role == 'PROV') {
        BusinessModel? biz = await _bizRepo.getBusinessByOwnerUid(uid);
        if (biz == null || biz.v_status != 'APPR') {
          dev.log("Error: Business not yet approved by admin",
              name: "AuthService");
          await _authRepo.signOutAuth();
          throw Exception("Business pending approval.");
        }
      }

      dev.log("Login successful, role: ${user.role}", name: "AuthService");
      return user.role;
    } on FirebaseException catch (e) {
      dev.log("Firebase auth error: ${e.message}", name: "AuthService");
      throw Exception("Server login error: ${e.message}");
    } catch (e, stack) {
      dev.log("General login error",
          name: "AuthService", error: e, stackTrace: stack);
      throw Exception("An error occurred during login: $e");
    }
  }

  // Registers a new customer and initializes their database profile.
  Future<String?> registerCustomer(
      {required String email,
      required String password,
      required String fullName,
      required String phoneNumber,
      required String city}) async {
    try {
      dev.log("Starting customer registration: $email", name: "AuthService");

      UserCredential? cred = await _authRepo.createUserAuth(email, password);
      if (cred == null || cred.user == null) return null;

      String uid = cred.user!.uid;

      UserModel newUser = UserModel(
        uid: uid,
        email: email,
        role: 'CUST',
        fullName: fullName,
        phoneNumber: phoneNumber,
        isActive: true,
        city: city,
        streetAddress: '',
        coordinates: null,
      );

      await _userRepo.saveUser(newUser);
      dev.log("Customer registered and saved successfully",
          name: "AuthService");
      return uid;
    } on FirebaseException catch (e) {
      dev.log("Firebase customer registration error: ${e.message}",
          name: "AuthService");
      throw Exception("Server registration error: ${e.message}");
    } catch (e, stack) {
      dev.log("General customer registration error",
          name: "AuthService", error: e, stackTrace: stack);
      throw Exception("Unexpected registration error: $e");
    }
  }

  // Registers a new business provider, creating both User and Business profiles pending approval.
  Future<String?> registerBusinessProvider({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String businessPhone,
    required String personalCity,
    required String businessCity,
    required String businessName,
    required String streetAddress,
    required String licenseUrl,
    required String logoUrl,
    required GeoPoint coordinates,
  }) async {
    try {
      dev.log("Starting business registration: $businessName",
          name: "AuthService");

      UserCredential? cred = await _authRepo.createUserAuth(email, password);
      if (cred == null || cred.user == null) return null;

      String uid = cred.user!.uid;

      UserModel newUser = UserModel(
        uid: uid,
        email: email,
        role: 'PROV',
        fullName: fullName,
        phoneNumber: phoneNumber,
        isActive: false,
        city: personalCity,
        streetAddress: '',
        coordinates: null,
      );
      await _userRepo.saveUser(newUser);

      String businessId =
          FirebaseFirestore.instance.collection('BUSINESS').doc().id;

      BusinessModel newBiz = BusinessModel(
        businessId: businessId,
        ownerUid: uid,
        businessName: businessName,
        city: businessCity,
        streetAddress: streetAddress,
        phoneNumber: businessPhone,
        licenseUrl: licenseUrl,
        v_status: 'PEND',
        rating: 0.0,
        coordinates: coordinates,
        logoUrl: logoUrl,
      );

      await _bizRepo.saveBusiness(newBiz);
      dev.log("Business created and pending admin approval",
          name: "AuthService");
      return uid;
    } on FirebaseException catch (e) {
      dev.log("Firebase business registration error: ${e.message}",
          name: "AuthService");
      throw Exception("Server business registration error: ${e.message}");
    } catch (e, stack) {
      dev.log("General business registration error",
          name: "AuthService", error: e, stackTrace: stack);
      throw Exception("Unexpected business registration error: $e");
    }
  }

  // Triggers a password reset email via Firebase Auth.
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      dev.log("Sending password reset email to: $email", name: "AuthService");
      await _authRepo.sendPasswordResetEmail(email);
      return true;
    } on FirebaseException catch (e) {
      dev.log("Firebase password reset error: ${e.message}",
          name: "AuthService");
      throw Exception("Server password reset error: ${e.message}");
    } catch (e, stack) {
      dev.log("Error sending reset email",
          name: "AuthService", error: e, stackTrace: stack);
      throw Exception("Failed to send reset email: $e");
    }
  }

  // Terminates the current user session.
  Future<bool> logoutUser() async {
    try {
      dev.log("Logging user out of the system", name: "AuthService");
      await _authRepo.signOutAuth();
      return true;
    } catch (e, stack) {
      dev.log("Logout error", name: "AuthService", error: e, stackTrace: stack);
      throw Exception("Failed to log out: $e");
    }
  }

  // Verifies if a valid, active session exists for the current user.
  Future<Map<String, String>?> checkCurrentUserSession() async {
    try {
      User? currentUser = _authRepo.currentUser;
      if (currentUser == null) return null;

      UserModel? user = await _userRepo.getUserById(currentUser.uid);
      if (user == null || !user.isActive) return null;

      if (user.role == 'PROV') {
        BusinessModel? biz =
            await _bizRepo.getBusinessByOwnerUid(currentUser.uid);
        if (biz == null || biz.v_status != 'APPR') return null;
      }

      return {'uid': user.uid, 'role': user.role};
    } on FirebaseException catch (e) {
      dev.log("Firebase session check error: ${e.message}",
          name: "AuthService");
      throw Exception("Server session error: ${e.message}");
    } catch (e) {
      dev.log("General session check error", name: "AuthService", error: e);
      throw Exception("Failed to verify existing session: $e");
    }
  }

  // Uploads a standard File to Uploadcare and returns the secure URL.
  Future<String?> uploadToUploadcare(File file) async {
    try {
      final url = Uri.parse('https://upload.uploadcare.com/base/');
      final request = http.MultipartRequest('POST', url)
        ..fields['UPLOADCARE_PUB_KEY'] = dotenv.env['UPLOADCARE_PUB_KEY']!
        ..fields['UPLOADCARE_STORE'] = '1'
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final result = json.decode(String.fromCharCodes(responseData));

        // Clean filename and build safe CDN URL
        final rawFileName = file.path.split('/').last;
        final safeFileName = _getSafeFileName(rawFileName);

        return "https://5haphmbtmb.ucarecd.net/${result['file']}/$safeFileName";
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Uploads byte data to Uploadcare and returns the secure URL.
  Future<String?> uploadBytesToCloud(Uint8List bytes, String fileName) async {
    try {
      final url = Uri.parse('https://upload.uploadcare.com/base/');
      final request = http.MultipartRequest('POST', url)
        ..fields['UPLOADCARE_PUB_KEY'] = dotenv.env['UPLOADCARE_PUB_KEY']!
        ..fields['UPLOADCARE_STORE'] = '1'
        ..files.add(
            http.MultipartFile.fromBytes('file', bytes, filename: fileName));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final result = json.decode(String.fromCharCodes(responseData));

        // Clean filename and build safe CDN URL
        final safeFileName = _getSafeFileName(fileName);

        return "https://5haphmbtmb.ucarecd.net/${result['file']}/$safeFileName";
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Sanitizes filename to prevent 404 errors on CDN custom domains
  String _getSafeFileName(String originalName) {
    if (originalName.isEmpty ||
        originalName == 'noroot.pdf' ||
        originalName.contains('blob')) {
      return 'document.pdf';
    }

    // Extract file extension
    final extension = originalName.contains('.')
        ? originalName.split('.').last.toLowerCase()
        : 'pdf';

    // Replace non-ASCII characters, spaces, and special symbols with underscores
    final safeName = originalName.replaceAll(RegExp(r'[^\w\.-]'), '_');

    // If the name became empty after cleaning, fallback to a default name
    if (safeName.replaceAll('_', '').trim().isEmpty) {
      return 'file_$extension';
    }

    return safeName;
  }
}
