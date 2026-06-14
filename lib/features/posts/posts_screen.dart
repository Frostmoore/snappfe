import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/util/navigation.dart';
import '../../core/widgets/async_value_widget.dart';
import 'post.dart';

class PostsScreen extends ConsumerWidget {
  const PostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(postsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Comunicazioni')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(postsProvider),
        child: AsyncValueWidget<List<Post>>(
          value: posts,
          onRetry: () => ref.invalidate(postsProvider),
          data: (items) => items.isEmpty
              ? const EmptyView('Nessuna comunicazione.')
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _PostCard(post: items[i]),
                ),
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Post post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => pushWithRipple(context, '/posts/${post.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.cover != null)
              CachedNetworkImage(imageUrl: post.cover!, height: 150, width: double.infinity, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.isReserved)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Chip(
                        label: Text('Riservato'),
                        visualDensity: VisualDensity.compact,
                        avatar: Icon(Icons.lock, size: 16),
                      ),
                    ),
                  Text(post.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  if (post.excerpt != null) ...[
                    const SizedBox(height: 6),
                    Text(post.excerpt!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade700)),
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
