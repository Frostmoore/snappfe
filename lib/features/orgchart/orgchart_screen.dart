import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/async_value_widget.dart';
import 'org_member.dart';

class OrgChartScreen extends ConsumerWidget {
  const OrgChartScreen({super.key});

  /// Appiattisce l'albero (DFS) così tutti i ruoli sono visibili subito, in ordine.
  List<OrgMember> _flatten(List<OrgMember> members) {
    final out = <OrgMember>[];
    void visit(OrgMember m) {
      out.add(m);
      for (final c in m.children) {
        visit(c);
      }
    }
    for (final m in members) {
      visit(m);
    }
    return out;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tree = ref.watch(orgChartProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Organigramma')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(orgChartProvider),
        child: AsyncValueWidget<List<OrgMember>>(
          value: tree,
          onRetry: () => ref.invalidate(orgChartProvider),
          data: (roots) {
            final members = _flatten(roots);
            if (members.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [SizedBox(height: 100), EmptyView('Organigramma non disponibile.')],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: members.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _MemberCard(member: members[i]),
            );
          },
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final OrgMember member;
  const _MemberCard({required this.member});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: kNavy.withValues(alpha: 0.10),
              backgroundImage: member.photo != null ? CachedNetworkImageProvider(member.photo!) : null,
              child: member.photo == null
                  ? Text(
                      member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: kNavy, fontWeight: FontWeight.bold, fontSize: 20),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.name, style: const TextStyle(color: kNavy, fontWeight: FontWeight.bold, fontSize: 16)),
                  if (member.role != null && member.role!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(member.role!, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
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
