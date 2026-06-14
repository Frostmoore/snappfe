import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class AppSettings {
  final String? appName;
  final String? headerImage;
  final String? headerVideo;
  final String? logo;
  final String? primaryColor;

  AppSettings({this.appName, this.headerImage, this.headerVideo, this.logo, this.primaryColor});

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        appName: j['app_name'] as String?,
        headerImage: j['header_image'] as String?,
        headerVideo: j['header_video'] as String?,
        logo: j['logo'] as String?,
        primaryColor: j['primary_color'] as String?,
      );
}

final appSettingsProvider = FutureProvider<AppSettings>((ref) async {
  final data = await ref.read(apiClientProvider).getData('/app/settings');
  return AppSettings.fromJson(Map<String, dynamic>.from(data as Map));
});
