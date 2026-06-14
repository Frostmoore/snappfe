import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class OrgMember {
  final int id;
  final String name;
  final String? role;
  final String? photo;
  final String? email;
  final List<OrgMember> children;

  OrgMember({
    required this.id,
    required this.name,
    this.role,
    this.photo,
    this.email,
    this.children = const [],
  });

  factory OrgMember.fromJson(Map<String, dynamic> j) => OrgMember(
        id: j['id'] as int,
        name: (j['name'] ?? '') as String,
        role: j['role'] as String?,
        photo: j['photo'] as String?,
        email: j['email'] as String?,
        children: (j['children'] as List?)
                ?.map((e) => OrgMember.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
      );
}

final orgChartProvider = FutureProvider<List<OrgMember>>((ref) async {
  final data = await ref.read(apiClientProvider).getData('/org-chart');
  return (data as List)
      .map((e) => OrgMember.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
});
