import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class MagazineIssue {
  final int id;
  final String title;
  final int? number;
  final String? cover;
  final String url;
  final String? issueDate;

  MagazineIssue({
    required this.id,
    required this.title,
    this.number,
    this.cover,
    required this.url,
    this.issueDate,
  });

  factory MagazineIssue.fromJson(Map<String, dynamic> j) => MagazineIssue(
        id: j['id'] as int,
        title: (j['title'] ?? '') as String,
        number: j['number'] as int?,
        cover: j['cover'] as String?,
        url: (j['url'] ?? '') as String,
        issueDate: j['issue_date'] as String?,
      );
}

final magazineIssuesProvider = FutureProvider<List<MagazineIssue>>((ref) async {
  final data = await ref.read(apiClientProvider).getData('/magazine-issues');
  return (data as List)
      .map((e) => MagazineIssue.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
});
