import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class ReservedTile {
  final int id;
  final String title;
  final String? subtitle;
  final String? icon; // url immagine
  final String? color; // hex

  ReservedTile({required this.id, required this.title, this.subtitle, this.icon, this.color});

  factory ReservedTile.fromJson(Map<String, dynamic> j) => ReservedTile(
        id: j['id'] as int,
        title: (j['title'] ?? '') as String,
        subtitle: j['subtitle'] as String?,
        icon: j['icon'] as String?,
        color: j['color'] as String?,
      );
}

class ReservedElement {
  final int id;
  final String title;
  final String? description;
  final String? downloadUrl;

  ReservedElement({required this.id, required this.title, this.description, this.downloadUrl});

  factory ReservedElement.fromJson(Map<String, dynamic> j) => ReservedElement(
        id: j['id'] as int,
        title: (j['title'] ?? '') as String,
        description: j['description'] as String?,
        downloadUrl: j['download_url'] as String?,
      );
}

class ReservedSection {
  final int id;
  final String title;
  final List<ReservedElement> elements;

  ReservedSection({required this.id, required this.title, this.elements = const []});

  factory ReservedSection.fromJson(Map<String, dynamic> j) => ReservedSection(
        id: j['id'] as int,
        title: (j['title'] ?? '') as String,
        elements: (j['elements'] as List?)
                ?.map((e) => ReservedElement.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
      );
}

class ReservedTileDetail {
  final int id;
  final String title;
  final String? subtitle;
  final List<ReservedSection> sections;

  ReservedTileDetail({required this.id, required this.title, this.subtitle, this.sections = const []});

  factory ReservedTileDetail.fromJson(Map<String, dynamic> j) => ReservedTileDetail(
        id: j['id'] as int,
        title: (j['title'] ?? '') as String,
        subtitle: j['subtitle'] as String?,
        sections: (j['sections'] as List?)
                ?.map((e) => ReservedSection.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
      );
}

final reservedTilesProvider = FutureProvider.autoDispose<List<ReservedTile>>((ref) async {
  final data = await ref.read(apiClientProvider).getData('/reserved/tiles');
  return (data as List).map((e) => ReservedTile.fromJson(Map<String, dynamic>.from(e as Map))).toList();
});

final reservedTileProvider = FutureProvider.autoDispose.family<ReservedTileDetail, int>((ref, id) async {
  final data = await ref.read(apiClientProvider).getData('/reserved/tiles/$id');
  return ReservedTileDetail.fromJson(Map<String, dynamic>.from(data as Map));
});
