import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/async_value_widget.dart';
import 'org_member.dart';

class OrgChartScreen extends ConsumerWidget {
  const OrgChartScreen({super.key});

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
          data: (roots) => roots.isEmpty
              ? const EmptyView('Organigramma non disponibile.')
              : ListView(
                  padding: const EdgeInsets.all(8),
                  children: roots.map((m) => _MemberNode(member: m)).toList(),
                ),
        ),
      ),
    );
  }
}

class _MemberNode extends StatelessWidget {
  final OrgMember member;
  const _MemberNode({required this.member});

  Widget _avatar() => CircleAvatar(
        backgroundImage: member.photo != null ? CachedNetworkImageProvider(member.photo!) : null,
        child: member.photo == null ? Text(member.name.isNotEmpty ? member.name[0] : '?') : null,
      );

  @override
  Widget build(BuildContext context) {
    if (member.children.isEmpty) {
      return ListTile(
        leading: _avatar(),
        title: Text(member.name),
        subtitle: member.role != null ? Text(member.role!) : null,
      );
    }
    return ExpansionTile(
      leading: _avatar(),
      title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: member.role != null ? Text(member.role!) : null,
      childrenPadding: const EdgeInsets.only(left: 16),
      children: member.children.map((c) => _MemberNode(member: c)).toList(),
    );
  }
}
