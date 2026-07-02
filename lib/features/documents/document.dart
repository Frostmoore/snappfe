import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class Document {
  final int id;
  final String title;
  final String? description;
  final String? url;

  Document({required this.id, required this.title, this.description, this.url});

  factory Document.fromJson(Map<String, dynamic> j) => Document(
        id: j['id'] as int,
        title: (j['title'] ?? '') as String,
        description: j['description'] as String?,
        url: j['url'] as String?,
      );
}

final documentsProvider = FutureProvider<List<Document>>((ref) async {
  final data = await ref.read(apiClientProvider).getData('/documents');
  return (data as List)
      .map((e) => Document.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
});
