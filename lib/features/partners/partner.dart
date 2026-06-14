import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class Partner {
  final int id;
  final String name;
  final String type; // convenzione | partner
  final String? logo;
  final String? url;
  final String? description;

  Partner({
    required this.id,
    required this.name,
    required this.type,
    this.logo,
    this.url,
    this.description,
  });

  factory Partner.fromJson(Map<String, dynamic> j) => Partner(
        id: j['id'] as int,
        name: (j['name'] ?? '') as String,
        type: (j['type'] ?? 'partner') as String,
        logo: j['logo'] as String?,
        url: j['url'] as String?,
        description: j['description'] as String?,
      );
}

final partnersProvider = FutureProvider<List<Partner>>((ref) async {
  final data = await ref.read(apiClientProvider).getData('/partners');
  return (data as List)
      .map((e) => Partner.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
});
