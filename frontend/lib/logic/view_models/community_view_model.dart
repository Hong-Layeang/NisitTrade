import 'package:flutter/material.dart';

import '../../core/errors/api_exception.dart';
import '../../data/models/community_post.dart';
import '../../data/repositories/community_repository_impl.dart';

class CommunityViewModel extends ChangeNotifier {
  CommunityViewModel({required CommunityRepository communityRepository})
      : _repository = communityRepository;

  final CommunityRepository _repository;

  List<CommunityPost> _posts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isPosting = false;
  String? _error;

  static const int _pageSize = 20;
  int _offset = 0;
  bool _hasMore = true;
  String _activeFeed = 'community';

  List<CommunityPost> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isPosting => _isPosting;
  String? get error => _error;
  bool get hasMore => _hasMore;
  String get activeFeed => _activeFeed;

  Future<void> load({String feed = 'community'}) async {
    if (_isLoading) return;
    _activeFeed = feed;
    _isLoading = true;
    _error = null;
    _offset = 0;
    _hasMore = true;
    _posts = [];
    notifyListeners();

    try {
      final response = await _repository.getPosts(
        feed: feed,
        limit: _pageSize,
        offset: 0,
      );
      if (!response.isSuccess) throw response.error!;
      final fetched = response.data ?? [];
      _posts = fetched;
      _offset = fetched.length;
      _hasMore = fetched.length >= _pageSize;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load community posts.';
      debugPrint('CommunityViewModel.load error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final response = await _repository.getPosts(
        feed: _activeFeed,
        limit: _pageSize,
        offset: _offset,
      );
      if (!response.isSuccess) throw response.error!;
      final fetched = response.data ?? [];
      _posts = [..._posts, ...fetched];
      _offset += fetched.length;
      _hasMore = fetched.length >= _pageSize;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load more posts.';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<bool> createPost({
    required String content,
    List<String> imagePaths = const [],
  }) async {
    if (_isPosting) return false;
    _isPosting = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _repository.createPost(
        content: content,
        imagePaths: imagePaths,
      );
      if (!response.isSuccess) {
        _error = response.error?.message ?? 'Failed to create post.';
        return false;
      }
      final newPost = response.data!;
      _posts = [newPost, ..._posts];

      await load(feed: _activeFeed);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'Failed to create post.';
      return false;
    } finally {
      _isPosting = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async => load(feed: _activeFeed);

  Future<CommunityPost?> getPostDetail(int postId) async {
    try {
      final response = await _repository.getPost(postId);
      if (!response.isSuccess) throw response.error!;
      final post = response.data;
      if (post == null) return null;
      _replacePost(post);
      return post;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Failed to fetch post detail.';
      notifyListeners();
      return null;
    }
  }

  Future<CommunityPost?> toggleLike(int postId, {required bool shouldLike}) async {
    try {
      final response = shouldLike
          ? await _repository.likePost(postId)
          : await _repository.unlikePost(postId);
      if (!response.isSuccess) throw response.error!;
      return getPostDetail(postId);
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      _error = shouldLike ? 'Failed to like post.' : 'Failed to unlike post.';
      notifyListeners();
      return null;
    }
  }

  Future<CommunityPost?> addComment({
    required int postId,
    required String content,
  }) async {
    try {
      final response = await _repository.addComment(postId: postId, content: content);
      if (!response.isSuccess) throw response.error!;
      return getPostDetail(postId);
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Failed to add comment.';
      notifyListeners();
      return null;
    }
  }

  Future<CommunityPost?> updateComment({
    required int postId,
    required int commentId,
    required String content,
  }) async {
    try {
      final response = await _repository.updateComment(
        postId: postId,
        commentId: commentId,
        content: content,
      );
      if (!response.isSuccess) throw response.error!;
      return getPostDetail(postId);
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Failed to update comment.';
      notifyListeners();
      return null;
    }
  }

  Future<CommunityPost?> deleteComment({
    required int postId,
    required int commentId,
  }) async {
    try {
      final response = await _repository.deleteComment(
        postId: postId,
        commentId: commentId,
      );
      if (!response.isSuccess) throw response.error!;
      return getPostDetail(postId);
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Failed to delete comment.';
      notifyListeners();
      return null;
    }
  }

  void _replacePost(CommunityPost updatedPost) {
    final index = _posts.indexWhere((post) => post.id == updatedPost.id);
    if (index < 0) {
      return;
    }
    _posts = [..._posts]..[index] = updatedPost;
    notifyListeners();
  }
}
