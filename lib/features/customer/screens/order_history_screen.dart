import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:save_a_bite/core/theme/app_colors.dart';
import 'package:save_a_bite/backend/controllers/OrderController.dart';
import 'package:save_a_bite/backend/controllers/ReviewController.dart';
import 'package:save_a_bite/features/customer/screens/business_reviews_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Screen responsible for managing and displaying the customer's order history,
/// handling filtering by order number and date range, navigating to store locations, and submitting reviews.
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  String _searchOrderNumber = '';
  DateTimeRange? _selectedDateRange;
  List<Map<String, dynamic>> _allOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrdersFromBackend();
    });
  }

  /// Fetches customer order history asynchronously from the backend repository.
  Future<void> _loadOrdersFromBackend() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    await context.read<OrderController>().loadCustomerHistory(uid);

    if (mounted) {
      setState(() {
        _allOrders = context.read<OrderController>().orderHistory.map((model) {
          final map = model.toMap();
          return {
            ...map,
            'id': model.orderId,
            'date': model.createdAt,
            'businessId': map['businessId'] ?? '',
            'packageId': map['packageId'] ?? '',
            'status': map['status'] ?? 'PENDING',
            'hasReview': map['hasReview'] ?? false,
            'title': map['title'] ?? 'חבילת מאפים',
            'price': map['price'] ?? 0,
          };
        }).toList();
        _isLoading = false;
      });
    }
  }

  /// Retrieves business and package metadata concurrently for individual order cards.
  Future<Map<String, dynamic>> _fetchOrderDetails(
      String businessId, String packageId) async {
    final Map<String, dynamic> results = {};

    if (businessId.isNotEmpty) {
      final bDoc = await FirebaseFirestore.instance
          .collection('BUSINESS')
          .doc(businessId)
          .get();
      results['business'] = bDoc.data();
    }

    if (packageId.isNotEmpty) {
      final pDoc = await FirebaseFirestore.instance
          .collection('PACKAGE')
          .doc(packageId)
          .get();
      results['package'] = pDoc.data();
    }

    return results;
  }

  /// Launches external mapping application for physical store navigation.
  Future<void> _navigateToGoogleMaps(String city, String streetAddress) async {
    if (streetAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('אין כתובת זמינה', textAlign: TextAlign.right)));
      return;
    }

    final String fullAddress = '$streetAddress, $city';
    final Uri googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(fullAddress)}');

    try {
      if (kIsWeb) {
        await launchUrl(googleMapsUrl);
      } else {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('לא ניתן לפתוח את אפליקציית הניווט',
                textAlign: TextAlign.right)));
      }
    }
  }

  /// Clears active search parameters and temporal filter range.
  void _clearFilters() {
    setState(() {
      _selectedDateRange = null;
      _searchOrderNumber = '';
    });
  }

  /// Opens localized date range picker widget for temporal filtering.
  Future<void> _pickDateRange() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('he', 'IL'),
      saveText: 'אישור ושמירה',
      helpText: 'בחירת טווח תאריכים לחיפוש',
      fieldStartLabelText: 'תאריך התחלה',
      fieldEndLabelText: 'תאריך סיום',
      initialEntryMode: DatePickerEntryMode.calendar,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.accentBlue,
                    surface: AppColors.darkSurface)
                : const ColorScheme.light(primary: AppColors.deepBlue),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 480, maxHeight: 580),
                child: child!,
              ),
            ),
          ),
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  /// Renders review submission dialog interface for rating completed orders.
  void _showReviewDialog(Map<String, dynamic> order, String businessName) {
    int selectedRating = 0;
    final TextEditingController reviewController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: Text('איך היה ב$businessName?',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.deepBlue)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('נשמח לשמוע על החוויה שלך:',
                        style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < selectedRating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 36,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              selectedRating = index + 1;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: reviewController,
                      maxLines: 3,
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        hintText: 'ספר לנו עוד ...',
                        hintStyle: TextStyle(
                            color: isDark ? Colors.white70 : Colors.grey),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                actionsAlignment: MainAxisAlignment.spaceBetween,
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('ביטול',
                        style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    onPressed: selectedRating > 0
                        ? () async {
                            bool success = await context
                                .read<ReviewController>()
                                .submitReview(
                                  uid: FirebaseAuth.instance.currentUser?.uid ??
                                      '',
                                  businessId: order['businessId'],
                                  orderId: order['id'],
                                  ratingScore: selectedRating,
                                  reviewText: reviewController.text,
                                );

                            if (context.mounted && success) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'תודה על הדירוג! הביקורת נשמרה בהצלחה.',
                                        textAlign: TextAlign.right),
                                    backgroundColor: Colors.green),
                              );
                              _loadOrdersFromBackend();
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepBlue,
                      disabledBackgroundColor:
                          isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('שליחת ביקורת'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter orders based on identifier search and temporal range constraints
    final filteredOrders = _allOrders.where((order) {
      final matchesOrderNumber =
          order['id'].toString().contains(_searchOrderNumber);
      bool matchesDateRange = true;

      if (_selectedDateRange != null) {
        final orderDate = order['date'] as DateTime;
        final start = _selectedDateRange!.start;
        final end = _selectedDateRange!.end;

        final startOfDay = DateTime(start.year, start.month, start.day);
        final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);

        matchesDateRange = orderDate
                .isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
            orderDate.isBefore(endOfDay.add(const Duration(seconds: 1)));
      }
      return matchesOrderNumber && matchesDateRange;
    }).toList();

    // Hierarchical sort execution:
    // Category 1: Uncollected orders (top priority)
    // Category 2: Collected orders missing review
    // Category 3: Collected orders with completed review (lowest priority)
    // Secondary condition: Descending date sequence within identical categories
    filteredOrders.sort((a, b) {
      final statusA = a['status']?.toString().toUpperCase() ?? '';
      final statusB = b['status']?.toString().toUpperCase() ?? '';
      final bool isCollectedA =
          statusA == 'COMPLETED' || statusA == 'COLLECTED';
      final bool isCollectedB =
          statusB == 'COMPLETED' || statusB == 'COLLECTED';
      final bool hasReviewA = a['hasReview'] == true;
      final bool hasReviewB = b['hasReview'] == true;

      int getCategory(bool isCollected, bool hasReview) {
        if (!isCollected) return 1;
        if (!hasReview) return 2;
        return 3;
      }

      final catA = getCategory(isCollectedA, hasReviewA);
      final catB = getCategory(isCollectedB, hasReviewB);

      if (catA != catB) return catA.compareTo(catB);

      final dateA = a['date'] as DateTime;
      final dateB = b['date'] as DateTime;
      return dateB.compareTo(dateA);
    });

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'היסטוריית הזמנות',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.deepBlue),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4)
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        hintText: 'חיפוש לפי מספר חבילה',
                        hintStyle: TextStyle(
                            color: isDark ? Colors.white70 : Colors.grey),
                        prefixIcon: const Icon(Icons.numbers,
                            color: AppColors.accentBlue),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (value) =>
                          setState(() => _searchOrderNumber = value.trim()),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickDateRange,
                            icon: const Icon(Icons.calendar_month),
                            label: Text(_selectedDateRange == null
                                ? 'סינון לפי טווח תאריכים'
                                : '${DateFormat('dd/MM/yy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yy').format(_selectedDateRange!.end)}'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200,
                              foregroundColor:
                                  isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        if (_selectedDateRange != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: IconButton(
                              icon: const Icon(Icons.clear, color: Colors.red),
                              tooltip: 'ביטול סינון תאריכים',
                              onPressed: _clearFilters,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredOrders.isEmpty
                        ? Center(
                            child: Text('לא נמצאו הזמנות.',
                                style: TextStyle(
                                    color:
                                        isDark ? Colors.white : Colors.black)))
                        : ListView.builder(
                            itemCount: filteredOrders.length,
                            itemBuilder: (context, index) {
                              final order = filteredOrders[index];
                              final businessId = order['businessId'];
                              final packageId = order['packageId'];

                              return FutureBuilder<Map<String, dynamic>>(
                                future:
                                    _fetchOrderDetails(businessId, packageId),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const Card(
                                      margin: EdgeInsets.only(bottom: 12),
                                      child: Padding(
                                        padding: EdgeInsets.all(24.0),
                                        child: Center(
                                            child: CircularProgressIndicator()),
                                      ),
                                    );
                                  }

                                  final businessData =
                                      snapshot.data!['business'];
                                  final packageData = snapshot.data!['package'];

                                  final businessName =
                                      businessData?['businessName'] ??
                                          'עסק מקומי';
                                  final city = businessData?['city'] ?? '';
                                  final streetAddress =
                                      businessData?['streetAddress'] ?? '';

                                  String pickupHoursFormatted = 'לא צוין';
                                  if (packageData != null) {
                                    final startTs = packageData['pickupStart']
                                        as Timestamp?;
                                    final endTs =
                                        packageData['pickupEnd'] as Timestamp?;
                                    if (startTs != null && endTs != null) {
                                      final sTime = DateFormat('HH:mm')
                                          .format(startTs.toDate());
                                      final eTime = DateFormat('HH:mm')
                                          .format(endTs.toDate());
                                      pickupHoursFormatted = '$sTime - $eTime';
                                    }
                                  }

                                  final String currentStatus = order['status']
                                          ?.toString()
                                          .toUpperCase() ??
                                      '';
                                  final bool isCollected =
                                      currentStatus == 'COMPLETED' ||
                                          currentStatus == 'COLLECTED';
                                  final bool hasReview =
                                      order['hasReview'] == true;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.darkSurface
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.05),
                                            blurRadius: 5)
                                      ],
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 60,
                                          height: 60,
                                          clipBehavior: Clip.hardEdge,
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.grey.shade800
                                                : Colors.grey.shade200,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Builder(
                                            builder: (context) {
                                              final logoUrl =
                                                  businessData?['logoUrl']
                                                      ?.toString()
                                                      .trim();
                                              if (logoUrl == null ||
                                                  logoUrl.isEmpty) {
                                                return const Icon(
                                                    Icons.shopping_bag,
                                                    size: 30,
                                                    color: Colors.brown);
                                              }
                                              return Image.network(
                                                logoUrl,
                                                fit: BoxFit.cover,
                                                width: 60,
                                                height: 60,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    const Icon(
                                                        Icons.shopping_bag,
                                                        size: 30,
                                                        color: Colors.brown),
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
                                              // Interactive business name routing to review screen view
                                              InkWell(
                                                onTap: () {
                                                  if (businessId.isNotEmpty) {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            BusinessReviewsScreen(
                                                                businessId:
                                                                    businessId),
                                                      ),
                                                    );
                                                  }
                                                },
                                                child: Text(
                                                  businessName,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: AppColors.accentBlue,
                                                    decoration: TextDecoration
                                                        .underline,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                  packageData?['title'] ??
                                                      order['title'] ??
                                                      '',
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: isDark
                                                          ? Colors.white70
                                                          : Colors.black87)),
                                              Text(
                                                  'הזמנה #${order['id'].toString().substring(0, 6)}',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: isDark
                                                          ? Colors.white70
                                                          : Colors.grey)),

                                              Text(
                                                  'תאריך איסוף: ${DateFormat('dd/MM/yy').format(order['date'])}',
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey)),
                                              Text(
                                                  'שעות איסוף: $pickupHoursFormatted',
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey)),

                                              if (streetAddress.isNotEmpty)
                                                Text(
                                                    'כתובת: $streetAddress, $city',
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey)),

                                              const SizedBox(height: 4),
                                              Text('₪${order['price']}',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppColors
                                                          .accentBlue)),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            if (!isCollected) ...[
                                              ElevatedButton.icon(
                                                onPressed: () =>
                                                    _navigateToGoogleMaps(
                                                        city, streetAddress),
                                                icon: const Icon(
                                                    Icons.navigation,
                                                    size: 16),
                                                label: const Text('נווט למקום'),
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        AppColors.deepBlue,
                                                    foregroundColor:
                                                        Colors.white),
                                              ),
                                              const SizedBox(height: 8),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('ORDER')
                                                      .doc(order['id'])
                                                      .update({
                                                    'status': 'COMPLETED'
                                                  });
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(const SnackBar(
                                                            content: Text(
                                                                'החבילה סומנה כנלקחה!',
                                                                textAlign:
                                                                    TextAlign
                                                                        .right),
                                                            backgroundColor:
                                                                Colors.green));
                                                    _loadOrdersFromBackend();
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.green,
                                                    foregroundColor:
                                                        Colors.white),
                                                child: const Text(
                                                    'אספתי את החבילה'),
                                              ),
                                            ] else ...[
                                              if (!hasReview)
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      _showReviewDialog(
                                                          order, businessName),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.amber
                                                                  .shade700,
                                                          foregroundColor:
                                                              Colors.white),
                                                  child: const Text(
                                                      'דרג את בית העסק'),
                                                )
                                              else
                                                ElevatedButton(
                                                  onPressed: null,
                                                  style: ElevatedButton.styleFrom(
                                                      disabledBackgroundColor:
                                                          Colors.grey.shade300,
                                                      disabledForegroundColor:
                                                          Colors.grey.shade600),
                                                  child: const Text(
                                                      'הביקורת נשלחה'),
                                                )
                                            ]
                                          ],
                                        )
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
