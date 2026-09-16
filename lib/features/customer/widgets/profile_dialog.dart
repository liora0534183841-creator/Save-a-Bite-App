import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:save_a_bite/core/theme/app_colors.dart';
import 'package:save_a_bite/backend/controllers/AuthController.dart';
import 'package:save_a_bite/backend/controllers/ProfileController.dart';
import 'package:save_a_bite/features/auth/screens/login_screen.dart';

/// A legacy dialog widget designed to display user or business profile information.
/// Superseded by [EditUserDialog] for active editing workflows but retained for reference.
class ProfileDialog extends StatelessWidget {
  const ProfileDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final userData = profileProvider.currentUserData;
    final bizData = profileProvider.currentBusinessData;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Header Icon and Title Section ---
              const Icon(Icons.account_circle,
                  size: 70, color: AppColors.accentBlue),
              const SizedBox(height: 10),
              Text(
                'פרטי פרופיל',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.accentBlue : AppColors.deepBlue),
              ),
              Divider(
                  thickness: 1.2,
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
              const SizedBox(height: 10),

              // --- Dynamic Profile Data Rendering ---
              if (profileProvider.isLoading)
                const CircularProgressIndicator(color: AppColors.deepBlue)
              else if (userData != null) ...[
                _buildProfileRow(
                    Icons.person, 'שם:', userData.fullName, isDark),
                _buildProfileRow(
                    Icons.email, 'אימייל:', userData.email, isDark),
                _buildProfileRow(
                    Icons.phone, 'טלפון:', userData.phoneNumber, isDark),
                _buildProfileRow(
                    Icons.location_city, 'עיר:', userData.city, isDark),
              ] else if (bizData != null) ...[
                _buildProfileRow(
                    Icons.business, 'שם עסק:', bizData.businessName, isDark),
                _buildProfileRow(
                    Icons.phone, 'טלפון עסק:', bizData.phoneNumber, isDark),
                _buildProfileRow(
                    Icons.location_city, 'עיר:', bizData.city, isDark),
                _buildProfileRow(
                    Icons.map, 'כתובת:', bizData.streetAddress, isDark),
              ] else
                const Text('לא נמצאו נתונים להצגה.',
                    style: TextStyle(color: Colors.grey)),

              const SizedBox(height: 20),
              Divider(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),

              // --- Action Buttons Footer ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      // TODO: Implement navigation or modal trigger for profile editing
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('ערוך פרטים'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _showLogoutConfirmation(context);
                    },
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('התנתק'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper method to construct standardized rows for displaying profile fields.
  Widget _buildProfileRow(
      IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon,
              color: isDark ? Colors.white70 : AppColors.deepBlue, size: 22),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(value.isNotEmpty ? value : 'לא הוזן',
                style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black87),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  /// Displays a confirmation dialog to verify user logout intent.
  void _showLogoutConfirmation(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Text('התנתקות מהמערכת',
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold)),
            content: Text(
                'הנך עומד להתנתק מאפליקציית SAVE A BITE.\nהאם אתה בטוח שברצונך לצאת?',
                style:
                    TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child:
                    const Text('ביטול', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  final authController = dialogContext.read<AuthController>();
                  final success = await authController.logout();

                  if (success && dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                      (Route<dynamic> route) => false,
                    );
                  }
                },
                child: const Text('אישור יציאה',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }
}
