import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/async_value_widget.dart';
import 'org_member.dart';

class OrgChartScreen extends ConsumerWidget {
  const OrgChartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(orgChartProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Organigramma')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(orgChartProvider),
        child: AsyncValueWidget<List<OrgGroup>>(
          value: groups,
          onRetry: () => ref.invalidate(orgChartProvider),
          data: (list) {
            if (list.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [SizedBox(height: 100), EmptyView('Organigramma non disponibile.')],
              );
            }
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                for (final g in list) ...[
                  _SectionHeader(group: g),
                  for (final m in g.members)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MemberCard(member: m),
                    ),
                  const SizedBox(height: 16),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Intestazione di sezione: titolo (navy) + descrizione (come sul sito).
class _SectionHeader extends StatelessWidget {
  final OrgGroup group;
  const _SectionHeader({required this.group});

  @override
  Widget build(BuildContext context) {
    final hasDescription = group.description != null && group.description!.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 22, decoration: BoxDecoration(color: kNavy, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  group.title,
                  style: const TextStyle(color: kNavy, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          if (hasDescription) ...[
            const SizedBox(height: 8),
            Text(
              group.description!,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13.5, height: 1.45),
            ),
          ],
        ],
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
