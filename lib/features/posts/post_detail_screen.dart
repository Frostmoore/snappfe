import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/util/html.dart';
import '../../core/widgets/async_value_widget.dart';
import 'post.dart';

class PostDetailScreen extends ConsumerWidget {
  final int id;
  const PostDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final post = ref.watch(postDetailProvider(id));
    return Scaffold(
      appBar: AppBar(title: const Text('Comunicazione')),
      body: AsyncValueWidget<Post>(
        value: post,
        onRetry: () => ref.invalidate(postDetailProvider(id)),
        data: (p) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (p.cover != null)
              ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: p.cover!)),
            const SizedBox(height: 16),
            Text(p.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(stripHtml(p.body), style: const TextStyle(fontSize: 16, height: 1.5)),
            if (p.externalUrl != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => launchUrl(Uri.parse(p.externalUrl!), mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Apri'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
