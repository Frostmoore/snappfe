import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class OrgMember {
  final int id;
  final String name;
  final String? role;
  final String? photo;
  final String? email;

  OrgMember({
    required this.id,
    required this.name,
    this.role,
    this.photo,
    this.email,
  });

  factory OrgMember.fromJson(Map<String, dynamic> j) => OrgMember(
        id: j['id'] as int,
        name: (j['name'] ?? '') as String,
        role: j['role'] as String?,
        photo: j['photo'] as String?,
        email: j['email'] as String?,
      );
}

/// Sezione dell'organigramma (es. "Direzione") con i suoi membri.
class OrgGroup {
  final String title;
  final List<OrgMember> members;

  OrgGroup({required this.title, required this.members});

  factory OrgGroup.fromJson(Map<String, dynamic> j) => OrgGroup(
        title: (j['group'] ?? '') as String,
        members: (j['members'] as List?)
                ?.map((e) => OrgMember.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
      );
}

final orgChartProvider = FutureProvider<List<OrgGroup>>((ref) async {
  final data = await ref.read(apiClientProvider).getData('/org-chart');
  return (data as List)
      .map((e) => OrgGroup.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
});
