import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:save_a_bite/core/theme/app_colors.dart';
import 'package:save_a_bite/core/widgets/custom_text_field.dart';
import 'package:save_a_bite/backend/controllers/AuthController.dart';
import 'package:save_a_bite/address_search_field.dart';

/// Screen responsible for User and Business registration processes.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  /// The current selected role: 'CUST' for Customer, 'PROV' for Business Provider
  String _currentRole = 'CUST';

  // --- Input Controllers ---
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // --- Business Specific Input Controllers ---
  final _businessNameController = TextEditingController();
  final _businessPhoneController = TextEditingController();

  // --- Data State for Uploads and Location ---
  String _logoUrl = "";
  String _licenseUrl = "";
  String _googleFullAddress = "טרם נבחר מיקום";
  String _googleCity = "";
  double? _latitude;
  double? _longitude;

  // Local state flag for tracking file upload progress
  bool _isFileUploading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _businessNameController.dispose();
    _businessPhoneController.dispose();
    super.dispose();
  }

  /// Handles asynchronous file picking and secure cloud upload via AuthController.
  Future<void> _pickAndUploadFile(bool isLogo) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf'],
    );

    if (result == null) return;

    setState(() => _isFileUploading = true);

    String? url;
    try {
      if (kIsWeb) {
        url = await context.read<AuthController>().uploadBytesToCloud(
            result.files.single.bytes!, result.files.single.name);
      } else {
        File file = File(result.files.single.path!);
        url = await context.read<AuthController>().uploadFileToCloud(file);
      }
    } catch (e) {
      url = null;
    }

    if (!mounted) return;
    setState(() => _isFileUploading = false);

    if (url != null) {
      setState(() => isLogo ? _logoUrl = url! : _licenseUrl = url!);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('הקובץ עלה בהצלחה!', textAlign: TextAlign.right),
          backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('שגיאה בהעלאת הקובץ', textAlign: TextAlign.right),
          backgroundColor: Colors.red));
    }
  }

  /// Validates all general and business-specific form inputs prior to submission.
  bool _validateInput(bool isBusiness) {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('נא למלא את כל שדות החובה הכלליים',
              textAlign: TextAlign.right),
          backgroundColor: Colors.red));
      return false;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('הסיסמאות אינן תואמות', textAlign: TextAlign.right),
          backgroundColor: Colors.red));
      return false;
    }
    if (_googleCity.isEmpty || _latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('נא לבחור כתובת מתוך הרשימה', textAlign: TextAlign.right),
          backgroundColor: Colors.red));
      return false;
    }

    if (isBusiness) {
      if (_businessNameController.text.trim().isEmpty ||
          _businessPhoneController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('נא למלא את כל פרטי העסק', textAlign: TextAlign.right),
            backgroundColor: Colors.red));
        return false;
      }
      if (_logoUrl.isEmpty || _licenseUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('נא להעלות לוגו ורישיון עסק', textAlign: TextAlign.right),
            backgroundColor: Colors.red));
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isBusiness = _currentRole == 'PROV';
    final authController = context.watch<AuthController>();

    return Scaffold(
      appBar: AppBar(
          title: const Text('הרשמה',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: AppColors.deepBlue,
          centerTitle: true),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // --- Role Selection Section ---
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Radio<String>(
                    value: 'CUST',
                    groupValue: _currentRole,
                    onChanged: (v) => setState(() => _currentRole = v!)),
                const Text('לקוח'),
                const SizedBox(width: 30),
                Radio<String>(
                    value: 'PROV',
                    groupValue: _currentRole,
                    onChanged: (v) => setState(() => _currentRole = v!)),
                const Text('עסק'),
              ]),

              // --- General User Data Fields ---
              CustomTextField(
                  controller: _nameController,
                  hintText: 'שם מלא',
                  prefixIcon: Icons.person_outline),
              const SizedBox(height: 16),
              CustomTextField(
                  controller: _emailController,
                  hintText: 'אימייל',
                  prefixIcon: Icons.email_outlined),
              const SizedBox(height: 16),
              CustomTextField(
                  controller: _phoneController,
                  hintText: 'טלפון',
                  prefixIcon: Icons.phone_android_outlined),
              const SizedBox(height: 16),
              CustomTextField(
                  controller: _passwordController,
                  hintText: 'סיסמה',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true),
              const SizedBox(height: 16),
              CustomTextField(
                  controller: _confirmPasswordController,
                  hintText: 'אימות סיסמה',
                  prefixIcon: Icons.lock_clock_outlined,
                  isPassword: true),

              // --- Business Specific Data Fields ---
              if (isBusiness) ...[
                const SizedBox(height: 16),
                CustomTextField(
                    controller: _businessNameController,
                    hintText: 'שם העסק',
                    prefixIcon: Icons.storefront_outlined),
                const SizedBox(height: 16),
                CustomTextField(
                    controller: _businessPhoneController,
                    hintText: 'טלפון העסק',
                    prefixIcon: Icons.phone),
                const SizedBox(height: 16),

                // File Upload Selection Tiles
                ListTile(
                  title: Text(
                      _logoUrl.isEmpty ? 'בחר לוגו עסק (תמונה)' : 'לוגו נבחר!'),
                  leading: _isFileUploading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.image),
                  onTap:
                      _isFileUploading ? null : () => _pickAndUploadFile(true),
                ),
                ListTile(
                  title: Text(_licenseUrl.isEmpty
                      ? 'בחר רישיון עסק (PDF/תמונה)'
                      : 'רישיון נבחר!'),
                  leading: _isFileUploading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.badge),
                  onTap:
                      _isFileUploading ? null : () => _pickAndUploadFile(false),
                ),
              ],

              const SizedBox(height: 20),

              // --- Location Search Field Component ---
              AddressSearchField(
                  isCityOnly: !isBusiness,
                  onAddressSelected: (addr, city, lat, lng) => setState(() {
                        _googleFullAddress = addr;
                        _googleCity = city;
                        _latitude = lat;
                        _longitude = lng;
                      })),

              const SizedBox(height: 30),

              // --- Registration Submit Button Execution ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: authController.isLoading
                      ? null
                      : () async {
                          if (!_validateInput(isBusiness)) return;

                          bool success = isBusiness
                              ? await context
                                  .read<AuthController>()
                                  .registerBusiness(
                                      _emailController.text.trim(),
                                      _passwordController.text,
                                      _nameController.text.trim(),
                                      _phoneController.text.trim(),
                                      _businessPhoneController.text.trim(),
                                      _googleCity,
                                      _googleCity,
                                      _businessNameController.text.trim(),
                                      _googleFullAddress,
                                      _licenseUrl,
                                      _logoUrl,
                                      GeoPoint(_latitude!, _longitude!))
                              : await context
                                  .read<AuthController>()
                                  .registerCustomer(
                                      _emailController.text.trim(),
                                      _passwordController.text,
                                      _nameController.text.trim(),
                                      _phoneController.text.trim(),
                                      _googleCity);

                          if (success) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('נרשמת בהצלחה!',
                                      textAlign: TextAlign.right),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Navigator.pop(context);
                            }
                          } else {
                            if (mounted) {
                              String errorMsg = context
                                      .read<AuthController>()
                                      .errorMessage ??
                                  'שגיאה בהרשמה, ייתכן שהמשתמש כבר קיים או שפרטים חסרים.';
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(errorMsg,
                                          textAlign: TextAlign.right),
                                      backgroundColor: Colors.red));
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: authController.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text('הרשמה',
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
