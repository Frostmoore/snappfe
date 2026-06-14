import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

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
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.location_on_outlined)),
      title: Text(section.name),
      subtitle: Text([section.province, section.address].where((e) => e != null && e.isNotEmpty).join(' · ')),
      trailing: section.phone != null
          ? IconButton(
              icon: const Icon(Icons.phone),
              onPressed: () => launchUrl(Uri.parse('tel:${section.phone}')),
            )
          : null,
      onTap: section.website != null
          ? () => launchUrl(Uri.parse(section.website!), mode: LaunchMode.externalApplication)
          : null,
    );
  }
}
