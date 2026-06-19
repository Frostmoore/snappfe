import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/async_value_widget.dart';
import 'provincial_section.dart';

class ProvincialScreen extends ConsumerStatefulWidget {
  const ProvincialScreen({super.key});

  @override
  ConsumerState<ProvincialScreen> createState() => _ProvincialScreenState();
}

class _ProvincialScreenState extends ConsumerState<ProvincialScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final sections = ref.watch(provincialSectionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Sezioni provinciali')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(hintText: 'Cerca per nome o provincia', prefixIcon: Icon(Icons.search)),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: AsyncValueWidget<List<ProvincialSection>>(
              value: sections,
              onRetry: () => ref.invalidate(provincialSectionsProvider),
              data: (items) {
                final filtered = _query.isEmpty
                    ? items
                    : items.where((s) =>
                        s.name.toLowerCase().contains(_query) ||
                        (s.province?.toLowerCase().contains(_query) ?? false)).toList();
                if (filtered.isEmpty) return const EmptyView('Nessuna sezione trovata.');
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) => _SectionTile(section: filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  final ProvincialSection section;
  const _SectionTile({required this.section});

  @override
  Widget build(BuildContext context) {
    final grey = Colors.grey.shade600;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titolo: grassetto, stesso colore degli altri titoli.
          Text(section.name, style: const TextStyle(color: kNavy, fontWeight: FontWeight.bold, fontSize: 16)),
          if (section.textBold != null && section.textBold!.isNotEmpty) ...[
            const SizedBox(height: 5),
            // Testo libero più piccolo, grigio grassetto.
            Text(section.textBold!, style: TextStyle(color: grey, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
          if (section.textItalic != null && section.textItalic!.isNotEmpty) ...[
            const SizedBox(height: 3),
            // Testo libero, stessa dimensione, grigio corsivo.
            Text(section.textItalic!, style: TextStyle(color: grey, fontStyle: FontStyle.italic, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}
