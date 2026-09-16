import 'package:flutter/material.dart';
import 'package:save_a_bite/core/theme/app_colors.dart';

/// A settings screen widget that displays application configuration options,
/// terms of use modal dialog triggers, and version information.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'הגדרות האפליקציה',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.deepBlue),
          ),
          const SizedBox(height: 20),

          // Display and Theme Configuration Tile
          ListTile(
            leading:
                const Icon(Icons.palette_outlined, color: AppColors.accentBlue),
            title: const Text('הגדרות תצוגה (עיצוב וצבעים)'),
            subtitle: const Text('יוגדר בהמשך המערכת'),
            onTap: () {},
          ),
          const Divider(),

          // Terms of Use Dialog Trigger Tile
          ListTile(
            leading: const Icon(Icons.description_outlined,
                color: AppColors.accentBlue),
            title: const Text('תנאי השימוש באפליקציה'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('תנאי השימוש'),
                  content: const Text(
                      'כאן יופיעו תנאי השימוש המלאים של SAVE A BITE בהמשך הפיתוח.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('סגור'))
                  ],
                ),
              );
            },
          ),
          const Divider(),

          // About Application Information Tile
          ListTile(
            leading:
                const Icon(Icons.info_outline, color: AppColors.accentBlue),
            title: const Text('אודות SAVE A BITE'),
            subtitle: const Text('גרסה 1.0.0'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
