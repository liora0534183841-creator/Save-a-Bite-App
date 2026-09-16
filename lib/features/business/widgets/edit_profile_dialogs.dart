import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:save_a_bite/core/theme/app_colors.dart';
import 'package:save_a_bite/address_search_field.dart';
import 'package:save_a_bite/backend/controllers/ProfileController.dart';

/// A dialog widget facilitating the modification of the core business profile parameters.
class EditBusinessDialog extends StatefulWidget {
  const EditBusinessDialog({super.key});

  @override
  State<EditBusinessDialog> createState() => _EditBusinessDialogState();
}

class _EditBusinessDialogState extends State<EditBusinessDialog> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  String _currentAddress = '';
  String _currentCity = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final bizData = context.read<ProfileController>().currentBusinessData;

    _nameController = TextEditingController(text: bizData?.businessName ?? '');
    _phoneController = TextEditingController(text: bizData?.phoneNumber ?? '');
    _currentAddress = bizData?.streetAddress ?? '';
    _currentCity = bizData?.city ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Processes form submission, validates constraints, and synchronizes updates with Firestore.
  Future<void> _saveBusiness() async {
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('נא למלא את כל שדות החובה', textAlign: TextAlign.right),
          backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    final profileCtrl = context.read<ProfileController>();
    final bizData = profileCtrl.currentBusinessData;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (bizData == null || uid.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final success = await profileCtrl.updateBusinessDetails(
      businessId: bizData.businessId,
      ownerUid: uid,
      businessName: _nameController.text.trim(),
      businessPhone: _phoneController.text.trim(),
      city: _currentCity,
      streetAddress: _currentAddress,
      logoUrl: bizData.logoUrl,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('פרטי העסק עודכנו בהצלחה', textAlign: TextAlign.right),
            backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('שגיאה בעדכון: ${profileCtrl.errorMessage}',
                textAlign: TextAlign.right),
            backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        title: const Text('עריכת פרטי עסק',
            style: TextStyle(
                color: AppColors.deepBlue, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          height: MediaQuery.of(context).size.height * 0.6,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: _nameController,
                    enabled: !_isLoading,
                    style:
                        TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: const InputDecoration(
                        labelText: 'שם העסק', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(
                    controller: _phoneController,
                    enabled: !_isLoading,
                    keyboardType: TextInputType.phone,
                    style:
                        TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: const InputDecoration(
                        labelText: 'מספר טלפון', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                const Align(
                    alignment: Alignment.centerRight,
                    child: Text('כתובת העסק:',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                AddressSearchField(
                    isCityOnly: false,
                    onAddressSelected: (fullAddress, city, lat, lng) {
                      setState(() {
                        _currentAddress = fullAddress;
                        _currentCity = city;
                      });
                    }),
                const SizedBox(height: 8),
                Text(
                    'כתובת: ${_currentAddress.isEmpty ? "טרם הוזנה" : _currentAddress}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ),
        actions: [
          if (!_isLoading)
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ביטול')),
          ElevatedButton(
              onPressed: _isLoading ? null : _saveBusiness,
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('שמירה')),
        ],
      ),
    );
  }
}

/// A dialog widget facilitating the modification of the customer's personal user profile and password credentials.
class EditUserDialog extends StatefulWidget {
  const EditUserDialog({super.key});

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final userData = context.read<ProfileController>().currentUserData;
    final authUser = FirebaseAuth.instance.currentUser;

    _nameController = TextEditingController(text: userData?.fullName ?? '');
    _emailController = TextEditingController(text: authUser?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Processes form submission, validates password modification constraints, and commits profile updates.
  Future<void> _saveUser() async {
    final wantsPasswordChange = _newPasswordController.text.isNotEmpty;

    if (wantsPasswordChange) {
      if (_oldPasswordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('נא להזין סיסמה נוכחית', textAlign: TextAlign.right),
            backgroundColor: Colors.red));
        return;
      }
      if (_newPasswordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('הסיסמאות החדשות אינן זהות!', textAlign: TextAlign.right),
            backgroundColor: Colors.red));
        return;
      }
    }

    setState(() => _isLoading = true);

    final profileCtrl = context.read<ProfileController>();
    final userData = profileCtrl.currentUserData;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (uid.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    bool profileSuccess = await profileCtrl.updateCustomer(
      uid: uid,
      fullName: _nameController.text.trim(),
      phoneNumber: userData?.phoneNumber ?? '',
      city: userData?.city ?? '',
      streetAddress: userData?.streetAddress ?? '',
    );

    bool passwordSuccess = false;
    if (profileSuccess && wantsPasswordChange) {
      passwordSuccess = await profileCtrl.changePassword(
          _oldPasswordController.text, _newPasswordController.text);
    }

    if (mounted) {
      setState(() => _isLoading = false);

      if (profileSuccess) {
        if (wantsPasswordChange && !passwordSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'השם עודכן, אך שינוי הסיסמה נכשל: ${profileCtrl.errorMessage}',
                  textAlign: TextAlign.right),
              backgroundColor: Colors.orange));
        } else {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('הפרטים עודכנו בהצלחה', textAlign: TextAlign.right),
              backgroundColor: Colors.green));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('שגיאה בעדכון: ${profileCtrl.errorMessage}',
                textAlign: TextAlign.right),
            backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        title: const Text('עריכת פרטי משתמש',
            style: TextStyle(
                color: AppColors.deepBlue, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          height: MediaQuery.of(context).size.height * 0.6,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: _nameController,
                    enabled: !_isLoading,
                    style:
                        TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: const InputDecoration(
                        labelText: 'שם מלא', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(
                    controller: _emailController,
                    enabled: false,
                    style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54),
                    decoration: const InputDecoration(
                        labelText: 'אימייל (לא ניתן לשינוי)',
                        border: OutlineInputBorder(),
                        filled: true)),
                const SizedBox(height: 20),
                const Divider(),
                const Text('החלפת סיסמה',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                    controller: _oldPasswordController,
                    enabled: !_isLoading,
                    obscureText: true,
                    style:
                        TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: const InputDecoration(
                        labelText: 'סיסמה נוכחית',
                        border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(
                    controller: _newPasswordController,
                    enabled: !_isLoading,
                    obscureText: true,
                    style:
                        TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: const InputDecoration(
                        labelText: 'סיסמה חדשה', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(
                    controller: _confirmPasswordController,
                    enabled: !_isLoading,
                    obscureText: true,
                    style:
                        TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: const InputDecoration(
                        labelText: 'אימות סיסמה חדשה',
                        border: OutlineInputBorder())),
              ],
            ),
          ),
        ),
        actions: [
          if (!_isLoading)
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ביטול')),
          ElevatedButton(
              onPressed: _isLoading ? null : _saveUser,
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('שמירה')),
        ],
      ),
    );
  }
}
