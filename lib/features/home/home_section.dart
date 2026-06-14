import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class HomeSection {
  final int id;
  final String title;
  final String? subtitle;
  final String route;
  final String layout; // wide | half
  final String? icon;
  final bool isSvg;
  final String? backgroundColor;
  final String? iconColor;

  HomeSection({
    required this.id,
    required this.title,
    this.subtitle,
    required this.route,
    required this.layout,
    this.icon,
    this.isSvg = false,
    this.backgroundColor,
    this.iconColor,
  });

  bool get isWide => layout == 'wide';

  factory HomeSection.fromJson(Map<String, dynamic> j) => HomeSection(
        id: j['id'] as int,
        title: (j['title'] ?? '') as String,
        subtitle: j['subtitle'] as String?,
        route: (j['route'] ?? '/') as String,
        layout: (j['layout'] ?? 'half') as String,
        icon: j['icon'] as String?,
        isSvg: (j['is_svg'] ?? false) as bool,
        backgroundColor: j['background_color'] as String?,
        iconColor: j['icon_color'] as String?,
      );
}

final homeSectionsProvider = FutureProvider<List<HomeSection>>((ref) async {
  final data = await ref.read(apiClientProvider).getData('/app/sections');
  return (data as List)
      .map((e) => HomeSection.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
});
