import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/storage_service.dart';
import '../core/services/supabase_service.dart';
import '../models/post_model.dart';

enum PostStatus { initial, loading, loaded, error }

class PostProvider extends ChangeNotifier {
  PostStatus _status = PostStatus.initial;
  List<PostModel> _posts = [];
  List<PostModel> _myPosts = [];
  String? _errorMessage;
  RealtimeChannel? _postsChannel;

  // ── Getters ───────────────────────────────────────────────────────────────
  PostStatus get status => _status;
  List<PostModel> get posts => _posts;
  List<PostModel> get myPosts => _myPosts;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == PostStatus.loading;

  // ── Fetch all posts ───────────────────────────────────────────────────────
  Future<void> fetchPosts({bool silent = false}) async {
    if (!silent) _setLoading();
    try {
      final data = await SupabaseService.table('posts')
          .select('*, profiles(full_name, avatar_url)')
          .order('created_at', ascending: false);
      _posts = (data as List).map((e) => PostModel.fromJson(e)).toList();
      _status = PostStatus.loaded;
      notifyListeners();
    } catch (e) {
      if (!silent) _setError(e.toString());
    }
  }

  // ── Fetch current user's posts ────────────────────────────────────────────
  Future<void> fetchMyPosts(String userId) async {
    _setLoading();
    try {
      final data = await SupabaseService.table('posts')
          .select('*, profiles(full_name, avatar_url)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      _myPosts = (data as List).map((e) => PostModel.fromJson(e)).toList();
      _status = PostStatus.loaded;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // ── Create post (supports multiple images) ────────────────────────────────
  /// [imageFiles] is a list of XFile objects. The first is used as the cover.
  /// All images are uploaded to Supabase Storage; the first public URL is
  /// stored in the post's `image_url` column.
  Future<bool> createPost(
    PostModel post, {
    XFile? imageFile,        // legacy single-image compat
    List<XFile>? imageFiles, // preferred: multi-image
  }) async {
    _setLoading();
    try {
      // Merge both sources; imageFiles takes precedence
      final allFiles = [
        ...?imageFiles,
        if (imageFile != null && !(imageFiles?.contains(imageFile) ?? false))
          imageFile,
      ];

      List<String> allUrls = [];
      String? coverUrl = post.imageUrl;

      if (allFiles.isNotEmpty) {
        // Read all files into memory in parallel
        final fileData = await Future.wait(
          allFiles.map((f) async => (bytes: await f.readAsBytes(), name: f.name)),
        );

        allUrls = await StorageService.uploadMultipleImages(
          fileData,
          post.userId,
        );

        if (allUrls.isEmpty) {
          throw Exception('All image uploads failed. Check bucket policies.');
        }

        coverUrl = allUrls.first;
      }

      final updatedPost = PostModel(
        id: post.id,
        userId: post.userId,
        title: post.title,
        author: post.author,
        description: post.description,
        imageUrl: coverUrl,
        imageUrls: allUrls,
        condition: post.condition,
        listingType: post.listingType,
        price: post.price,
        category: post.category,
        location: post.location,
        isAvailable: post.isAvailable,
        createdAt: post.createdAt,
      );

      await SupabaseService.table('posts').insert(updatedPost.toJson());

      // Silently refresh so the home feed picks up the new post via realtime
      await fetchPosts(silent: true);
      _status = PostStatus.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ── Delete post ───────────────────────────────────────────────────────────
  Future<bool> deletePost(String postId) async {
    try {
      // Optionally delete cover image from storage
      final post = _posts.firstWhere(
        (p) => p.id == postId,
        orElse: () => _myPosts.firstWhere((p) => p.id == postId,
            orElse: () => throw StateError('not found')),
      );
      await SupabaseService.table('posts').delete().eq('id', postId);
      for (final url in post.imageUrls) {
        await StorageService.deleteImageByUrl(url);
      }
      _posts.removeWhere((p) => p.id == postId);
      _myPosts.removeWhere((p) => p.id == postId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ── Realtime subscription ─────────────────────────────────────────────────
  void subscribeToPosts() {
    _postsChannel?.unsubscribe();
    _postsChannel = SupabaseService.client
        .channel('public:posts')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'posts',
          callback: (_) => fetchPosts(silent: true),
        )
        .subscribe();
  }

  void unsubscribePosts() {
    _postsChannel?.unsubscribe();
    _postsChannel = null;
  }

  // ── Private helpers ───────────────────────────────────────────────────────
  void _setLoading() {
    _status = PostStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = PostStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    unsubscribePosts();
    super.dispose();
  }
}
