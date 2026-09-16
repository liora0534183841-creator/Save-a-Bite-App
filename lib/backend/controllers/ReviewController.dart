import 'package:flutter/material.dart';
import 'dart:developer' as dev;
import '../data/models/review_model.dart';
import '../data/services/review_service.dart';

// Manages the state and submission of business reviews.
class ReviewController extends ChangeNotifier {
  final ReviewService _reviewService = ReviewService();

  bool _isLoading = false;
  // Returns whether an authentication process is currently running.
  bool get isLoading => _isLoading;

  List<ReviewModel> _businessReviews = [];
  // The list of reviews for the currently selected business.
  List<ReviewModel> get businessReviews => _businessReviews;

  String? _errorMessage;
  // Holds the latest error message, or `null` if no error exists.
  String? get errorMessage => _errorMessage;

  // Updates the loading status and notifies about it.
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Clears the current error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Submits a new review for a business and refreshes the review list.
  Future<bool> submitReview({
    required String uid,
    required String businessId,
    required String orderId,
    required int ratingScore,
    required String reviewText,
  }) async {
    _setLoading(true);
    clearError();
    try {
      dev.log("Request to the controller: Submit a new review $businessId", name: "ReviewController");
      bool success = await _reviewService.submitBusinessReview(
        uid: uid,
        businessId: businessId,
        orderId: orderId,
        ratingScore: ratingScore,
        reviewText: reviewText,
      );
      
      if (success) {
        await loadBusinessReviews(businessId);
      }
      return success;
    } catch (e, stack) {
      dev.log("Error submitting review", name: "ReviewController", error: e, stackTrace: stack);
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Loads all sorted reviews for a specific business.
  Future<void> loadBusinessReviews(String businessId) async {
    _setLoading(true);
    clearError();
    try {
      dev.log("Request to the controller: Load sorted reviews for business $businessId", name: "ReviewController");
      _businessReviews = await _reviewService.getBusinessPageWithSortedReviews(businessId);
    } catch (e, stack) {
      dev.log("Error loading reviews", name: "ReviewController", error: e, stackTrace: stack);
      _businessReviews = [];
      _errorMessage = e.toString().replaceAll("Exception: ", "");
    } finally {
      _setLoading(false);
    }
  }
}