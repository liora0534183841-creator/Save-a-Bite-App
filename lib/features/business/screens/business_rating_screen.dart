import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:save_a_bite/core/theme/app_colors.dart';
import 'package:save_a_bite/core/widgets/custom_text_field.dart';
import 'package:save_a_bite/backend/controllers/AuthController.dart';

/// A dialog widget that handles password reset requests and recovery email triggers.
class ResetPasswordDialog extends StatefulWidget {
  const ResetPasswordDialog({super.key});

  @override
  State<ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<ResetPasswordDialog> {
  // Controller to capture the user email input for password recovery
  final emailController = TextEditingController();

  @override
  void dispose() {
    // Clean up controller to prevent memory leaks
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();

    return AlertDialog(
      backgroundColor: AppColors.whiteCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'שחזור סיסמה',
        textAlign: TextAlign.center,
        style: TextStyle(
            color: AppColors.deepBlue,
            fontWeight: FontWeight.bold,
            fontSize: 20),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'אנא הזן את כתובת האימייל שלך לקבלת קישור לאיפוס הסיסמה:',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textDark, fontSize: 14),
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: emailController,
            hintText: 'אימייל לשחזור',
            prefixIcon: Icons.email_outlined,
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        if (!authController.isLoading)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול',
                style: TextStyle(color: AppColors.textLight)),
          ),
        ElevatedButton(
          onPressed: authController.isLoading
              ? null
              : () async {
                  final email = emailController.text.trim();

                  if (email.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('נא להזין אימייל',
                              textAlign: TextAlign.right),
                          backgroundColor: Colors.red),
                    );
                    return;
                  }

                  bool success = await context
                      .read<AuthController>()
                      .sendPasswordReset(email);

                  if (success) {
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('קישור לאיפוס נשלח לכתובת המייל',
                              textAlign: TextAlign.right),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    if (mounted) {
                      String errorMsg =
                          context.read<AuthController>().errorMessage ??
                              'שגיאה בשליחת מייל שחזור';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(errorMsg, textAlign: TextAlign.right),
                            backgroundColor: Colors.red),
                      );
                    }
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentBlue,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: authController.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text('שלח מייל לשחזור ססמא',
                  style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
