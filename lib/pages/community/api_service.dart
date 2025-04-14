import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Posts
  static Future<List<Map<String, dynamic>>> fetchPosts({
    int page = 0,
    int limit = 10,
    String? userId,
  }) async {
    final from = page * limit;
    final to = (page + 1) * limit - 1;

    final response = await _supabase
        .from('posts')
        .select('''
          *, 
          mother:user_id(*),
          likes(count),
          comments(count),
          is_liked:likes!inner(user_id)
        ''')
        .eq('is_liked.user_id', userId ?? '')
        .order('created_at', ascending: false)
        .range(from, to);

    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> createPost({
    required String content,
    String? imagePath,
    required String userId,
  }) async {
    String? imageUrl;
    if (imagePath != null) {
      final fileExt = imagePath.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      await _supabase.storage
          .from('post_images')
          .upload(fileName, File(imagePath));
      imageUrl = _supabase.storage.from('post_images').getPublicUrl(fileName);
    }

    await _supabase.from('posts').insert({
      'user_id': userId,
      'content': content,
      'image_url': imageUrl,
    });
  }

  static Future<void> toggleLike({
    required String postId,
    required String userId,
  }) async {
    final existingLike =
        await _supabase
            .from('likes')
            .select()
            .eq('user_id', userId)
            .eq('post_id', postId)
            .maybeSingle();

    if (existingLike != null) {
      await _supabase
          .from('likes')
          .delete()
          .eq('user_id', userId)
          .eq('post_id', postId);
    } else {
      await _supabase.from('likes').insert({
        'user_id': userId,
        'post_id': postId,
      });
    }
  }

  static Future<void> deletePost(String postId) async {
    await _supabase.from('posts').delete().eq('id', postId);
  }

  // Mothers/Profiles
  static Future<Map<String, dynamic>> getMotherProfile(String userId) async {
    final response =
        await _supabase.from('mothers').select().eq('user_id', userId).single();
    return response;
  }
}
