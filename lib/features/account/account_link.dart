import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/providers.dart';

class AccountLink {
  final int id;
  final String status;
  final String? username;
  final String? level;
  final String? levelLabel;

  AccountLink({
    required this.id,
    required this.status,
    this.username,
    this.level,
    this.levelLabel,
  });

  factory AccountLink.fromJson(Map<String, dynamic> j) {
    final wp = j['wp_account'] is Map ? Map<String, dynamic>.from(j['wp_account']) : null;
    return AccountLink(
      id: j['id'] as int,
      status: (j['status'] ?? '') as String,
      username: wp?['username'] as String?,
      level: wp?['level'] as String?,
      levelLabel: wp?['level_label'] as String?,
    );
  }
}

class AccountRepository {
  final ApiClient api;
  AccountRepository(this.api);

  Future<AccountLink?> status() async {
    final data = await api.getData('/account-links');
    if (data == null) return null;
    return AccountLink.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<AccountLink> link(String identifier, String password) async {
    final data = await api.postData('/account-links', body: {
      'identifier': identifier,
      'password': password,
    });
    return AccountLink.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> unlink() => api.deleteData('/account-links');
}

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(ref.read(apiClientProvider)),
);

final accountLinkProvider = FutureProvider<AccountLink?>((ref) async {
  return ref.read(accountRepositoryProvider).status();
});
