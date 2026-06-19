import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/util/navigation.dart';
import '../../core/widgets/async_value_widget.dart';
import 'event.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  DateTime? _fromDate; // mostra gli eventi a partire da questa data
  String? _type;
  String? _region;
  String? _province;

  bool get _hasFilters => _fromDate != null || _type != null || _region != null || _province != null;

  Future<void> _refresh() async {
    // Forza il backend a rileggere dal sito (bypassa la cache 120s) e ripopola.
    try {
      await ref.read(apiClientProvider).getData('/events', query: {'refresh': 1});
    } catch (_) {}
    ref.invalidate(eventsProvider);
  }

  List<Event> _applyFilters(List<Event> items) {
    return items.where((e) {
      if (_type != null && e.type != _type) return false;
      if (_region != null && e.region != _region) return false;
      if (_province != null && e.province != _province) return false;
      if (_fromDate != null) {
        if (e.startsAt == null) return false;
        final d = DateTime(e.startsAt!.year, e.startsAt!.month, e.startsAt!.day);
        if (d.isBefore(_fromDate!)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Eventi')),
      body: AsyncValueWidget<List<Event>>(
        value: events,
        onRetry: () => ref.invalidate(eventsProvider),
        data: (all) {
          final filtered = _applyFilters(all);
          return Column(
            children: [
              if (all.isNotEmpty) _buildFilters(all),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: filtered.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 100),
                            EmptyView(all.isEmpty
                                ? 'Nessun evento in programma.'
                                : 'Nessun evento con i filtri selezionati.'),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => _EventCard(event: filtered[i]),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Barra filtri (combinabili) -------------------------------------------

  Widget _buildFilters(List<Event> all) {
    final typeOptions = <String, String>{};
    for (final e in all) {
      if (e.type != null && e.type!.isNotEmpty) typeOptions[e.type!] = e.typeLabel ?? e.type!;
    }
    final regionOptions = all.map((e) => e.region).whereType<String>().where((r) => r.isNotEmpty).toSet().toList()..sort();
    final provinceSource = _region == null ? all : all.where((e) => e.region == _region);
    final provinceOptions = provinceSource.map((e) => e.province).whereType<String>().where((p) => p.isNotEmpty).toSet().toList()..sort();

    return Material(
      elevation: 1,
      child: SizedBox(
        height: 56,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          children: [
            _dateChip(),
            if (typeOptions.isNotEmpty) ...[
              const SizedBox(width: 8),
              _menuChip(
                label: 'Tipo',
                value: _type,
                display: _type == null ? null : (typeOptions[_type] ?? _type),
                options: typeOptions,
                onPick: (v) => setState(() => _type = v),
              ),
            ],
            if (regionOptions.isNotEmpty) ...[
              const SizedBox(width: 8),
              _menuChip(
                label: 'Regione',
                value: _region,
                display: _region,
                options: {for (final r in regionOptions) r: r},
                onPick: (v) => setState(() {
                  _region = v;
                  _province = null; // la provincia dipende dalla regione
                }),
              ),
            ],
            if (provinceOptions.isNotEmpty) ...[
              const SizedBox(width: 8),
              _menuChip(
                label: 'Provincia',
                value: _province,
                display: _province,
                options: {for (final p in provinceOptions) p: p},
                onPick: (v) => setState(() => _province = v),
              ),
            ],
            if (_hasFilters) ...[
              const SizedBox(width: 8),
              ActionChip(
                avatar: const Icon(Icons.clear, size: 16),
                label: const Text('Pulisci'),
                onPressed: () => setState(() {
                  _fromDate = null;
                  _type = null;
                  _region = null;
                  _province = null;
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dateChip() {
    final active = _fromDate != null;
    final text = active ? 'Dal ${DateFormat('d MMM yyyy', 'it').format(_fromDate!)}' : 'Data';
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: _fromDate ?? now,
          firstDate: DateTime(now.year - 1),
          lastDate: DateTime(now.year + 3),
        );
        if (picked != null) setState(() => _fromDate = DateTime(picked.year, picked.month, picked.day));
      },
      child: _chipBox(text, active, trailingIcon: Icons.calendar_today),
    );
  }

  Widget _menuChip({
    required String label,
    required String? value,
    String? display,
    required Map<String, String> options,
    required ValueChanged<String?> onPick,
  }) {
    final active = value != null;
    return PopupMenuButton<String>(
      tooltip: label,
      onSelected: (v) => onPick(v.isEmpty ? null : v),
      itemBuilder: (_) => [
        const PopupMenuItem(value: '', child: Text('Tutti')),
        ...options.entries.map((e) => PopupMenuItem(value: e.key, child: Text(e.value))),
      ],
      child: _chipBox(active ? (display ?? value) : label, active, trailingIcon: Icons.arrow_drop_down),
    );
  }

  Widget _chipBox(String text, bool active, {IconData? trailingIcon}) {
    final color = active ? kNavy : Colors.grey.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? kNavy.withValues(alpha: 0.10) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? kNavy : Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: TextStyle(color: color, fontWeight: active ? FontWeight.w700 : FontWeight.w500, fontSize: 13)),
          if (trailingIcon != null) Icon(trailingIcon, size: 18, color: color),
        ],
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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => pushWithRipple(context, '/events/${event.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.cover != null)
              // Copertina a piena altezza (non croppata): larghezza piena, altezza
              // proporzionale all'immagine.
              CachedNetworkImage(imageUrl: event.cover!, width: double.infinity, fit: BoxFit.fitWidth),
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
