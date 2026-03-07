import '../models/community_post.dart';

abstract class CommunityRepository {
  Future<List<CommunityPost>> getPosts();
}

class CommunityRepositoryImpl implements CommunityRepository {
  @override
  Future<List<CommunityPost>> getPosts() async {
    // TODO: Implement community posts API integration when backend is ready
    throw UnimplementedError('CommunityRepository not yet implemented. Awaiting backend API.');
  }
}
