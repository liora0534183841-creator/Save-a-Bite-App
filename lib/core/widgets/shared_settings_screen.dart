import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:save_a_bite/core/theme/app_colors.dart';
import 'package:save_a_bite/core/theme/theme_provider.dart';

/// A shared settings screen utilized across all user roles (Customer, Business, Admin).
/// 
/// Consolidates application-wide configurations such as dynamic theme toggling,
/// and provides centralized access to legal documentation and application metadata.
class SharedSettingsScreen extends StatelessWidget {
  const SharedSettingsScreen({super.key});

  /// Displays the Terms of Service modal dialog.
  /// 
  /// Outlines legal responsibilities, system usage policies, and liability disclaimers
  /// regarding financial transactions and food quality.
  void _showTermsOfServiceDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'תנאי שימוש ופרטיות', 
            style: TextStyle(color: isDark ? AppColors.accentBlue : AppColors.deepBlue, fontWeight: FontWeight.bold)
          ),
          content: SingleChildScrollView(
            child: Text(
              'ברוכים הבאים למערכת SAVE A BITE. המערכת נועדה לצמצום בזבוז מזון ושיפור הקיימות.\n\n'
              '1. אחריות המשתמש: המשתמש מתחייב לספק פרטים נכונים בעת ההרשמה למערכת.\n\n'
              '2. הצלת מזון ואחריות טיב: מארזי המזון המוצעים הינם עודפי מזון טריים. בתי העסק נושאים באחריות המלאה והבלעדית על טיב המזון, תנאי אחסונו, וכשרותו.\n\n'
              '3. תשלום והתנערות מאחריות מסחרית: אפליקציית SAVE A BITE משמשת כפלטפורמת תיווך בלבד. התשלום בגין החבילות מבוצע ישירות מול בית העסק במעמד האיסוף. מפתחי ומנהלי האפליקציה אינם צד בעסקה ולא יישאו באחריות לכל מחלוקת כספית, טיב שירות או אי-אספקה מצד בית העסק.\n\n'
              '4. איסוף הזמנות: איסוף המזון יתבצע אך ורק בטווח השעות המוגדר על ידי העסק. אי הגעה במועד עשויה לגרור ביטול עסקה ואף חסימת הלקוח.\n',
              style: TextStyle(height: 1.5, fontSize: 14, color: isDark ? Colors.white70 : Colors.black87),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('סגור', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  /// Displays the general application information dialog.
  /// 
  /// Surfaces system versioning, underlying mission statement, and credits the development team.
  void _showAboutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'SAVE A BITE', 
            style: TextStyle(color: isDark ? AppColors.accentBlue : AppColors.deepBlue, fontWeight: FontWeight.bold, fontSize: 24),
            textAlign: TextAlign.center
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.eco_rounded, size: 50, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                'פלטפורמה טכנולוגית מתקדמת לניהול וצמצום עודפי מזון בבתי עסק.\n\n'
                'פותח ואופיין על ידי צוות הפיתוח:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.4, color: isDark ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 12),
              Text(
                'ליאורה לוי • הודיה כובאני • שירה גל\nרבקה אדרי • הדר ברששת',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? AppColors.accentBlue : AppColors.deepBlue),
              ),
              const Divider(height: 32),
              const Text('גרסת מערכת: 1.0.0 (Build 2026)', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('סגירה', style: TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0, bottom: 8.0, top: 16.0),
              child: Text(
                'הגדרות תצוגה ומערכת', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? AppColors.accentBlue : AppColors.deepBlue)
              ),
            ),
            Card(
              color: isDark ? AppColors.darkSurface : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: isDark ? Colors.transparent : Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.dark_mode_outlined, color: AppColors.accentBlue),
                    title: Text('מצב לילה', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                    subtitle: Text('שינוי צבעי הממשק לנוחות בחושך', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                    trailing: Switch(
                      value: themeProvider.isDarkMode,
                      activeThumbColor: AppColors.deepBlue,
                      onChanged: (value) {
                        themeProvider.toggleTheme(value);
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Padding(
              padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
              child: Text(
                'מידע ומשפטי', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? AppColors.accentBlue : AppColors.deepBlue)
              ),
            ),
            Card(
              color: isDark ? AppColors.darkSurface : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: isDark ? Colors.transparent : Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.gavel_outlined, color: AppColors.accentBlue),
                    title: Text('תנאי השימוש באפליקציה', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: () => _showTermsOfServiceDialog(context),
                  ),
                  Divider(height: 1, indent: 50, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded, color: AppColors.accentBlue),
                    title: Text('אודות SAVE A BITE', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                    subtitle: Text('פרטי צוות הפיתוח וגרסה', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: () => _showAboutDialog(context),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            const Center(
              child: Text(
                'SAVE A BITE © 2026\nAll Rights Reserved',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 1.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}