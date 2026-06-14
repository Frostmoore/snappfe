import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/util/html.dart';
import '../../core/widgets/async_value_widget.dart';
import 'article.dart';

class ArticleDetailScreen extends ConsumerWidget {
  final int id;
  const ArticleDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final article = ref.watch(articleDetailProvider(id));
    return Scaffold(
      appBar: AppBar(title: const Text('Articolo')),
      body: AsyncValueWidget<Article>(
        value: article,
        onRetry: () => ref.invalidate(articleDetailProvider(id)),
        data: (a) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (a.image != null)
              ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: a.image!)),
            const SizedBox(height: 16),
            Text(a.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            if (a.author != null) ...[
              const SizedBox(height: 6),
              Text('di ${a.author}', style: TextStyle(color: Colors.grey.shade600)),
            ],
            const SizedBox(height: 12),
            Text(stripHtml(a.content ?? a.excerpt), style: const TextStyle(fontSize: 16, height: 1.5)),
            if (a.link != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => launchUrl(Uri.parse(a.link!), mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Apri sul sito'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
