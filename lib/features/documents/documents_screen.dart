import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/async_value_widget.dart';
import '../../core/widgets/tap_card.dart';
import 'document.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  int? _selectedId; // card col bordino acceso (apre il file → resta finché non tocco altrove)

  @override
  Widget build(BuildContext context) {
    final documents = ref.watch(documentsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Documenti')),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => setState(() => _selectedId = null),
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(documentsProvider),
          child: AsyncValueWidget<List<Document>>(
            value: documents,
            onRetry: () => ref.invalidate(documentsProvider),
            data: (items) => items.isEmpty
                ? const EmptyView('Nessun documento disponibile.')
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _DocumentCard(
                      document: items[i],
                      selected: _selectedId == items[i].id,
                      onSelect: () => setState(() => _selectedId = items[i].id),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final Document document;
  final bool selected;
  final VoidCallback onSelect;
  const _DocumentCard({required this.document, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final hasFile = document.url != null && document.url!.isNotEmpty;
    final primary = Theme.of(context).colorScheme.primary;
    return TapCard(
      selected: selected,
      onTap: () async {
        onSelect();
        if (hasFile) {
          final uri = Uri.tryParse(document.url!);
          if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.description_outlined, color: primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(document.title, style: const TextStyle(color: kNavy, fontWeight: FontWeight.bold, fontSize: 16)),
                  if (document.description != null && document.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(document.description!, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ],
              ),
            ),
            if (hasFile) Icon(Icons.download_rounded, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }
}
