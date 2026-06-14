import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
        onRefresh: () async => ref.invalidate(eventsProvider),
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
                  Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  if (event.startsAt != null)
                    Row(children: [
                      const Icon(Icons.event, size: 16),
                      const SizedBox(width: 6),
                      Text(df.format(event.startsAt!.toLocal())),
                    ]),
                  if (event.location != null) ...[
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
