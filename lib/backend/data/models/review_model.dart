class ReviewModel {
  final String reviewId;  // Unique - one review per order 
  final String uid;
  final String orderId;  
  final String businessId; 
  final int rating;   // 1-5     
  final String comment;   

  ReviewModel({
    required this.reviewId,
    required this.uid,
    required this.orderId,
    required this.businessId,
    required this.rating,
    required this.comment,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      reviewId: map['reviewId'] ?? '',
      uid: map['uid'] ?? '',
      orderId: map['orderId'] ?? '',
      businessId: map['businessId'] ?? '',
      rating: map['rating'] ?? 5,
      comment: map['comment'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reviewId': reviewId,
      'uid': uid,
      'orderId': orderId,
      'businessId': businessId,
      'rating': rating,
      'comment': comment,
    };
  }
}