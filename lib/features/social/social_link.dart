import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class SocialLink {
  final int id;
  final String platform;
  final String? label;
  final String url;
  final String? icon;
  final bool isSvg;
  final String? backgroundColor;
  final String? iconColor;

  SocialLink({
    required this.id,
    required this.platform,
    this.label,
    required this.url,
    this.icon,
    this.isSvg = false,
    this.backgroundColor,
    this.iconColor,
  });

  factory SocialLink.fromJson(Map<String, dynamic> j) => SocialLink(
        id: j['id'] as int,
        platform: (j['platform'] ?? '') as String,
        label: j['label'] as String?,
        url: (j['url'] ?? '') as String,
        icon: j['icon'] as String?,
        isSvg: (j['is_svg'] ?? false) as bool,
        backgroundColor: j['background_color'] as String?,
        iconColor: j['icon_color'] as String?,
      );
}

final socialLinksProvider = FutureProvider<List<SocialLink>>((ref) async {
  final data = await ref.read(apiClientProvider).getData('/app/social-links');
  return (data as List)
      .map((e) => SocialLink.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
});
