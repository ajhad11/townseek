import 'package:flutter/material.dart';
import '../models/review.dart';
import '../data/user_manager.dart';
import '../data/review_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewSection extends StatefulWidget {
  final Function(double)? onRatingChanged;
  final String shopId;
  final String? ownerId;

  const ReviewSection({
    super.key,
    this.onRatingChanged,
    required this.shopId,
    this.ownerId,
  });

  @override
  State<ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<ReviewSection> {
  String _sortOption = 'Newest';
  final ReviewService _reviewService = ReviewService();
  List<Review> _reviews = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() => _isLoading = true);
    final reviews = await _reviewService.fetchReviews(widget.shopId);
    if (mounted) {
      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
      _updateAverageRating();
    }
  }

  void _updateAverageRating() {
     if (_reviews.isNotEmpty) {
      final avg = _reviews.map((r) => r.rating).reduce((a, b) => a + b) / _reviews.length;
       if (widget.onRatingChanged != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
             widget.onRatingChanged!(avg);
          });
       }
    }
  }

  void _showReviewDialog({Review? existingReview}) {
    double rating = existingReview?.rating ?? 0.0;
    final TextEditingController commentController = TextEditingController(text: existingReview?.comment);
    const teal = Color(0xFF2962FF);
    const purple = Color(0xFF2962FF);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isSubmitting = false;

            Future<void> submit() async {
              if (rating == 0.0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please select a star rating")),
                );
                return;
              }
              setState(() => isSubmitting = true);
              try {
                if (existingReview != null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Editing not yet supported fully")));
                } else {
                  await _reviewService.addReview(widget.shopId, rating, commentController.text);
                }
                if (context.mounted) Navigator.pop(context);
                _fetchReviews();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                  setState(() => isSubmitting = false);
                }
              }
            }

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      existingReview == null ? "Rate and review" : "Edit review",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Rating label
                    Text(
                      "Rating (${rating.toInt()}/5)",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 8),

                    // Star Row
                    Row(
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () => setState(() => rating = index + 1.0),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              index < rating ? Icons.star_rounded : Icons.star_rounded,
                              color: index < rating ? teal : const Color(0xFFDDE8E8),
                              size: 40,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),

                    // Review label
                    Text(
                      "Review",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 8),

                    // Comment Text Area
                    TextField(
                      controller: commentController,
                      enabled: !isSubmitting,
                      maxLines: 5,
                      style: const TextStyle(color: Colors.black87, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Share your experience...",
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        contentPadding: const EdgeInsets.all(14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: purple.withValues(alpha: 0.5), width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: purple, width: 1.8),
                        ),
                        filled: false,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Cancel
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                          ),
                        ),
                        // Post
                        if (isSubmitting)
                          const SizedBox(width: 48, child: Center(child: CircularProgressIndicator(color: purple)))
                        else
                          ElevatedButton(
                            onPressed: submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: purple,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              elevation: 0,
                            ),
                            child: const Text(
                              "Post",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _deleteReview(String reviewId) async {
    try {
      await _reviewService.deleteReview(reviewId, widget.shopId);
      _fetchReviews();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error deleting: $e")));
      }
    }
  }

  void _showResponseDialog(Review review) {
    final TextEditingController responseController = TextEditingController(text: review.response);
    const purple = Color(0xFF2962FF);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isSubmitting = false;

            Future<void> submit() async {
              if (responseController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter a response")),
                );
                return;
              }
              setState(() => isSubmitting = true);
              try {
                await _reviewService.updateReviewResponse(review.id, responseController.text.trim());
                if (context.mounted) Navigator.pop(context);
                _fetchReviews();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                  setState(() => isSubmitting = false);
                }
              }
            }

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.response == null ? "Reply to review" : "Edit reply",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Your response will be visible publicly under the customer's review.",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: responseController,
                      enabled: !isSubmitting,
                      maxLines: 5,
                      style: const TextStyle(color: Colors.black87, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Write your response...",
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        contentPadding: const EdgeInsets.all(14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: purple.withValues(alpha: 0.5), width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: purple, width: 1.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (isSubmitting)
                          const SizedBox(width: 48, child: Center(child: CircularProgressIndicator(color: purple)))
                        else
                          ElevatedButton(
                            onPressed: submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: purple,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              elevation: 0,
                            ),
                            child: const Text(
                              "Submit",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(String reviewId) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Delete review?",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const SizedBox(height: 12),
                Text(
                  "Are you sure you want to delete this review? This cannot be undone.",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text("Cancel", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _deleteReview(reviewId);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[400],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        elevation: 0,
                      ),
                      child: const Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    // Filter current user review
    final userReviewIndex = _reviews.indexWhere((r) => r.userId == _currentUserId);
    final userReview = userReviewIndex != -1 ? _reviews[userReviewIndex] : null;

    // Filter other reviews
    final otherReviews = _reviews.where((r) => r.userId != _currentUserId).toList();

    // Calculate Average Rating
    double averageRating = 0;
    if (_reviews.isNotEmpty) {
      averageRating = _reviews.map((r) => r.rating).reduce((a, b) => a + b) / _reviews.length;
    }
    
    // Check if user is logged in
    final isLoggedIn = _currentUserId != null;

    // Sort reviews logic
    switch (_sortOption) {
      case 'Newest':
        otherReviews.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'Oldest':
        otherReviews.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'Highest Rating':
        otherReviews.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Lowest Rating':
        otherReviews.sort((a, b) => a.rating.compareTo(b.rating));
        break;
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // 0. Rating Summary
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
             children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _reviews.isEmpty ? "0.0" : averageRating.toStringAsFixed(1), 
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, height: 1.0)
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "${_reviews.length} reviews",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Row(
                         children: List.generate(5, (index) {
                           return Icon(
                             index < averageRating.round() ? Icons.star : Icons.star_border,
                             color: Colors.amber,
                             size: 24,
                           );
                         }),
                       ),
                       const SizedBox(height: 5),
                       const Text("Overall Rating", style: TextStyle(fontWeight: FontWeight.w500)),
                     ],
                  ),
                )
             ],
          ),
        ),

        // 0.5 Sorting Options
        if (_reviews.isNotEmpty)
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
               decoration: BoxDecoration(
                 border: Border.all(color: Colors.grey[300]!),
                 borderRadius: BorderRadius.circular(8),
               ),
               child: DropdownButtonHideUnderline(
                 child: DropdownButton<String>(
                   value: _sortOption,
                   isDense: true,
                   style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w500),
                   icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                   onChanged: (String? newValue) {
                     if (newValue != null) {
                       setState(() {
                         _sortOption = newValue;
                       });
                     }
                   },
                   items: <String>['Newest', 'Oldest', 'Highest Rating', 'Lowest Rating']
                       .map<DropdownMenuItem<String>>((String value) {
                     return DropdownMenuItem<String>(
                       value: value,
                       child: Text(value),
                       );
                   }).toList(),
                 ),
               ),
             ),
          ],
        ),
        const SizedBox(height: 15),

        // 1. Input Trigger (Shown if user hasn't reviewed yet and is logged in)
        if (userReview == null && isLoggedIn)
          GestureDetector(
            onTap: () => _showReviewDialog(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                   ListenableBuilder(
                      listenable: UserManager.instance,
                      builder: (context, child) {
                        final user = UserManager.instance;
                        return CircleAvatar(
                          radius: 14,
                          backgroundImage: user.localImageFile != null
                              ? FileImage(user.localImageFile!) as ImageProvider
                              : NetworkImage(user.profileImage),
                        );
                      }
                   ),
                   const SizedBox(width: 15),
                   const Text("Write a public review...", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          )
        else if (!isLoggedIn)
           const Center(child: Padding(
             padding: EdgeInsets.symmetric(vertical: 10),
             child: Text("Log in to write a review"),
           )),
        
        if (userReview == null) const SizedBox(height: 20),
        
        // 2. Review List
        if (userReview != null) ...[
          _buildReviewTile(userReview, isCurrentUser: true),
        ],
        
        ...otherReviews.map((review) => _buildReviewTile(review, isCurrentUser: false)),
      ],
    ));
  }

  Widget _buildReviewTile(Review review, {required bool isCurrentUser}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           CircleAvatar(
             backgroundImage: NetworkImage(review.userImage),
             radius: 20,
           ),
           const SizedBox(width: 15),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                     if (isCurrentUser)
                       PopupMenuButton<String>(
                         icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                         padding: EdgeInsets.zero,
                         constraints: const BoxConstraints(minWidth: 30),
                         onSelected: (value) {
                           if (value == 'delete') {
                             _showDeleteConfirmation(review.id);
                           } else if (value == 'edit') {
                             _showReviewDialog(existingReview: review);
                           }
                         },
                         itemBuilder: (context) => [
                           const PopupMenuItem(
                             value: 'edit',
                             height: 30,
                             child: Text("Edit", style: TextStyle(fontSize: 13)),
                           ),
                           const PopupMenuItem(
                             value: 'delete',
                             height: 30,
                             child: Text("Delete", style: TextStyle(fontSize: 13)),
                           ),
                         ],
                       )
                   ],
                 ),
                 Row(
                   children: [
                     Row(
                       children: List.generate(5, (index) {
                         return Icon(
                           index < review.rating ? Icons.star : Icons.star_border,
                           color: Colors.amber,
                           size: 12,
                         );
                       }),
                     ),
                     const SizedBox(width: 5),
                     Text(
                       _formatDate(review.date),
                       style: const TextStyle(color: Colors.grey, fontSize: 11),
                     ),
                   ],
                 ),
                  if (review.comment != null && review.comment!.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      review.comment!,
                      style: const TextStyle(fontSize: 13, height: 1.3, color: Colors.black87),
                    ),
                  ],

                  // 3. Response Section
                  if (review.response != null && review.response!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F4F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE1E8ED)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.storefront, size: 14, color: Color(0xFF2962FF)),
                              const SizedBox(width: 6),
                              const Text(
                                "Vendor Response",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2962FF),
                                ),
                              ),
                              const Spacer(),
                              if (review.responseAt != null)
                                Text(
                                  _formatDate(review.responseAt!),
                                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            review.response!,
                            style: const TextStyle(fontSize: 12, height: 1.4, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // 4. Shop Owner Reply/Edit Button
                  if (_currentUserId == widget.ownerId) ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () => _showResponseDialog(review),
                      icon: Icon(
                        review.response == null ? Icons.reply_rounded : Icons.edit_note_rounded,
                        size: 16,
                        color: const Color(0xFF2962FF),
                      ),
                      label: Text(
                        review.response == null ? "Reply" : "Edit Response",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2962FF),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays > 0) {
      return "${difference.inDays} days ago";
    } else if (difference.inHours > 0) {
      return "${difference.inHours} hours ago";
    } else {
      return "Just now";
    }
  }
}
