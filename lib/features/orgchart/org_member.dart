import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class OrgMember {
  final int id;
  final String name;
  final String? role;
  final String? note; // testo libero sotto il ruolo
  final String? link; // se valorizzato, il tap apre questo link
  final String? photo;
  final String? email;

  OrgMember({
    required this.id,
    required this.name,
    this.role,
    this.note,
    this.link,
    this.photo,
    this.email,
  });

  factory OrgMember.fromJson(Map<String, dynamic> j) => OrgMember(
        id: j['id'] as int,
        name: (j['name'] ?? '') as String,
        role: j['role'] as String?,
        note: j['note'] as String?,
        link: j['link'] as String?,
        photo: j['photo'] as String?,
        email: j['email'] as String?,
      );
}

/// Sezione dell'organigramma (es. "Direzione") con sottotitolo, descrizione e membri.
class OrgGroup {
  final String title;
  final String? subtitle;
  final String? description;
  final List<OrgMember> members;

  OrgGroup({required this.title, this.subtitle, this.description, required this.members});

  factory OrgGroup.fromJson(Map<String, dynamic> j) => OrgGroup(
        title: (j['group'] ?? '') as String,
        subtitle: j['subtitle'] as String?,
        description: j['description'] as String?,
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
