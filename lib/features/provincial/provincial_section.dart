import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class ProvincialSection {
  final int id;
  final String name;
  final String? body; // contenuto rich-text (HTML) libero
  final String? province;
  final String? region;

  ProvincialSection({
    required this.id,
    required this.name,
    this.body,
    this.province,
    this.region,
  });

  factory ProvincialSection.fromJson(Map<String, dynamic> j) => ProvincialSection(
        id: j['id'] as int,
        name: (j['name'] ?? '') as String,
        body: j['body'] as String?,
        province: j['province'] as String?,
        region: j['region'] as String?,
      );
}

final provincialSectionsProvider = FutureProvider<List<ProvincialSection>>((ref) async {
  final data = await ref.read(apiClientProvider).getData('/provincial-sections');
  return (data as List)
      .map((e) => ProvincialSection.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
});
