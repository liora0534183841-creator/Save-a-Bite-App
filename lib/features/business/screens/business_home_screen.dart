import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:save_a_bite/core/theme/app_colors.dart';
import 'package:save_a_bite/features/auth/screens/login_screen.dart';
import 'package:save_a_bite/features/business/widgets/add_package_dialog.dart';
import 'package:save_a_bite/features/business/widgets/edit_profile_dialogs.dart';
import 'package:save_a_bite/core/widgets/shared_settings_screen.dart';

// --- Backend Controllers Imports ---
import 'package:save_a_bite/backend/controllers/PackageController.dart';
import 'package:save_a_bite/backend/controllers/ReviewController.dart';
import 'package:save_a_bite/backend/controllers/AuthController.dart';
import 'package:save_a_bite/backend/controllers/ProfileController.dart';
import 'package:save_a_bite/backend/data/models/package_model.dart';
import 'dart:developer' as dev;

/// Main dashboard screen for business providers to manage packages, view orders, and monitor customer reviews.
class BusinessHomeScreen extends StatefulWidget {
  const BusinessHomeScreen({super.key});

  @override
  State<BusinessHomeScreen> createState() => _BusinessHomeScreenState();
}

class _BusinessHomeScreenState extends State<BusinessHomeScreen> {
  int _currentTabIndex = 0;
  String _searchPackageId = '';
  DateTimeRange? _selectedDateRange;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  /// Asynchronously loads business profile, active packages, and reviews for the authenticated provider.
  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    final profileCtrl = context.read<ProfileController>();
    final packageCtrl = context.read<PackageController>();
    final reviewCtrl = context.read<ReviewController>();

    // Always fetch fresh business profile data for the current authenticated user
    await profileCtrl.loadBusinessData(uid);

    final businessId = profileCtrl.currentBusinessData?.businessId;

    if (businessId != null && businessId.isNotEmpty) {
      await packageCtrl.loadBusinessDashboard(businessId);
      await reviewCtrl.loadBusinessReviews(businessId);
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// Enriches raw package items with associated order statuses and customer details concurrently.
  Future<List<Map<String, dynamic>>> _getEnrichedBusinessPackages(
      List<PackageModel> rawPackages) async {
    final futures = rawPackages.map((pkg) async {
      int sortCat = 0;
      String custName = 'Customer';
      String custPhone = 'N/A';
      String orderStatus = 'NONE';

      if (pkg.status != 'AVAILABLE') {
        try {
          final orderQuery = await FirebaseFirestore.instance
              .collection('ORDER')
              .where('packageId', isEqualTo: pkg.packageId)
              .limit(1)
              .get();

          if (orderQuery.docs.isNotEmpty) {
            final orderData = orderQuery.docs.first.data();
            orderStatus = orderData['status'] ?? 'PENDING';

            if (orderStatus.toUpperCase() == 'COMPLETED' ||
                orderStatus.toUpperCase() == 'COLLECTED') {
              sortCat = 2;
            } else {
              sortCat = 1;
            }

            final String custId = orderData['customerId'] ?? '';

            if (custId.isNotEmpty) {
              final userDoc = await FirebaseFirestore.instance
                  .collection('USER')
                  .doc(custId)
                  .get();

              if (userDoc.exists && userDoc.data() != null) {
                final userData = userDoc.data()!;

                final fName = userData['fullName']?.toString().trim() ?? '';
                if (fName.isNotEmpty) custName = fName;

                final phone = userData['phoneNumber']?.toString().trim() ?? '';
                if (phone.isNotEmpty) custPhone = phone;
              }
            }
          } else {
            sortCat = 3;
          }
        } catch (e) {
          dev.log('Error fetching enriched package data: $e',
              name: 'BusinessHomeScreen');
          sortCat = 3;
        }
      }

      return {
        'package': pkg,
        'sortCategory': sortCat,
        'customerName': custName,
        'customerPhone': custPhone,
        'orderStatus': orderStatus,
      };
    });

    List<Map<String, dynamic>> enriched = await Future.wait(futures);

    enriched.sort((a, b) {
      final catComparison =
          (a['sortCategory'] as int).compareTo(b['sortCategory'] as int);
      if (catComparison != 0) return catComparison;

      final dateA = (a['package'] as PackageModel).pickupStart;
      final dateB = (b['package'] as PackageModel).pickupStart;
      return dateB.compareTo(dateA);
    });

    return enriched;
  }

  /// Clears active search filters and temporal range constraints.
  void _clearFilters() {
    setState(() {
      _selectedDateRange = null;
      _searchPackageId = '';
    });
  }

  /// Opens localized date range picker widget for filtering items.
  Future<void> _pickDateRange() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.accentBlue,
                    surface: AppColors.darkSurface)
                : const ColorScheme.light(
                    primary: AppColors.deepBlue, onPrimary: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  /// Opens modal dialog for creating and uploading a new food package.
  void _openAddPackagePopup() {
    showDialog(
      context: context,
      builder: (context) => AddPackageDialog(
        nextId: 'חדש',
        onPackageAdded: (newPackage) {},
      ),
    ).then((_) {
      _loadDashboardData();
    });
  }

  /// Updates package status in the database repository.
  Future<void> _updatePackageStatus(String packageId, String newStatus) async {
    final businessId =
        context.read<ProfileController>().currentBusinessData?.businessId ?? '';
    if (businessId.isEmpty) return;

    setState(() => _isLoading = true);

    final success = await context
        .read<PackageController>()
        .updateStatus(packageId, newStatus, businessId);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('החבילה הוסרה בהצלחה', textAlign: TextAlign.right),
              backgroundColor: Colors.green),
        );
      } else {
        final error = context.read<PackageController>().errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('שגיאה בעדכון: $error', textAlign: TextAlign.right),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Prompts user for confirmation before terminating current session.
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('התנתקות',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('האם אתה בטוח שברצונך לצאת מהחשבון?'),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('ביטול')),
            ElevatedButton(
              onPressed: () async {
                final authController = context.read<AuthController>();
                final success = await authController.logout();

                if (success && mounted) {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                      (route) => false);
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

  /// Handles action selections from the profile popup menu.
  void _handleMenuSelection(String value) {
    if (value == 'logout') {
      _confirmLogout();
    } else if (value == 'edit_business') {
      showDialog(context: context, builder: (_) => const EditBusinessDialog());
    } else if (value == 'edit_user') {
      showDialog(context: context, builder: (_) => const EditUserDialog());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final profileData = context.watch<ProfileController>().currentBusinessData;
    final rawPackages = context.watch<PackageController>().businessPackages;
    final rawReviews = context.watch<ReviewController>().businessReviews;

    Widget tabContent;

    if (_isLoading) {
      tabContent = const Center(
          child: CircularProgressIndicator(color: AppColors.deepBlue));
    } else if (_currentTabIndex == 0) {
      tabContent = Column(
        children: [
          InkWell(
            onTap: _openAddPackagePopup,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accentBlue, width: 2),
              ),
              child: const Column(
                children: [
                  Icon(Icons.add_box_outlined,
                      size: 48, color: AppColors.accentBlue),
                  SizedBox(height: 8),
                  Text('העלאת חבילה חדשה',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentBlue)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4)
                ]),
            child: Column(
              children: [
                TextField(
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                      hintText: 'חיפוש לפי מס\' מזהה החבילה',
                      hintStyle: TextStyle(
                          color: isDark ? Colors.white70 : Colors.grey),
                      prefixIcon:
                          const Icon(Icons.search, color: AppColors.deepBlue),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12)),
                  onChanged: (value) =>
                      setState(() => _searchPackageId = value.trim()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickDateRange,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_selectedDateRange == null
                            ? 'חיפוש לפי טווח תאריכים'
                            : '${DateFormat('dd/MM/yy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yy').format(_selectedDateRange!.end)}'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedDateRange == null
                                ? (isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade200)
                                : AppColors.accentBlue,
                            foregroundColor: _selectedDateRange == null
                                ? (isDark ? Colors.white : Colors.black87)
                                : Colors.white,
                            elevation: 0,
                            alignment: Alignment.centerRight),
                      ),
                    ),
                    if (_selectedDateRange != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                          icon: const Icon(Icons.clear, color: Colors.red),
                          onPressed: _clearFilters),
                    ]
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _getEnrichedBusinessPackages(rawPackages),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final enrichedPackages = snapshot.data ?? [];

                  final filteredPackages = enrichedPackages.where((item) {
                    final pkg = item['package'] as PackageModel;

                    final shortId = pkg.packageId.length >= 6
                        ? pkg.packageId.substring(0, 6)
                        : pkg.packageId;
                    final matchesId = shortId.contains(_searchPackageId) ||
                        pkg.packageId.contains(_searchPackageId);

                    bool matchesDate = true;
                    if (_selectedDateRange != null) {
                      final pkgDate = pkg.pickupStart;
                      final start = _selectedDateRange!.start;
                      final end = _selectedDateRange!.end;

                      final startOfDay =
                          DateTime(start.year, start.month, start.day);
                      final endOfDay =
                          DateTime(end.year, end.month, end.day, 23, 59, 59);

                      matchesDate = pkgDate.isAfter(startOfDay
                              .subtract(const Duration(seconds: 1))) &&
                          pkgDate.isBefore(
                              endOfDay.add(const Duration(seconds: 1)));
                    }
                    return matchesId && matchesDate;
                  }).toList();

                  if (filteredPackages.isEmpty) {
                    return const Center(
                        child: Text('לא נמצאו חבילות לפי הסינון המבוקש.'));
                  }

                  return ListView.builder(
                    itemCount: filteredPackages.length,
                    itemBuilder: (context, index) {
                      final item = filteredPackages[index];
                      final pkg = item['package'] as PackageModel;
                      final sortCat = item['sortCategory'] as int;
                      final customerName = item['customerName'] as String;
                      final customerPhone = item['customerPhone'] as String;

                      final isAvailable = sortCat == 0;
                      final isPending = sortCat == 1;
                      final isCollected = sortCat == 2;

                      final shortPkgId = pkg.packageId.length >= 6
                          ? pkg.packageId.substring(0, 6)
                          : pkg.packageId;

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 5)
                          ],
                          border: !isAvailable
                              ? Border.all(
                                  color: Colors.grey.shade400, width: 2)
                              : null,
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Opacity(
                                opacity: 0.05,
                                child: Icon(Icons.restaurant,
                                    size: 100, color: Colors.grey.shade400),
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  clipBehavior: Clip.hardEdge,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Builder(
                                    builder: (context) {
                                      final logoImage =
                                          (profileData?.logoUrl != null &&
                                                  profileData!.logoUrl
                                                      .trim()
                                                      .isNotEmpty)
                                              ? profileData.logoUrl
                                              : null;

                                      if (logoImage == null) {
                                        return Icon(Icons.shopping_bag,
                                            size: 40,
                                            color: isAvailable
                                                ? Colors.brown
                                                : Colors.grey);
                                      }

                                      return Image.network(
                                        logoImage,
                                        fit: BoxFit.cover,
                                        width: 80,
                                        height: 80,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(Icons.shopping_bag,
                                                    size: 40,
                                                    color: isAvailable
                                                        ? Colors.brown
                                                        : Colors.grey),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(pkg.title,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: isDark
                                                  ? Colors.white
                                                  : AppColors.deepBlue)),
                                      Text('מק"ט: #$shortPkgId',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.black87)),
                                      Text(
                                          'תאריך: ${DateFormat('dd/MM/yyyy').format(pkg.pickupStart)}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey)),
                                      Text(
                                          pkg.salePrice == 0
                                              ? 'חינם!'
                                              : '₪${pkg.salePrice}',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isAvailable
                                                  ? AppColors.accentBlue
                                                  : Colors.grey)),
                                      if (isPending)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                              'הוזמן ע"י: $customerName\nטלפון: $customerPhone',
                                              style: TextStyle(
                                                  color: Colors.orange.shade700,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12)),
                                        ),
                                      if (isCollected)
                                        const Padding(
                                          padding: EdgeInsets.only(top: 8.0),
                                          child: Text('נאסף',
                                              style: TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13)),
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    if (isAvailable) ...[
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: Colors.red),
                                        tooltip: 'מחיקת חבילה מהמדף',
                                        onPressed: () => _updatePackageStatus(
                                            pkg.packageId, 'UNAVAILABLE'),
                                      ),
                                    ] else if (sortCat == 3) ...[
                                      const Chip(
                                        label: Text('לא זמינה',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold)),
                                        backgroundColor: Colors.grey,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ],
                                )
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
          ),
        ],
      );
    } else if (_currentTabIndex == 1) {
      final double averageRating = profileData?.rating.toDouble() ?? 0.0;

      tabContent = SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profileData?.businessName ?? 'שם העסק לא הוזן',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.accentBlue
                            : AppColors.deepBlue)),
                Text(
                    '${profileData?.streetAddress ?? ''}, ${profileData?.city ?? ''}',
                    style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.grey)),
                const Divider(height: 24),
              ],
            ),
            Row(
              children: [
                const Text('דירוג ממוצע של העסק: ',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${averageRating.toStringAsFixed(1)} ',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber)),
                const Icon(Icons.star, color: Colors.amber),
              ],
            ),
            const SizedBox(height: 24),
            Text('מה לקוחות אחרים מספרים עלינו:',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.deepBlue)),
            const SizedBox(height: 12),
            rawReviews.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                        child: Text("טרם התקבלו ביקורות עבור עסק זה.",
                            style: TextStyle(color: Colors.grey))),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: rawReviews.length,
                    itemBuilder: (context, index) {
                      final review = rawReviews[index];
                      return FutureBuilder<QuerySnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('USER')
                              .where('uid', isEqualTo: review.uid)
                              .limit(1)
                              .get(),
                          builder: (context, snapshot) {
                            String displayName = 'לקוח/ה המערכת';

                            if (snapshot.hasData &&
                                snapshot.data!.docs.isNotEmpty) {
                              final userData = snapshot.data!.docs.first.data()
                                  as Map<String, dynamic>;
                              final fullName =
                                  userData['fullName']?.toString().trim() ?? '';
                              if (fullName.isNotEmpty) {
                                displayName = fullName;
                              }
                            }

                            return Card(
                              color:
                                  isDark ? AppColors.darkSurface : Colors.white,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                title: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(displayName,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black)),
                                    Row(
                                        children: List.generate(
                                            review.rating,
                                            (i) => const Icon(Icons.star,
                                                size: 16,
                                                color: Colors.amber))),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: Text(review.comment,
                                      style: TextStyle(
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black87)),
                                ),
                              ),
                            );
                          });
                    },
                  ),
          ],
        ),
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
        title: const Text('SAVE A BITE',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<String>(
            icon:
                const Icon(Icons.account_circle, color: Colors.white, size: 30),
            onSelected: _handleMenuSelection,
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'edit_business', child: Text('עריכת עסק')),
              const PopupMenuItem(
                  value: 'edit_user', child: Text('עריכת פרטים אישיים')),
              const PopupMenuDivider(),
              const PopupMenuItem(
                  value: 'logout',
                  child: Text('התנתקות', style: TextStyle(color: Colors.red))),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(padding: const EdgeInsets.all(16.0), child: tabContent),
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
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'דף הבית'),
            BottomNavigationBarItem(
                icon: Icon(Icons.star_rate), label: 'דירוגים'),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings), label: 'הגדרות'),
          ],
        ),
      ),
    );
  }
}
