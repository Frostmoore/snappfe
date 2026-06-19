import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/util/navigation.dart';
import '../../core/widgets/async_value_widget.dart';
import 'event.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Eventi')),
      body: RefreshIndicator(
        onRefresh: () async {
          // Forza il backend a rileggere dal sito (bypassa la cache 120s) e ripopola,
          // poi rilegge la lista aggiornata.
          try {
            await ref.read(apiClientProvider).getData('/events', query: {'refresh': 1});
          } catch (_) {}
          ref.invalidate(eventsProvider);
        },
        child: AsyncValueWidget<List<Event>>(
          value: events,
          onRetry: () => ref.invalidate(eventsProvider),
          data: (items) => items.isEmpty
              ? const EmptyView('Nessun evento in programma.')
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _EventCard(event: items[i]),
                ),
        ),
      ),
    );
  }
}

/// Etichetta colorata del tipo di evento (Formativo/Politico/Altro).
class _TypeBadge extends StatelessWidget {
  final String label;
  final String? type;
  const _TypeBadge({required this.label, this.type});

  Color get _color {
    switch (type) {
      case 'formativo':
        return const Color(0xFF1E88E5);
      case 'politico':
        return const Color(0xFFE65100);
      default:
        return const Color(0xFF607D8B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: _color, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.5),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM yyyy, HH:mm', 'it');
    return Card(
      child: InkWell(
        onTap: () => pushWithRipple(context, '/events/${event.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.cover != null)
              CachedNetworkImage(imageUrl: event.cover!, height: 150, width: double.infinity, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (event.typeLabel != null && event.typeLabel!.isNotEmpty) ...[
                    _TypeBadge(label: event.typeLabel!, type: event.type),
                    const SizedBox(height: 8),
                  ],
                  Text(event.title, style: const TextStyle(color: kNavy, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  if (event.startsAt != null)
                    Row(children: [
                      const Icon(Icons.event, size: 16),
                      const SizedBox(width: 6),
                      Text(df.format(event.startsAt!)),
                    ]),
                  if (event.place != null) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.map_outlined, size: 16),
                      const SizedBox(width: 6),
                      Expanded(child: Text(event.place!, overflow: TextOverflow.ellipsis)),
                    ]),
                  ],
                  if (event.location != null && event.location!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.place_outlined, size: 16),
                      const SizedBox(width: 6),
                      Expanded(child: Text(event.location!, overflow: TextOverflow.ellipsis)),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
