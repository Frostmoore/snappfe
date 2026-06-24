import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/widgets/async_value_widget.dart';
import '../../core/widgets/tap_card.dart';
import 'reserved_tile.dart';

/// Dettaglio di una tile dell'area riservata: sezioni con elementi da scaricare.
class ReservedTileScreen extends ConsumerStatefulWidget {
  final int id;
  const ReservedTileScreen({super.key, required this.id});

  @override
  ConsumerState<ReservedTileScreen> createState() => _ReservedTileScreenState();
}

class _ReservedTileScreenState extends ConsumerState<ReservedTileScreen> {
  int? _selectedId; // elemento col bordino acceso (apre file → resta finché non tocco altrove)

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(reservedTileProvider(widget.id));

    return Scaffold(
      appBar: AppBar(title: Text(detail.value?.title ?? 'Area riservata')),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => setState(() => _selectedId = null),
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(reservedTileProvider(widget.id)),
          child: AsyncValueWidget<ReservedTileDetail>(
            value: detail,
            onRetry: () => ref.invalidate(reservedTileProvider(widget.id)),
            data: (tile) {
              if (tile.sections.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [SizedBox(height: 100), EmptyView('Nessun contenuto in questa sezione.')],
                );
              }
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  for (final section in tile.sections) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: Text(section.title, style: const TextStyle(color: kNavy, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    if (section.elements.isEmpty)
                      Text('—', style: TextStyle(color: Colors.grey.shade500))
                    else
                      ...section.elements.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ElementCard(
                              element: e,
                              selected: _selectedId == e.id,
                              onSelect: () => setState(() => _selectedId = e.id),
                            ),
                          )),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ElementCard extends StatelessWidget {
  final ReservedElement element;
  final bool selected;
  final VoidCallback onSelect;
  const _ElementCard({required this.element, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final hasFile = element.downloadUrl != null;
    final primary = Theme.of(context).colorScheme.primary;
    final content = Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(hasFile ? Icons.download_rounded : Icons.description_outlined, color: primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(element.title, style: const TextStyle(color: kNavy, fontWeight: FontWeight.w600, fontSize: 15)),
                if (element.description != null && element.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(element.description!, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                ],
              ],
            ),
          ),
          if (hasFile) Icon(Icons.chevron_right, color: Colors.grey.shade500),
        ],
      ),
    );

    // Elemento senza file: card statica (stile coerente, senza interazione).
    if (!hasFile) {
      return Card(
        elevation: 3,
        shadowColor: Colors.black54,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        clipBehavior: Clip.antiAlias,
        child: content,
      );
    }

    return TapCard(
      selected: selected,
      onTap: () async {
        onSelect(); // accende il bordino (resta finché non tocco altrove)
        final uri = Uri.tryParse(element.downloadUrl!);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: content,
    );
  }
}
