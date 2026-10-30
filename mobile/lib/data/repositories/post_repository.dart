import '../../core/network/api_client.dart';
import '../mock/mock_clubs.dart';
import '../models/comment.dart';
import '../models/post.dart';

/// 게시물 상세·댓글 관련 서버 요청
abstract class PostRepository {
  Future<Post> fetchPost(int postId);

  Future<List<Comment>> fetchComments(int postId);

  Future<Comment> addComment(int postId, String content);

  Future<Comment> updateComment(int commentId, String content);

  Future<void> deleteComment(int commentId);
}

/// 실제 서버(FastAPI)와 통신하는 구현
class ApiPostRepository implements PostRepository {
  ApiPostRepository(this._api);

  final ApiClient _api;

  @override
  Future<Post> fetchPost(int postId) async {
    final data = await _api.get('/posts/$postId');
    return Post.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<Comment>> fetchComments(int postId) async {
    final data = await _api.get('/posts/$postId/comments');
    return (data as List)
        .map((e) => Comment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Comment> addComment(int postId, String content) async {
    final data =
        await _api.post('/posts/$postId/comments', body: {'content': content});
    return Comment.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<Comment> updateComment(int commentId, String content) async {
    final data =
        await _api.patch('/comments/$commentId', body: {'content': content});
    return Comment.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteComment(int commentId) async {
    await _api.delete('/comments/$commentId');
  }
}

/// 서버 없이 화면을 개발·테스트할 때 쓰는 가짜 구현
class MockPostRepository implements PostRepository {
  MockPostRepository({this.currentUserId = 1, this.currentUserName = '학생1'});

  final int currentUserId;
  final String currentUserName;

  late final List<Comment> _comments = [
    Comment(
      id: 1,
      postId: 1,
      authorId: 2,
      authorName: '김임원',
      content: '이번 주는 그래프 문제를 풀어요.',
      createdAt: DateTime(2026, 10, 27, 19, 0),
    ),
  ];
  int _nextId = 100;

  @override
  Future<Post> fetchPost(int postId) async {
    return mockPosts.firstWhere((p) => p.id == postId);
  }

  @override
  Future<List<Comment>> fetchComments(int postId) async {
    return _comments.where((c) => c.postId == postId).toList();
  }

  @override
  Future<Comment> addComment(int postId, String content) async {
    final comment = Comment(
      id: _nextId++,
      postId: postId,
      authorId: currentUserId,
      authorName: currentUserName,
      content: content,
      createdAt: DateTime.now(),
    );
    _comments.add(comment);
    return comment;
  }

  @override
  Future<Comment> updateComment(int commentId, String content) async {
    final index = _comments.indexWhere((c) => c.id == commentId);
    final old = _comments[index];
    final updated = Comment(
      id: old.id,
      postId: old.postId,
      authorId: old.authorId,
      authorName: old.authorName,
      content: content,
      createdAt: old.createdAt,
    );
    _comments[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteComment(int commentId) async {
    _comments.removeWhere((c) => c.id == commentId);
  }
}
