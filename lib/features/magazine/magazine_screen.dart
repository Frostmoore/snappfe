import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/widgets/async_value_widget.dart';
import '../../core/widgets/tap_card.dart';
import 'magazine_issue.dart';

class MagazineScreen extends ConsumerWidget {
  const MagazineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issues = ref.watch(magazineIssuesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text("L'Agente di Assicurazione")),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(magazineIssuesProvider),
        child: AsyncValueWidget<List<MagazineIssue>>(
          value: issues,
          onRetry: () => ref.invalidate(magazineIssuesProvider),
          data: (items) => items.isEmpty
              ? const EmptyView('Nessun numero disponibile.')
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _IssueCard(issue: items[i]),
                ),
        ),
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  final MagazineIssue issue;
  const _IssueCard({required this.issue});

  @override
  Widget build(BuildContext context) {
    return TapCard(
      onTap: () => launchUrl(Uri.parse(issue.url), mode: LaunchMode.externalApplication),
      child: Row(
        children: [
          // Copertina (o icona) a sinistra.
          SizedBox(
            width: 72,
            height: 96,
            child: issue.cover != null
                ? CachedNetworkImage(
                    imageUrl: issue.cover!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.menu_book, color: kNavy),
                    ),
                  )
                : Container(
                    color: kNavy.withValues(alpha: 0.10),
                    child: const Icon(Icons.menu_book, color: kNavy, size: 32),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    issue.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: kNavy, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.open_in_new, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text('Apri il numero', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
