import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/errors/api_exception.dart';
import '../../data/dtos/community_post_dto.dart';
import '../../data/repository_interfaces/i_community_repository.dart';
import '../services/profile_content_change_notifier.dart';

class CommunityViewModel extends ChangeNotifier {
  CommunityViewModel({
    required ICommunityRepository communityRepository,
    required ProfileContentChangeNotifier profileContentChangeNotifier,
  })  : _repository = communityRepository,
        _profileContentChangeNotifier = profileContentChangeNotifier;

  final ICommunityRepository _repository;
  final ProfileContentChangeNotifier _profileContentChangeNotifier;

  List<CommunityPostDto> _posts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isPosting = false;
  String? _error;

  static const int _pageSize = 20;
  int _offset = 0;
  bool _hasMore = true;
  String _activeFeed = 'community';

  List<CommunityPostDto> get posts => _posts;
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
      _profileContentChangeNotifier.markCommunityPostChanged(
        ownerUserId: newPost.author.id,
      );
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

  Future<CommunityPostDto?> getPostDetail(int postId) async {
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

  Future<CommunityPostDto?> toggleLike(int postId, {required bool shouldLike}) async {
    final index = _posts.indexWhere((post) => post.id == postId);
    CommunityPostDto? previousPost;

    if (index >= 0) {
      previousPost = _posts[index];
      final current = _posts[index];
      final nextLikeCount = shouldLike
          ? current.likesCount + 1
          : (current.likesCount > 0 ? current.likesCount - 1 : 0);
      final optimistic = current.copyWith(
        isLikedByMe: shouldLike,
        likesCount: nextLikeCount,
      );
      _posts = [..._posts]..[index] = optimistic;
      notifyListeners();
    }

    try {
      final response = shouldLike
          ? await _repository.likePost(postId)
          : await _repository.unlikePost(postId);
      if (!response.isSuccess) throw response.error!;

      unawaited(getPostDetail(postId));
      final refreshedIndex = _posts.indexWhere((post) => post.id == postId);
      return refreshedIndex >= 0 ? _posts[refreshedIndex] : previousPost;
    } on ApiException catch (e) {
      if (index >= 0 && previousPost != null) {
        _posts = [..._posts]..[index] = previousPost;
      }
      _error = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      if (index >= 0 && previousPost != null) {
        _posts = [..._posts]..[index] = previousPost;
      }
      _error = shouldLike ? 'Failed to like post.' : 'Failed to unlike post.';
      notifyListeners();
      return null;
    }
  }

  Future<CommunityPostDto?> toggleSave(int postId, {required bool shouldSave}) async {
    try {
      final response = shouldSave
          ? await _repository.savePost(postId)
          : await _repository.unsavePost(postId);
      if (!response.isSuccess) throw response.error!;
      final updatedPost = await getPostDetail(postId);
      if (updatedPost != null) {
        _profileContentChangeNotifier.markCommunityPostChanged(
          ownerUserId: updatedPost.author.id,
        );
      }
      return updatedPost;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      _error = shouldSave ? 'Failed to save post.' : 'Failed to unsave post.';
      notifyListeners();
      return null;
    }
  }

  Future<CommunityPostDto?> updatePost({
    required int postId,
    required String content,
    List<String> imagePaths = const [],
    List<String> retainedImageUrls = const [],
  }) async {
    try {
      final response = await _repository.updatePost(
        postId: postId,
        content: content,
        imagePaths: imagePaths,
        retainedImageUrls: retainedImageUrls,
      );
      if (!response.isSuccess) throw response.error!;
      return getPostDetail(postId);
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Failed to update post.';
      notifyListeners();
      return null;
    }
  }

  Future<bool> deletePost(int postId, {int? ownerUserId}) async {
    try {
      final existingPost = _posts.cast<CommunityPostDto?>().firstWhere(
        (post) => post?.id == postId,
        orElse: () => null,
      );
      final response = await _repository.deletePost(postId);
      if (!response.isSuccess) throw response.error!;
      _posts = _posts.where((post) => post.id != postId).toList();
      final changedOwnerUserId = ownerUserId ?? existingPost?.author.id;
      if (changedOwnerUserId != null) {
        _profileContentChangeNotifier.markCommunityPostChanged(
          ownerUserId: changedOwnerUserId,
        );
      }
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to delete post.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> reportPost({
    required int postId,
    required String reason,
    String? details,
  }) async {
    try {
      final response = await _repository.reportPost(
        postId: postId,
        reason: reason,
        details: details,
      );
      if (!response.isSuccess) throw response.error!;
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to submit report.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> hidePostForViewer(int postId) async {
    try {
      final response = await _repository.hidePostForViewer(postId);
      if (!response.isSuccess) throw response.error!;
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to hide post.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> unhidePostForViewer(int postId) async {
    try {
      final response = await _repository.unhidePostForViewer(postId);
      if (!response.isSuccess) throw response.error!;
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to unhide post.';
      notifyListeners();
      return false;
    }
  }

  Future<CommunityPostDto?> addComment({
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

  Future<CommunityPostDto?> updateComment({
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

  Future<CommunityPostDto?> deleteComment({
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

  void clear() {
    _posts = [];
    _isLoading = false;
    _isLoadingMore = false;
    _isPosting = false;
    _error = null;
    _offset = 0;
    _hasMore = true;
    _activeFeed = 'community';
    notifyListeners();
  }

  void _replacePost(CommunityPostDto updatedPost) {
    final index = _posts.indexWhere((post) => post.id == updatedPost.id);
    if (index < 0) {
      return;
    }
    final existing = _posts[index];
    final merged = _withStableImageUrls(existing: existing, incoming: updatedPost);
    _posts = [..._posts]..[index] = merged;
    notifyListeners();
  }

  CommunityPostDto _withStableImageUrls({
    required CommunityPostDto existing,
    required CommunityPostDto incoming,
  }) {
    final existingImages = existing.orderedImages;
    final incomingImages = incoming.orderedImages;

    if (existingImages.isEmpty || incomingImages.isEmpty) {
      return incoming;
    }

    if (existingImages.length != incomingImages.length) {
      return incoming;
    }

    for (var i = 0; i < existingImages.length; i++) {
      if (_normalizeImageUrl(existingImages[i]) != _normalizeImageUrl(incomingImages[i])) {
        return incoming;
      }
    }

    return incoming.copyWith(
      imageUrls: existing.imageUrls,
    );
  }

  String _normalizeImageUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;

    if ((uri.scheme == 'http' || uri.scheme == 'https') && uri.hasAuthority) {
      return uri.replace(query: '', fragment: '').toString();
    }

    return url;
  }
}

