import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/widgets/async_value_widget.dart';
import 'reserved_tile.dart';

/// Dettaglio di una tile dell'area riservata: sezioni con elementi da scaricare.
class ReservedTileScreen extends ConsumerWidget {
  final int id;
  const ReservedTileScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(reservedTileProvider(id));

    return Scaffold(
      appBar: AppBar(title: Text(detail.value?.title ?? 'Area riservata')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(reservedTileProvider(id)),
        child: AsyncValueWidget<ReservedTileDetail>(
          value: detail,
          onRetry: () => ref.invalidate(reservedTileProvider(id)),
          data: (tile) {
            if (tile.sections.isEmpty) {
              return const EmptyView('Nessun contenuto in questa sezione.');
            }
            return ListView(
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
                    ...section.elements.map((e) => _ElementCard(element: e)),
                  const SizedBox(height: 8),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ElementCard extends StatelessWidget {
  final ReservedElement element;
  const _ElementCard({required this.element});

  Future<void> _open(BuildContext context) async {
    final url = element.downloadUrl;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = element.downloadUrl != null;
    return Card(
      child: ListTile(
        leading: Icon(hasFile ? Icons.download_rounded : Icons.description_outlined,
            color: Theme.of(context).colorScheme.primary),
        title: Text(element.title, style: const TextStyle(color: kNavy, fontWeight: FontWeight.w600)),
        subtitle: (element.description != null && element.description!.isNotEmpty)
            ? Text(element.description!)
            : null,
        trailing: hasFile ? const Icon(Icons.chevron_right) : null,
        onTap: hasFile ? () => _open(context) : null,
      ),
    );
  }
}
