import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/widgets/async_value_widget.dart';
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
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.62,
                  ),
                  itemCount: items.length,
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
    return Card(
      child: InkWell(
        onTap: () => launchUrl(Uri.parse(issue.url), mode: LaunchMode.externalApplication),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: issue.cover != null
                  ? CachedNetworkImage(imageUrl: issue.cover!, fit: BoxFit.cover)
                  : Container(color: Colors.grey.shade200, child: const Icon(Icons.menu_book, size: 48)),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(issue.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kNavy, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
