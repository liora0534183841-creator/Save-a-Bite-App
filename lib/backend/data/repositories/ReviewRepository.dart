import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;
import '../models/review_model.dart';

class ReviewRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _col = 'REVIEW';
  // Saves a new review document.
  Future<void> saveReview(ReviewModel review) async {
    try {
      await _db.collection(_col).doc(review.reviewId).set(review.toMap());
      dev.log("Review saved: ${review.reviewId}", name: "ReviewRepository");
    } catch (e, stack) {
      dev.log("Save review failed", name: "ReviewRepository", error: e, stackTrace: stack);
      rethrow;
    }
  }
  // Fetches all reviews associated with a specific business.
  Future<List<ReviewModel>> getReviewsByBusiness(String businessId) async {
    try {
      var snap = await _db.collection(_col).where('businessId', isEqualTo: businessId).get();
      return snap.docs.map((doc) => ReviewModel.fromMap(doc.data())).toList();
    } catch (e, stack) {
      dev.log("Fetch business reviews failed", name: "ReviewRepository", error: e, stackTrace: stack);
      rethrow;
    }
  }
}