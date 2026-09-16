import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:save_a_bite/core/theme/app_colors.dart';
import 'package:save_a_bite/address_search_field.dart';
import 'package:save_a_bite/backend/controllers/ProfileController.dart';

/// A modal dialog widget that allows customers to edit their personal profile data
/// and securely update their account credentials.
class EditUserDialog extends StatefulWidget {
  const EditUserDialog({super.key});

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  // Text controllers for capturing basic user input fields
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  // State variables for geographical location tracking
  String _selectedCity = '';
  String _selectedStreet = '';

  // Text controllers for secure password modification
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Loading state flag to lock user interactions during network operations
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final profileController = context.read<ProfileController>();
    final user = profileController.currentUserData;

    // Initialize controllers with existing user profile data
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _emailController = TextEditingController(
        text: FirebaseAuth.instance.currentUser?.email ?? '');

    _selectedCity = user?.city ?? '';
    _selectedStreet = user?.streetAddress ?? '';
  }

  @override
  void dispose() {
    // Clean up controllers to prevent memory leaks upon widget destruction
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Validates input parameters, synchronizes profile data, and executes password updates if requested.
  Future<void> _saveChanges() async {
    final bool wantsToChangePassword = _oldPasswordController.text.isNotEmpty ||
        _newPasswordController.text.isNotEmpty ||
        _confirmPasswordController.text.isNotEmpty;

    if (wantsToChangePassword) {
      if (_oldPasswordController.text.isEmpty) {
        _showSnackBar('יש להזין סיסמה נוכחית כדי לשנות סיסמה', isError: true);
        return;
      }
      if (_newPasswordController.text != _confirmPasswordController.text) {
        _showSnackBar('הסיסמאות החדשות אינן תואמות!', isError: true);
        return;
      }
      if (_newPasswordController.text.length < 6) {
        _showSnackBar('הסיסמה החדשה חייבת להכיל לפחות 6 תווים', isError: true);
        return;
      }
    }

    setState(() => _isSaving = true);
    final profileController = context.read<ProfileController>();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    bool profileUpdated = false;
    bool passwordUpdated = false;

    // Update basic customer profile information in the database repository
    profileUpdated = await profileController.updateCustomer(
      uid: uid,
      fullName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      city: _selectedCity,
      streetAddress: _selectedStreet,
    );

    // Process password modification if profile update succeeded and change was requested
    if (profileUpdated && wantsToChangePassword) {
      passwordUpdated = await profileController.changePassword(
          _oldPasswordController.text, _newPasswordController.text);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (profileUpdated) {
      if (wantsToChangePassword && !passwordUpdated) {
        _showSnackBar(
            'הפרטים נשמרו, אך חלה שגיאה בעדכון הסיסמה: ${profileController.errorMessage}',
            isError: true);
      } else {
        _showSnackBar('הפרטים נשמרו בהצלחה', isError: false);
        Navigator.pop(context);
      }
    } else {
      _showSnackBar('שגיאה בשמירת הפרטים: ${profileController.errorMessage}',
          isError: true);
    }
  }

  /// Helper method for displaying contextual feedback messages to the user.
  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.right),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: EdgeInsets.only(bottom: keyboardInset * 0.5),
        child: AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('עריכת פרטים אישיים',
              style: TextStyle(
                  color: AppColors.deepBlue, fontWeight: FontWeight.bold)),
          content: Container(
            width: 400,
            constraints: const BoxConstraints(maxHeight: 450),
            child: IgnorePointer(
              ignoring: _isSaving,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameController,
                      scrollPadding: const EdgeInsets.all(40),
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black),
                      decoration: const InputDecoration(
                          labelText: 'שם מלא', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      scrollPadding: const EdgeInsets.all(40),
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black),
                      decoration: const InputDecoration(
                          labelText: 'מספר טלפון',
                          border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      scrollPadding: const EdgeInsets.all(40),
                      style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54),
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'אימייל (לא ניתן לשינוי)',
                        border: OutlineInputBorder(),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Location Search Component
                    AddressSearchField(
                      isCityOnly: true,
                      onAddressSelected: (fullAddress, city, lat, lng) {
                        setState(() {
                          _selectedCity = city;
                        });
                      },
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        'העיר שנבחרה: ${_selectedCity.isEmpty ? 'טרם נבחרה' : _selectedCity}',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text('החלפת סיסמה :',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _oldPasswordController,
                      obscureText: true,
                      scrollPadding: const EdgeInsets.all(40),
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black),
                      decoration: const InputDecoration(
                          labelText: 'סיסמה נוכחית',
                          border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: true,
                      scrollPadding: const EdgeInsets.all(40),
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black),
                      decoration: const InputDecoration(
                          labelText: 'סיסמה חדשה',
                          border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      scrollPadding: const EdgeInsets.all(40),
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black),
                      decoration: const InputDecoration(
                          labelText: 'אימות סיסמה חדשה',
                          border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            if (!_isSaving)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child:
                    const Text('ביטול', style: TextStyle(color: Colors.grey)),
              ),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('שמירה'),
            ),
          ],
        ),
      ),
    );
  }
}
