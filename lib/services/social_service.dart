import 'package:elderly_care/config/supabase_config.dart';
import 'package:elderly_care/models/social_post.dart';
import 'package:elderly_care/models/comment_model.dart';
import 'package:image_picker/image_picker.dart';

class SocialService {
  final _supabase = SupabaseConfig.supabase;
  static const String _storageBucket = 'social-posts';
  
  // Fixed current time for consistency
  DateTime get _currentTime => DateTime.now().toUtc();
  

  // More reliable current user getter
String get _currentUser {
  final user = _supabase.auth.currentUser;
  if (user == null || user.email == null) {
    throw Exception('User not authenticated');
  }
  return user.email!.split('@')[0]; // Or however you derive username
}

  Stream<List<SocialPost>> getPostsStream() {
    try {
      return _supabase
          .from('social_posts')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .asyncMap((posts) async {
            final List<SocialPost> socialPosts = [];
            for (final post in posts) {
              try {
                // Get author details
                final authorData = await _supabase
                    .from('profiles')
                    .select()
                    .eq('username', post['username'])
                    .single();
                
                // Get likes count and check if user liked
                final likes = await _supabase
                    .from('post_likes')
                    .select('username')
                    .eq('post_id', post['id']);
                
                final bool isLiked = likes.any((like) => like['username'] == _currentUser);
                final int likesCount = likes.length;

                // Get comments count
                final comments = await _supabase
                    .from('post_comments')
                    .select('id')
                    .eq('post_id', post['id']);

                socialPosts.add(SocialPost.fromJson({
                  ...post,
                  'author_name': authorData['name'],
                  'author_avatar': authorData['avatar_url'] ?? 
                    'https://ui-avatars.com/api/?name=${authorData['name']}',
                  'likes_count': likesCount,
                  'comments_count': comments.length,
                  'is_liked': isLiked,
                }));
              } catch (e) {
                print('Error processing post ${post['id']}: $e');
              }
            }
            return socialPosts;
          });
    } catch (e) {
      print('Error in getPostsStream: $e');
      rethrow;
    }
  }

  Stream<List<SocialPost>> getUserPostsStream() {
    try {
      return _supabase
          .from('social_posts')
          .stream(primaryKey: ['id'])
          .eq('username', _currentUser)
          .order('created_at', ascending: false)
          .asyncMap((posts) async {
            final List<SocialPost> socialPosts = [];
            for (final post in posts) {
              try {
                // Get author details
                final authorData = await _supabase
                    .from('profiles')
                    .select()
                    .eq('username', post['username'])
                    .single();
                
                // Get likes count and check if user liked
                final likes = await _supabase
                    .from('post_likes')
                    .select('username')
                    .eq('post_id', post['id']);
                
                final bool isLiked = likes.any((like) => like['username'] == _currentUser);
                final int likesCount = likes.length;

                // Get comments count
                final comments = await _supabase
                    .from('post_comments')
                    .select('id')
                    .eq('post_id', post['id']);

                socialPosts.add(SocialPost.fromJson({
                  ...post,
                  'author_name': authorData['name'],
                  'author_avatar': authorData['avatar_url'] ?? 
                    'https://ui-avatars.com/api/?name=${authorData['name']}',
                  'likes_count': likesCount,
                  'comments_count': comments.length,
                  'is_liked': isLiked,
                }));
              } catch (e) {
                print('Error processing post ${post['id']}: $e');
              }
            }
            return socialPosts;
          });
    } catch (e) {
      print('Error in getUserPostsStream: $e');
      rethrow;
    }
  }

  Future<void> toggleLike(String postId) async {
    try {
      // Check if the user already liked the post
      final existingLike = await _supabase
          .from('post_likes')
          .select()
          .eq('post_id', postId)
          .eq('username', _currentUser)
          .maybeSingle();

      if (existingLike == null) {
        // Add like
        await _supabase.from('post_likes').insert({
          'post_id': postId,
          'username': _currentUser,
          'created_at': _currentTime.toIso8601String(),
        });
      } else {
        // Remove like
        await _supabase
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('username', _currentUser);
      }
    } catch (e) {
      print('Error toggling like: $e');
      rethrow;
    }
  }

  Future<String?> uploadImage(XFile image) async {
  try {
    final fileExt = image.path.split('.').last;
    final fileName = '${_currentTime.millisecondsSinceEpoch}.$fileExt';
    
    // Use the user's UUID for the folder name
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    final filePath = '$userId/$fileName';
    
    final imageBytes = await image.readAsBytes();
    
    // Upload the image
    await _supabase
        .storage
        .from('social-posts')
        .uploadBinary(filePath, imageBytes);

    // Get the public URL
    final imageUrl = _supabase
        .storage
        .from('social-posts')
        .getPublicUrl(filePath);

    print('Image uploaded successfully: $imageUrl');
    return imageUrl;
  } catch (e) {
    print('Error uploading image: $e');
    if (e.toString().contains('storage') || e.toString().contains('bucket')) {
      print('Storage error details: $e');
    }
    rethrow;
  }
}

// Update deleteImage method as well
Future<void> deleteImage(String imageUrl) async {
  try {
    final uri = Uri.parse(imageUrl);
    final pathSegments = uri.pathSegments;
    
    // Find the bucket name in the path and use everything after it
    final bucketIndex = pathSegments.indexOf('social-posts');
    if (bucketIndex != -1) {
      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
      
      print('Attempting to delete file: $filePath');
      await _supabase
          .storage
          .from('social-posts')
          .remove([filePath]);
      
      print('Image deleted successfully');
    } else {
      print('Could not extract valid file path from URL: $imageUrl');
    }
  } catch (e) {
    print('Error deleting image: $e');
    rethrow;
  }
}

  Future<void> createPost(String content, {String? imageUrl}) async {
    try {
      

      await _supabase.from('social_posts').insert({
        'username': _currentUser,
        'content': content,
        'image_url': imageUrl,
        'created_at': _currentTime.toIso8601String(),
      });
    } catch (e) {
      print('Error creating post: $e');
      rethrow;
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      // Get the post first to check for image
      final post = await _supabase
          .from('social_posts')
          .select()
          .eq('id', postId)
          .single();

      // Delete the image if it exists
      if (post['image_url'] != null) {
        await deleteImage(post['image_url']);
      }

      // Delete the post
      await _supabase
          .from('social_posts')
          .delete()
          .eq('id', postId)
          .eq('username', _currentUser);
    } catch (e) {
      print('Error deleting post: $e');
      rethrow;
    }
  }

  Stream<List<Comment>> getPostCommentsStream(String postId) {
    try {
      return _supabase
          .from('post_comments')
          .stream(primaryKey: ['id'])
          .eq('post_id', postId)
          .order('created_at')
          .asyncMap((comments) async {
            final List<Comment> commentsList = [];
            for (final comment in comments) {
              try {
                // Get author details
                final authorData = await _supabase
                    .from('profiles')
                    .select()
                    .eq('username', comment['username'])
                    .single();
                
                commentsList.add(Comment.fromJson({
                  ...comment,
                  'author_name': authorData['name'],
                  'author_avatar': authorData['avatar_url'] ?? 
                    'https://ui-avatars.com/api/?name=${authorData['name']}',
                }));
              } catch (e) {
                print('Error processing comment ${comment['id']}: $e');
              }
            }
            return commentsList;
          });
    } catch (e) {
      print('Error in getPostCommentsStream: $e');
      rethrow;
    }
  }

  Future<void> addComment({
    required String postId,
    required String content,
  }) async {
    try {
      await _supabase.from('post_comments').insert({
        'post_id': postId,
        'username': _currentUser,
        'content': content,
        'created_at': _currentTime.toIso8601String(),
      });
    } catch (e) {
      print('Error adding comment: $e');
      rethrow;
    }
  }

  Future<void> refreshPosts() async {
    try {
      // Check authentication first
      if (_supabase.auth.currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('social_posts')
          .select()
          .eq('username', _currentUser)
          .order('created_at', ascending: false)
          .limit(1);
    } catch (e) {
      print('Error refreshing posts: $e');
      rethrow;
    }
  }
}