import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class ProvincialSection {
  final int id;
  final String name;
  final String? province;
  final String? region;
  final String? address;
  final String? email;
  final String? phone;
  final String? website;
  final String? notes;

  ProvincialSection({
    required this.id,
    required this.name,
    this.province,
    this.region,
    this.address,
    this.email,
    this.phone,
    this.website,
    this.notes,
  });

  factory ProvincialSection.fromJson(Map<String, dynamic> j) => ProvincialSection(
        id: j['id'] as int,
        name: (j['name'] ?? '') as String,
        province: j['province'] as String?,
        region: j['region'] as String?,
        address: j['address'] as String?,
        email: j['email'] as String?,
        phone: j['phone'] as String?,
        website: j['website'] as String?,
        notes: j['notes'] as String?,
      );
}

final provincialSectionsProvider = FutureProvider<List<ProvincialSection>>((ref) async {
  final data = await ref.read(apiClientProvider).getData('/provincial-sections');
  return (data as List)
      .map((e) => ProvincialSection.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
});
