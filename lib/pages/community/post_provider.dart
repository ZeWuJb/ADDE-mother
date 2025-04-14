import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'post_model.dart';

class PostProvider with ChangeNotifier {
  List<Post> _posts = [];
  List<Post> get posts => _posts;

  Future<void> fetchPosts(String currentMotherId) async {
    try {
      print('Starting fetchPosts for motherId: $currentMotherId');
      final response = await Supabase.instance.client
          .from('posts')
          .select('*, mothers(full_name)')
          .order('created_at', ascending: false);

      print('Fetched posts count: ${response.length}');
      print('Posts data: $response');

      final likeResponse = await Supabase.instance.client
          .from('likes')
          .select('post_id')
          .eq('mother_id', currentMotherId);

      final likedPostIds = likeResponse.map((e) => e['post_id']).toSet();
      print('Liked post IDs: $likedPostIds');

      _posts = response.map<Post>((map) {
        try {
          final post = Post.fromMap(map, map['mothers']['full_name'] ?? 'Unknown')
            ..isLiked = likedPostIds.contains(map['id']);
          print('Mapped post: ${post.title}');
          return post;
        } catch (e) {
          print('Error mapping post: $map, error: $e');
          return Post(
            id: map['id']?.toString() ?? '',
            motherId: map['mother_id']?.toString() ?? '',
            fullName: 'Unknown',
            title: 'Invalid Post',
            content: 'Error loading post',
            likesCount: 0,
            createdAt: DateTime.now(),
          );
        }
      }).toList();

      print('Total mapped posts: ${_posts.length}');
      notifyListeners();
      print('fetchPosts completed');
    } catch (e) {
      print('Error fetching posts: $e');
      rethrow;
    }
  }

  Future<void> createPost(String motherId, String fullName, String title, String content) async {
    try {
      final response = await Supabase.instance.client.from('posts').insert({
        'mother_id': motherId,
        'title': title,
        'content': content,
      }).select('*, mothers(full_name)').single();

      print('Created post: $response');

      _posts.insert(
        0,
        Post.fromMap(response, fullName)..isLiked = false,
      );
      notifyListeners();
    } catch (e) {
      print('Error creating post: $e');
      rethrow;
    }
  }

  Future<void> updatePost(String postId, String title, String content) async {
    try {
      await Supabase.instance.client
          .from('posts')
          .update({'title': title, 'content': content})
          .eq('id', postId);

      final index = _posts.indexWhere((post) => post.id == postId);
      if (index != -1) {
        _posts[index] = Post(
          id: postId,
          motherId: _posts[index].motherId,
          fullName: _posts[index].fullName,
          title: title,
          content: content,
          likesCount: _posts[index].likesCount,
          createdAt: _posts[index].createdAt,
          isLiked: _posts[index].isLiked,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error updating post: $e');
      rethrow;
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await Supabase.instance.client.from('posts').delete().eq('id', postId);
      _posts.removeWhere((post) => post.id == postId);
      notifyListeners();
    } catch (e) {
      print('Error deleting post: $e');
      rethrow;
    }
  }

  Future<void> toggleLike(String postId, String motherId, bool isLiked) async {
    try {
      if (isLiked) {
        await Supabase.instance.client
            .from('likes')
            .delete()
            .eq('post_id', postId)
            .eq('mother_id', motherId);
        await Supabase.instance.client.rpc('decrement_likes', params: {'row_id': postId});
      } else {
        await Supabase.instance.client.from('likes').insert({
          'post_id': postId,
          'mother_id': motherId,
        });
        await Supabase.instance.client.rpc('increment_likes', params: {'row_id': postId});
      }

      final index = _posts.indexWhere((post) => post.id == postId);
      if (index != -1) {
        _posts[index].isLiked = !isLiked;
        _posts[index].likesCount += isLiked ? -1 : 1;
        notifyListeners();
      }
    } catch (e) {
      print('Error toggling like: $e');
      rethrow;
    }
  }
}
