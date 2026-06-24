import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/async_value_widget.dart';
import '../../core/widgets/tap_card.dart';
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
                return RefreshIndicator(
                  // Trascina per ricaricare le sezioni dal backend (dati aggiornati dal pannello).
                  onRefresh: () async {
                    ref.invalidate(provincialSectionsProvider);
                    await ref.read(provincialSectionsProvider.future);
                  },
                  child: filtered.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [SizedBox(height: 100), EmptyView('Nessuna sezione trovata.')],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => _SectionCard(section: filtered[i]),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Card espandibile (angoli vivi, ripple): il titolo è sempre visibile,
/// espandendola appare il contenuto rich-text e si accende il bordino blu.
class _SectionCard extends StatefulWidget {
  final ProvincialSection section;
  const _SectionCard({required this.section});

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    final hasBody = section.body != null && section.body!.trim().isNotEmpty;
    return Card(
      elevation: 3,
      shadowColor: Colors.black54,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero), // angoli vivi
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Theme(
            // Rimuove le righe divisorie di default dell'ExpansionTile dentro la card.
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              onExpansionChanged: (v) => setState(() => _expanded = v),
              // Icona leading nello stile dell'organigramma (cerchio trasparente).
              leading: const CircleAvatar(
                radius: 22,
                backgroundColor: Colors.transparent,
                child: Icon(Icons.location_on_outlined, color: kNavy, size: 26),
              ),
              title: Text(section.name, style: const TextStyle(color: kNavy, fontWeight: FontWeight.bold, fontSize: 16)),
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasBody)
                  HtmlWidget(
                    section.body!,
                    textStyle: const TextStyle(color: Color(0xFF424242), fontSize: 14, height: 1.45),
                  )
                else
                  const Text('Nessuna informazione disponibile.',
                      style: TextStyle(color: Color(0xFF757575), fontStyle: FontStyle.italic, fontSize: 13)),
              ],
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: _expanded ? 4 : 0,
              color: kCardActiveBorder,
            ),
          ),
        ],
      ),
    );
  }
}
