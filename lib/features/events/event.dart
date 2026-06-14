import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class Event {
  final int id;
  final String title;
  final String slug;
  final String? description;
  final String? cover;
  final String? location;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String? registrationUrl;

  Event({
    required this.id,
    required this.title,
    required this.slug,
    this.description,
    this.cover,
    this.location,
    this.startsAt,
    this.endsAt,
    this.registrationUrl,
  });

  bool get hasRegistration => registrationUrl != null && registrationUrl!.isNotEmpty;

  factory Event.fromJson(Map<String, dynamic> j) => Event(
        id: j['id'] as int,
        title: (j['title'] ?? '') as String,
        slug: (j['slug'] ?? '') as String,
        description: j['description'] as String?,
        cover: j['cover'] as String?,
        location: j['location'] as String?,
        startsAt: j['starts_at'] != null ? DateTime.tryParse(j['starts_at']) : null,
        endsAt: j['ends_at'] != null ? DateTime.tryParse(j['ends_at']) : null,
        registrationUrl: j['registration_url'] as String?,
      );
}

final eventsProvider = FutureProvider<List<Event>>((ref) async {
  final data = await ref.read(apiClientProvider).getData('/events');
  return (data as List)
      .map((e) => Event.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
});

final eventDetailProvider = FutureProvider.family<Event, int>((ref, id) async {
  final data = await ref.read(apiClientProvider).getData('/events/$id');
  return Event.fromJson(Map<String, dynamic>.from(data as Map));
});
