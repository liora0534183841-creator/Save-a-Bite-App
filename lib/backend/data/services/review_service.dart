import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;

import '../models/review_model.dart';
import '../repositories/ReviewRepository.dart';
import '../repositories/OrderRepository.dart';
import '../repositories/BusinessRepository.dart';

class ReviewService {
  final ReviewRepository _reviewRepo = ReviewRepository();
  final OrderRepository _orderRepo = OrderRepository();
  final BusinessRepository _bizRepo = BusinessRepository();
  // Submits a customer review and recalculates the business's average rating.
  Future<bool> submitBusinessReview({
    required String uid, required String businessId, required String orderId,
    required int ratingScore, required String reviewText,
  }) async {
    try {
      dev.log("Saving new review for business: $businessId", name: "ReviewService");
      String newReviewId = FirebaseFirestore.instance.collection('REVIEW').doc().id;

      ReviewModel newReview = ReviewModel(
        reviewId: newReviewId, uid: uid, orderId: orderId, businessId: businessId,
        rating: ratingScore, comment: reviewText,
      );

      await _reviewRepo.saveReview(newReview);
      await _orderRepo.updateOrderFields(orderId, {'hasReview': true});

      List<ReviewModel> allReviews = await _reviewRepo.getReviewsByBusiness(businessId);
      double totalRating = 0.0;
      for (var r in allReviews) {
        totalRating += r.rating;
      }
      double newAverage = allReviews.isEmpty ? 0.0 : totalRating / allReviews.length;

      await _bizRepo.updateBusinessFields(businessId, {'rating': newAverage});

      dev.log("Review saved and average updated", name: "ReviewService");
      return true;

    } catch (e, stack) {
      dev.log("Error saving review", name: "ReviewService", error: e, stackTrace: stack);
      throw Exception("Failed to submit review: $e");
    }
  }
  // Retrieves and sorts all reviews for a specific business, prioritizing highest ratings.
  Future<List<ReviewModel>> getBusinessPageWithSortedReviews(String businessId) async {
    try {
      dev.log("Fetching and sorting reviews for business: $businessId", name: "ReviewService");
      List<ReviewModel> reviews = await _reviewRepo.getReviewsByBusiness(businessId);
      
      reviews.sort((a, b) {
        if (b.rating != a.rating) {
          return b.rating.compareTo(a.rating);
        }
        return b.reviewId.compareTo(a.reviewId);
      });
      
      return reviews;
    } catch (e, stack) {
      dev.log("Error fetching business reviews", name: "ReviewService", error: e, stackTrace: stack);
      throw Exception("Failed to load business reviews: $e");
    }
  }
}