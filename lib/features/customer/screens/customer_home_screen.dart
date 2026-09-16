import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:save_a_bite/core/theme/app_colors.dart';
import 'package:save_a_bite/features/customer/controllers/customer_controller.dart';
import 'package:save_a_bite/features/auth/screens/login_screen.dart';
import 'package:save_a_bite/address_search_field.dart';
import 'package:save_a_bite/core/widgets/shared_settings_screen.dart';

import 'order_history_screen.dart';
import '../widgets/edit_user_dialog.dart';
import 'business_reviews_screen.dart';

import 'package:save_a_bite/backend/controllers/AuthController.dart';
import 'package:save_a_bite/backend/controllers/PackageController.dart';
import 'package:save_a_bite/backend/controllers/OrderController.dart';
import 'package:save_a_bite/backend/controllers/ProfileController.dart';
import 'package:save_a_bite/backend/data/models/package_model.dart';

/// The main dashboard screen for customers, supporting package browsing,
/// interactive map viewing, searching, and order management.
class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _currentBottomIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();

  double _currentMapLat = 31.7683;
  double _currentMapLng = 35.2137;
  bool _hasCenteredMapOnFirstLoad = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final profileController = context.read<ProfileController>();
      final userCity = profileController.currentUserData?.city;

      final initialCity =
          (userCity != null && userCity.isNotEmpty) ? userCity : 'ירושלים';

      context.read<CustomerController>().changeCity(initialCity);
      context.read<PackageController>().loadAvailablePackages(initialCity);
    });
  }

  /// Asynchronously queries Firestore to enrich raw packages with local business profile data.
  Future<List<Map<String, dynamic>>> _getEnrichedPackages(
      List<PackageModel> allPackages, String currentCity) async {
    if (allPackages.isEmpty) return [];
    try {
      final businessSnapshot =
          await FirebaseFirestore.instance.collection('BUSINESS').get();

      final Map<String, Map<String, dynamic>> localBusinesses = {};
      final String searchCity = currentCity.trim().toLowerCase();

      for (var doc in businessSnapshot.docs) {
        final dbCity =
            (doc.data()['city'] ?? '').toString().trim().toLowerCase();

        if (dbCity.contains(searchCity) || searchCity.contains(dbCity)) {
          localBusinesses[doc.id] = doc.data();
        }
      }

      List<Map<String, dynamic>> enriched = [];
      for (var pkg in allPackages) {
        if (localBusinesses.containsKey(pkg.businessId)) {
          enriched.add({
            'package': pkg,
            'business': localBusinesses[pkg.businessId],
          });
        }
      }
      return enriched;
    } catch (e) {
      return [];
    }
  }

  /// Displays an confirmation dialog for logging out and clears authentication session state.
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('התנתקות',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('האם אתה בטוח שברצונך לצאת מהחשבון?'),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ביטול')),
            ElevatedButton(
              onPressed: () async {
                await context.read<AuthController>().logout();
                if (context.mounted) {
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

  @override
  Widget build(BuildContext context) {
    final customerController = context.watch<CustomerController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppColors.deepBlue,
        automaticallyImplyLeading: false,
        title: const Text(
          'SAVE A BITE',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon:
                const Icon(Icons.account_circle, color: Colors.white, size: 28),
            onSelected: (value) {
              if (value == 'edit_user') {
                showDialog(
                    context: context, builder: (_) => const EditUserDialog());
              } else if (value == 'logout') {
                _confirmLogout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'edit_user', child: Text('עריכת פרטי משתמש')),
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
        child: _currentBottomIndex == 0
            ? _buildHomeContent(customerController, isDark)
            : _currentBottomIndex == 1
                ? const OrderHistoryScreen()
                : const SharedSettingsScreen(),
      ),
      bottomNavigationBar: Directionality(
        textDirection: TextDirection.rtl,
        child: BottomNavigationBar(
          currentIndex: _currentBottomIndex,
          selectedItemColor: AppColors.deepBlue,
          unselectedItemColor: Colors.grey,
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          onTap: (index) {
            setState(() {
              _currentBottomIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'דף הבית'),
            BottomNavigationBarItem(
                icon: Icon(Icons.history), label: 'היסטוריית חבילות'),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings), label: 'הגדרות'),
          ],
        ),
      ),
    );
  }

  /// Builds the main interactive home view containing address filters, search bar, and view toggle.
  Widget _buildHomeContent(CustomerController customerController, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: AddressSearchField(
                  isCityOnly: true,
                  onAddressSelected: (fullAddress, city, lat, lng) {
                    setState(() {
                      _currentMapLat = lat;
                      _currentMapLng = lng;
                      _hasCenteredMapOnFirstLoad = true;

                      try {
                        _mapController.move(LatLng(lat, lng), 13.5);
                      } catch (e) {
                        debugPrint('Map view not active yet: $e');
                      }
                    });

                    customerController.changeCity(city);
                    context
                        .read<PackageController>()
                        .loadAvailablePackages(city);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: 'חיפוש חופשי...',
                    hintStyle:
                        TextStyle(color: isDark ? Colors.white70 : Colors.grey),
                    fillColor: isDark ? AppColors.darkSurface : Colors.white,
                    filled: true,
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.accentBlue),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: isDark
                                ? Colors.transparent
                                : Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: isDark
                                ? Colors.transparent
                                : Colors.grey.shade300)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (value) {
                    customerController.updateSearchQuery(value);
                    context
                        .read<PackageController>()
                        .searchPackages(customerController.selectedCity, value);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: IconButton(
                  icon: Icon(
                    customerController.isMapView
                        ? Icons.view_list
                        : Icons.location_on,
                    color: AppColors.accentBlue,
                    size: 24,
                  ),
                  onPressed: () {
                    customerController.toggleView();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: customerController.isMapView
                ? _buildMobileMap(isDark)
                : _buildPackagesList(customerController, isDark),
          ),
        ],
      ),
    );
  }

  /// Constructs the interactive map view displaying localized business markers.
  Widget _buildMobileMap(bool isDark) {
    return Consumer<PackageController>(
      builder: (context, packageController, child) {
        final allPackages = packageController.availablePackages;
        final currentCity = context.read<CustomerController>().selectedCity;

        return FutureBuilder<List<Map<String, dynamic>>>(
            future: _getEnrichedPackages(allPackages, currentCity),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final enrichedPackages = snapshot.data ?? [];

              Map<String, List<PackageModel>> packagesByBusiness = {};
              Map<String, Map<String, dynamic>> businessDetails = {};

              for (var item in enrichedPackages) {
                final pkg = item['package'] as PackageModel;
                final biz = item['business'] as Map<String, dynamic>;
                final bizId = pkg.businessId;

                if (!packagesByBusiness.containsKey(bizId)) {
                  packagesByBusiness[bizId] = [];
                  businessDetails[bizId] = biz;
                }
                packagesByBusiness[bizId]!.add(pkg);
              }

              List<Marker> markers = [];
              for (var bizId in packagesByBusiness.keys) {
                final biz = businessDetails[bizId]!;
                final pkgs = packagesByBusiness[bizId]!;

                double lat = _currentMapLat;
                double lng = _currentMapLng;

                // Extract coordinates from server-stored GeoPoint reference
                if (biz['coordinates'] != null &&
                    biz['coordinates'] is GeoPoint) {
                  final geo = biz['coordinates'] as GeoPoint;
                  lat = geo.latitude;
                  lng = geo.longitude;
                } else if (biz['lat'] != null && biz['lng'] != null) {
                  lat = biz['lat'].toDouble();
                  lng = biz['lng'].toDouble();
                }

                markers.add(
                  Marker(
                    point: LatLng(lat, lng),
                    width: 60,
                    height: 60,
                    child: GestureDetector(
                      onTap: () {
                        _showBusinessPackagesBottomSheet(context, biz, pkgs,
                            context.read<CustomerController>());
                      },
                      child: const Icon(Icons.location_pin,
                          color: Colors.red, size: 45),
                    ),
                  ),
                );
              }

              return ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(_currentMapLat, _currentMapLng),
                    initialZoom: 13.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.saveabite.app',
                    ),
                    MarkerLayer(markers: markers),
                  ],
                ),
              );
            });
      },
    );
  }

  /// Displays a modal bottom sheet containing package offerings for a selected business marker.
  void _showBusinessPackagesBottomSheet(
      BuildContext context,
      Map<String, dynamic> business,
      List<PackageModel> packages,
      CustomerController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final businessName = business['businessName'] ?? 'עסק מקומי';

    showModalBottomSheet(
        context: context,
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('חבילות מבית $businessName',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepBlue)),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: packages.length,
                    itemBuilder: (context, index) {
                      final pkg = packages[index];
                      return ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          clipBehavior: Clip.hardEdge,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Builder(
                            builder: (context) {
                              final logoUrl =
                                  business['logoUrl']?.toString().trim();
                              if (logoUrl == null || logoUrl.isEmpty) {
                                return const Icon(Icons.fastfood,
                                    color: Colors.orange);
                              }
                              return Image.network(
                                logoUrl,
                                fit: BoxFit.cover,
                                width: 50,
                                height: 50,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.fastfood,
                                        color: Colors.orange),
                              );
                            },
                          ),
                        ),
                        title: Text(pkg.title,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black)),
                        subtitle: Text('₪${pkg.salePrice.toStringAsFixed(2)}',
                            style:
                                const TextStyle(color: AppColors.accentBlue)),
                        trailing: const Icon(Icons.arrow_forward_ios,
                            size: 16, color: Colors.grey),
                        onTap: () {
                          Navigator.pop(context);
                          _showOrderPopup(context, controller, {
                            'id': pkg.packageId,
                            'title': pkg.title,
                            'businessId': pkg.businessId,
                            'price': pkg.salePrice,
                            'pickupStart': pkg.pickupStart,
                            'pickupEnd': pkg.pickupEnd,
                          });
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        });
  }

  /// Builds the scrollable list view of available food packages.
  Widget _buildPackagesList(
      CustomerController customerController, bool isDark) {
    return Consumer<PackageController>(
      builder: (context, packageController, child) {
        final allPackages = packageController.availablePackages;

        if (packageController.isLoading) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.deepBlue));
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
            future: _getEnrichedPackages(
                allPackages, customerController.selectedCity),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final enrichedPackages = snapshot.data ?? [];

              if (enrichedPackages.isEmpty) {
                return Center(
                    child: Text('לא נמצאו חבילות זמינות באזורך',
                        style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54)));
              }

              return ListView.builder(
                itemCount: enrichedPackages.length,
                itemBuilder: (context, index) {
                  final item = enrichedPackages[index];
                  final pkg = item['package'] as PackageModel;
                  final biz = item['business'] as Map<String, dynamic>;

                  final businessName = biz['businessName'] ?? 'עסק מקומי';

                  return Card(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Container(
                        width: 60,
                        height: 60,
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8)),
                        child: Builder(
                          builder: (context) {
                            final bizData =
                                item['business'] as Map<String, dynamic>?;
                            final logoUrl =
                                bizData?['logoUrl']?.toString().trim();

                            if (logoUrl == null || logoUrl.isEmpty) {
                              return const Icon(Icons.fastfood,
                                  color: Colors.orange, size: 30);
                            }

                            return Image.network(
                              logoUrl,
                              fit: BoxFit.cover,
                              width: 60,
                              height: 60,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.fastfood,
                                      color: Colors.orange, size: 30),
                            );
                          },
                        ),
                      ),
                      title: Text(pkg.title,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BusinessReviewsScreen(
                                      businessId: pkg.businessId),
                                ),
                              );
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 2.0),
                              child: Text(
                                'מאת: $businessName (צפה בביקורות)',
                                style: const TextStyle(
                                  color: AppColors.accentBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                          Text('מחיר: ₪${pkg.salePrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: AppColors.accentBlue,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.grey),
                      onTap: () {
                        _showOrderPopup(context, customerController, {
                          'id': pkg.packageId,
                          'title': pkg.title,
                          'businessId': pkg.businessId,
                          'price': pkg.salePrice,
                          'pickupStart': pkg.pickupStart,
                          'pickupEnd': pkg.pickupEnd,
                        });
                      },
                    ),
                  );
                },
              );
            });
      },
    );
  }

  /// Displays an order confirmation dialog with terms acceptance validation,
  /// including pickup date and time details.
  void _showOrderPopup(
      BuildContext context, CustomerController customerController,
      [Map<String, dynamic>? pkg]) {
    customerController.setTermsChecked(false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String title =
        pkg != null ? pkg['title'] ?? 'חבילת מאפים' : 'חבילת מאפים';
    final dynamic price = pkg != null ? pkg['price'] ?? 25.0 : 25.0;
    final String packageId = pkg != null ? pkg['id'] ?? '' : '';

    // עיבוד התאריכים והשעות מתוך אובייקטי ה-DateTime
    String pickupDateStr = '';
    String startTimeStr = '';
    String endTimeStr = '';

    if (pkg != null && pkg['pickupStart'] != null && pkg['pickupEnd'] != null) {
      DateTime start = pkg['pickupStart'];
      DateTime end = pkg['pickupEnd'];

      pickupDateStr =
          "${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}/${start.year}";
      startTimeStr =
          "${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}";
      endTimeStr =
          "${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}";
    }

    if (packageId.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('שגיאה בזיהוי החבילה')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return Consumer<CustomerController>(
          builder: (context, controller, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Text('אישור הזמנה',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepBlue)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('מחיר לתשלום: ₪$price',
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 12),

                    // --- תצוגת תאריך ושעות איסוף ---
                    if (pickupDateStr.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 16, color: AppColors.accentBlue),
                          const SizedBox(width: 6),
                          Text('תאריך איסוף: $pickupDateStr',
                              style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    if (startTimeStr.isNotEmpty && endTimeStr.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.access_time,
                                size: 16, color: AppColors.accentBlue),
                            const SizedBox(width: 6),
                            Text('שעות: $startTimeStr - $endTimeStr',
                                style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    // ----------------------------------

                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Checkbox(
                          value: controller.isTermsChecked,
                          activeColor: AppColors.accentBlue,
                          onChanged: (value) {
                            controller.setTermsChecked(value ?? false);
                          },
                        ),
                        const Expanded(
                            child: Text('קראתי ואני מאשר את תנאי השימוש',
                                style: TextStyle(fontSize: 12))),
                      ],
                    ),
                  ],
                ),
                actionsAlignment: MainAxisAlignment.center,
                actions: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: controller.isTermsChecked
                            ? AppColors.deepBlue
                            : Colors.grey,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                    onPressed: controller.isTermsChecked
                        ? () async {
                            final customerUid =
                                FirebaseAuth.instance.currentUser?.uid ?? '';
                            final businessId = pkg?['businessId'] ?? '';

                            bool success = await context
                                .read<OrderController>()
                                .placeOrder(customerUid, packageId, businessId);

                            if (context.mounted) {
                              Navigator.pop(context);
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('ההזמנה בוצעה בהצלחה!',
                                          textAlign: TextAlign.right),
                                      backgroundColor: Colors.green),
                                );
                                context
                                    .read<PackageController>()
                                    .loadAvailablePackages(
                                        controller.selectedCity);
                              } else {
                                final error = context
                                    .read<OrderController>()
                                    .errorMessage;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('שגיאה: $error',
                                          textAlign: TextAlign.right),
                                      backgroundColor: Colors.red),
                                );
                              }
                            }
                          }
                        : null,
                    child: const Text('אישור',
                        style: TextStyle(color: Colors.white)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('ביטול',
                        style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
