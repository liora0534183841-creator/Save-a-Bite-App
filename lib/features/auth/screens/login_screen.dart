import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:save_a_bite/core/theme/app_colors.dart';
import 'package:save_a_bite/core/widgets/custom_text_field.dart';
import 'package:save_a_bite/backend/controllers/AuthController.dart';
import 'register_screen.dart';
import '../widgets/reset_password_dialog.dart';

import 'package:save_a_bite/features/customer/screens/customer_home_screen.dart';
import 'package:save_a_bite/features/business/screens/business_home_screen.dart';
import 'package:save_a_bite/features/admin/screens/admin_home_screen.dart';

/// A screen widget that handles user authentication and credential verification (Login).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers to capture email and password input fields
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    // Clean up controllers to prevent memory leaks upon widget destruction
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine current theme brightness for adaptive color styling
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- Header Section: Logo and Branding ---
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    shape: BoxShape.circle),
                child: const Icon(Icons.restaurant_menu,
                    size: 65, color: AppColors.accentBlue),
              ),
              const SizedBox(height: 16),
              Text(
                'SAVE A BITE',
                style: TextStyle(
                    color: isDark ? Colors.white : AppColors.deepBlue,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5),
              ),
              const SizedBox(height: 6),
              const Text("!Let's save food together",
                  style: TextStyle(
                      color: AppColors.accentBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 40),

              // --- Authentication Form Container ---
              Consumer<AuthController>(
                builder: (context, controller, child) {
                  return Directionality(
                    textDirection: TextDirection.rtl,
                    child: Column(
                      children: [
                        CustomTextField(
                          controller: emailController,
                          hintText: 'אימייל',
                          prefixIcon: Icons.email_outlined,
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          controller: passwordController,
                          hintText: 'סיסמה',
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                        ),

                        // Password Reset Trigger Link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              showDialog(
                                  context: context,
                                  builder: (_) => const ResetPasswordDialog());
                            },
                            child: const Text('שכחת סיסמה?',
                                style: TextStyle(
                                    color: AppColors.accentBlue,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline)),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // --- Submit Login Button Execution ---
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: controller.isLoading
                                ? null
                                : () async {
                                    final inputEmail = emailController.text
                                        .trim()
                                        .toLowerCase();
                                    final inputPassword =
                                        passwordController.text;

                                    if (inputEmail.isEmpty ||
                                        inputPassword.isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'נא למלא אימייל וסיסמה',
                                                textAlign: TextAlign.right),
                                            backgroundColor: Colors.red),
                                      );
                                      return;
                                    }

                                    final success = await controller.login(
                                        inputEmail, inputPassword);

                                    if (success) {
                                      emailController.clear();
                                      passwordController.clear();

                                      if (context.mounted) {
                                        final userRole = controller.userRole;

                                        // Route user based on authorized permission role
                                        if (userRole == 'ADMIN') {
                                          Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      const AdminHomeScreen()));
                                        } else if (userRole == 'PROV') {
                                          Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      const BusinessHomeScreen()));
                                        } else if (userRole == 'CUST') {
                                          Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      const CustomerHomeScreen()));
                                        } else {
                                          Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      const CustomerHomeScreen()));
                                        }
                                      }
                                    } else {
                                      if (context.mounted) {
                                        String errorMsg =
                                            controller.errorMessage ??
                                                'ההתחברות נכשלה. נסה שוב.';
                                        final lowerError =
                                            errorMsg.toLowerCase();

                                        // Map technical server errors to user-friendly notifications
                                        if (lowerError
                                                .contains('badly formatted') ||
                                            lowerError
                                                .contains('invalid-email')) {
                                          errorMsg =
                                              'כתובת האימייל שהוזנה אינה תקינה.';
                                        } else if (lowerError.contains(
                                                'invalid-credential') ||
                                            lowerError
                                                .contains('user-not-found') ||
                                            lowerError
                                                .contains('wrong-password') ||
                                            lowerError.contains(
                                                'auth credential is incorrect')) {
                                          errorMsg =
                                              'אימייל או סיסמה שגויים. נסה שוב.';
                                        } else if (lowerError.contains(
                                            'network-request-failed')) {
                                          errorMsg =
                                              'שגיאת תקשורת. אנא בדוק את החיבור לאינטרנט.';
                                        } else if (lowerError
                                            .contains('too-many-requests')) {
                                          errorMsg =
                                              'יותר מדי ניסיונות כשלים. נסה שוב מאוחר יותר.';
                                        } else {
                                          errorMsg =
                                              'שגיאה בהתחברות. אנא ודא שהפרטים נכונים.';
                                        }

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(errorMsg,
                                                  textAlign: TextAlign.right,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              backgroundColor: Colors.red),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isDark ? AppColors.darkSurface : Colors.white,
                              foregroundColor: AppColors.accentBlue,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                            ),
                            child: controller.isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                        color: AppColors.accentBlue,
                                        strokeWidth: 2.5))
                                : const Text('כניסה לחשבון',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 25),

              // --- Registration Navigation Link ---
              TextButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen()));
                },
                child: const Text(
                  'אין לך חשבון? הרשמה למערכת',
                  style: TextStyle(
                    color: AppColors.accentBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
