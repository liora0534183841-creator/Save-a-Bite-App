import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:save_a_bite/core/theme/app_colors.dart';

/// A screen widget that fetches and displays detailed business information
/// along with a live stream of customer reviews and star ratings.
class BusinessReviewsScreen extends StatelessWidget {
  final String businessId;

  const BusinessReviewsScreen({super.key, required this.businessId});

  @override
  Widget build(BuildContext context) {
    // Determine active theme brightness for correct color styling
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppColors.deepBlue,
        title: const Text('ביקורות על העסק',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('BUSINESS')
              .doc(businessId)
              .get(),
          builder: (context, businessSnapshot) {
            if (businessSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!businessSnapshot.hasData || !businessSnapshot.data!.exists) {
              return const Center(child: Text('העסק אינו קיים במערכת.'));
            }

            final businessData =
                businessSnapshot.data!.data() as Map<String, dynamic>;
            final businessName = businessData['businessName'] ?? 'עסק מקומי';
            final street = businessData['streetAddress'] ?? '';
            final city = businessData['city'] ?? '';
            final double rating = (businessData['rating'] ?? 0.0).toDouble();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Business Profile Overview Header ---
                  Text(businessName,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.accentBlue
                              : AppColors.deepBlue)),
                  const SizedBox(height: 4),
                  Text('$street, $city',
                      style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.grey)),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Text('דירוג ממוצע: ',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('${rating.toStringAsFixed(1)} ',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber)),
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('מה לקוחות מספרים:',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.deepBlue)),
                  const SizedBox(height: 12),

                  // --- Live Stream of Business Reviews ---
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('REVIEW')
                        .where('businessId', isEqualTo: businessId)
                        .snapshots(),
                    builder: (context, reviewSnapshot) {
                      if (reviewSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final reviews = reviewSnapshot.data?.docs ?? [];

                      if (reviews.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(
                              child: Text('טרם התקבלו ביקורות עבור עסק זה.',
                                  style: TextStyle(color: Colors.grey))),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reviews.length,
                        itemBuilder: (context, index) {
                          final reviewData =
                              reviews[index].data() as Map<String, dynamic>;
                          final comment = reviewData['comment'] ?? '';
                          final int starRating = reviewData['rating'] ?? 5;
                          final customerUid = reviewData['uid'] ?? '';

                          // Fetch customer full name asynchronously for review card display
                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('USER')
                                .doc(customerUid)
                                .get(),
                            builder: (context, userSnapshot) {
                              String displayName = 'לקוח/ה המערכת';
                              if (userSnapshot.hasData &&
                                  userSnapshot.data!.exists) {
                                final userData = userSnapshot.data!.data()
                                    as Map<String, dynamic>;
                                final fullName =
                                    userData['fullName']?.toString().trim() ??
                                        '';
                                if (fullName.isNotEmpty) {
                                  displayName = fullName;
                                }
                              }

                              return Card(
                                color: isDark
                                    ? AppColors.darkSurface
                                    : Colors.white,
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
                                              starRating,
                                              (i) => const Icon(Icons.star,
                                                  size: 16,
                                                  color: Colors.amber))),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6.0),
                                    child: Text(comment,
                                        style: TextStyle(
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.black87)),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
