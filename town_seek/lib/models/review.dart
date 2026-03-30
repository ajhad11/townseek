class Review {
  final String id;
  final String userId;
  final String userName;
  final String userImage;
  final double rating;
  final String? comment;
  final DateTime date;
  final String? response;
  final DateTime? responseAt;

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.rating,
    this.comment,
    required this.date,
    this.response,
    this.responseAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'];
    final name = profile != null ? profile['name'] : 'Unknown User';
    final avatarUrl = profile != null ? profile['avatar_url'] : null;
    
    // Fallback image if not provided in 'profiles'
    final image = avatarUrl ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random&size=150';

    return Review(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      userName: name,
      userImage: image,
      rating: (json['rating'] as num).toDouble(),
      comment: json['review_text'],
      date: DateTime.parse(json['created_at']),
      response: json['response'],
      responseAt: json['response_at'] != null ? DateTime.parse(json['response_at']) : null,
    );
  }
}
