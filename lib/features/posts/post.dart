import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class Post {
  final int id;
  final String type;
  final String title;
  final String? excerpt;
  final String slug;
  final String? cover;
  final String? minLevel;
  final String? externalUrl;
  final String? publishedAt;
  final String? body;
  final bool isReserved; // destinato a un pubblico ristretto (non a tutti)

  Post({
    required this.id,
    required this.type,
    required this.title,
    this.excerpt,
    required this.slug,
    this.cover,
    this.minLevel,
    this.externalUrl,
    this.publishedAt,
    this.body,
    this.isReserved = false,
  });

  factory Post.fromJson(Map<String, dynamic> j) => Post(
        id: j['id'] as int,
        type: (j['type'] ?? 'generic') as String,
        title: (j['title'] ?? '') as String,
        excerpt: j['excerpt'] as String?,
        slug: (j['slug'] ?? '') as String,
        cover: j['cover'] as String?,
        minLevel: j['min_level'] as String?,
        externalUrl: j['external_url'] as String?,
        publishedAt: j['published_at'] as String?,
        body: j['body'] as String?,
        isReserved: (j['is_reserved'] as bool?) ?? (j['min_level'] != null && j['min_level'] != 'public'),
      );
}

final postsProvider = FutureProvider<List<Post>>((ref) async {
  final data = await ref.read(apiClientProvider).getData('/posts');
  return (data as List)
      .map((e) => Post.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
});

final postDetailProvider = FutureProvider.family<Post, int>((ref, id) async {
  final data = await ref.read(apiClientProvider).getData('/posts/$id');
  return Post.fromJson(Map<String, dynamic>.from(data as Map));
});
