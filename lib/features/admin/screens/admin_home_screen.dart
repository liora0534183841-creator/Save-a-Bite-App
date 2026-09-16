import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:web/web.dart' as web;

import 'package:save_a_bite/core/theme/app_colors.dart';
import 'package:save_a_bite/features/auth/screens/login_screen.dart';
import 'package:save_a_bite/core/widgets/shared_settings_screen.dart';

import 'package:save_a_bite/backend/controllers/AuthController.dart';
import 'package:save_a_bite/backend/controllers/AdminController.dart';

/// Local wrapper class for AdminController to resolve context scoping constraints.
class LocalAdminController extends ChangeNotifier with AdminController {}

/// The primary dashboard for the Administrator role.
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentTabIndex = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingBusinesses = [];

  final LocalAdminController _adminCtrl = LocalAdminController();

  @override
  void initState() {
    super.initState();
    _fetchPendingBusinesses();
  }

  /// Asynchronously queries the Firestore collection for pending business documents.
  Future<void> _fetchPendingBusinesses() async {
    setState(() => _isLoading = true);

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('BUSINESS')
          .where('v_status', isEqualTo: 'PEND')
          .get();

      final fetchedList = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'businessId': doc.id,
          'ownerUid': data['ownerUid'] ?? '',
          'name': data['businessName'] ?? 'עסק ללא שם',
          'owner': data['ownerUid'] != null ? 'ID: ${data['ownerUid']}' : 'N/A',
          'documentType': 'מסמכי רישוי עסק',
          'licenseUrl': data['licenseUrl'] ?? '',
        };
      }).toList();

      if (mounted) {
        setState(() {
          _pendingBusinesses = fetchedList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e', textAlign: TextAlign.right),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Validates URL string and opens verification documents securely in a new browser tab.
  void _viewDocument(String businessName, String docType, String licenseUrl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isValidUrl = licenseUrl.isNotEmpty &&
        (licenseUrl.startsWith('http://') || licenseUrl.startsWith('https://'));

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('מסמך: $businessName',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('סוג מסמך: $docType'),
              const SizedBox(height: 24),
              if (!isValidUrl)
                const Text('הקישור לקובץ בשרת שגוי או ריק.',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold))
              else
                ElevatedButton.icon(
                  onPressed: () {
                    web.window.open(licenseUrl, '_blank');
                  },
                  icon: const Icon(Icons.open_in_new, color: Colors.white),
                  label: const Text('פתח מסמך',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('סגירה', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  /// Updates target business registration status to approved ('APPR') in the backend repository.
  Future<void> _approveBusiness(int index) async {
    final business = _pendingBusinesses[index];
    setState(() => _isLoading = true);

    final success = await _adminCtrl.updateBusinessRegistrationStatus(
        business['businessId'], business['ownerUid'], 'APPR');

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        setState(() {
          _pendingBusinesses.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('העסק אושר בהצלחה בשרת!', textAlign: TextAlign.right),
              backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Server error: ${_adminCtrl.errorMessage}',
                  textAlign: TextAlign.right),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Updates target business registration status to rejected ('REJ') in the backend repository.
  Future<void> _rejectBusiness(int index, String reason) async {
    final business = _pendingBusinesses[index];
    setState(() => _isLoading = true);

    final success = await _adminCtrl.updateBusinessRegistrationStatus(
        business['businessId'], business['ownerUid'], 'REJ');

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        setState(() {
          _pendingBusinesses.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('בקשת העסק נדחתה והוסרה.', textAlign: TextAlign.right),
              backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Server error: ${_adminCtrl.errorMessage}',
                  textAlign: TextAlign.right),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Displays interactive dialog prompting administrator for a mandatory rejection justification.
  void _promptRejectReason(int index) {
    final business = _pendingBusinesses[index];
    final TextEditingController reasonController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('דחיית עסק: ${business['name']}',
              style: const TextStyle(
                  color: Colors.red, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('נא להזין סיבת אי-אישור:'),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'לדוגמה: מסמך מטושטש...',
                  hintStyle:
                      TextStyle(color: isDark ? Colors.white70 : Colors.grey),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ביטול', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                        content: Text('חובה להזין סיבת דחייה',
                            textAlign: TextAlign.right),
                        backgroundColor: Colors.red),
                  );
                  return;
                }
                Navigator.pop(dialogContext);
                await _rejectBusiness(index, reasonController.text.trim());
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child:
                  const Text('דחה עסק', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  /// Terminates active user session and routes back to the authentication login screen.
  void _confirmLogout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('התנתקות',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('האם אתה בטוח שברצונך לצאת?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ביטול', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await context.read<AuthController>().logout();

                if (success && mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('התנתק', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget tabContent;

    if (_isLoading && _pendingBusinesses.isEmpty) {
      tabContent = const Center(
          child: CircularProgressIndicator(color: AppColors.deepBlue));
    } else if (_currentTabIndex == 0) {
      tabContent = _pendingBusinesses.isEmpty
          ? const Center(
              child: Text('אין כרגע עסקים הממתינים לאישור.',
                  style: TextStyle(fontSize: 16)))
          : ListView.builder(
              itemCount: _pendingBusinesses.length,
              itemBuilder: (context, index) {
                final business = _pendingBusinesses[index];
                return Card(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('שם העסק: ${business['name']}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: isDark
                                    ? AppColors.accentBlue
                                    : AppColors.deepBlue)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isLoading
                                    ? null
                                    : () => _viewDocument(
                                        business['name'],
                                        business['documentType'],
                                        business['licenseUrl']),
                                icon: const Icon(Icons.remove_red_eye),
                                label: const Text('צפייה במסמך'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.check_circle,
                                  color: Colors.green, size: 36),
                              onPressed: _isLoading
                                  ? null
                                  : () => _approveBusiness(index),
                              tooltip: 'אישור עסק',
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel,
                                  color: Colors.red, size: 36),
                              onPressed: _isLoading
                                  ? null
                                  : () => _promptRejectReason(index),
                              tooltip: 'דחיית עסק',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
    } else {
      tabContent = const SharedSettingsScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppColors.deepBlue,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text('SAVE A BITE - מנהל',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<String>(
            icon:
                const Icon(Icons.account_circle, color: Colors.white, size: 28),
            onSelected: (value) {
              if (value == 'logout') {
                _confirmLogout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Text('התנתקות', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            children: [
              tabContent,
              if (_isLoading && _pendingBusinesses.isNotEmpty)
                Container(
                  color: Colors.black.withValues(alpha: 0.1),
                  child: const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.deepBlue)),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Directionality(
        textDirection: TextDirection.rtl,
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: (index) => setState(() => _currentTabIndex = index),
          selectedItemColor: AppColors.deepBlue,
          unselectedItemColor: Colors.grey,
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.domain_verification), label: 'אישורים'),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings), label: 'הגדרות'),
          ],
        ),
      ),
    );
  }
}
