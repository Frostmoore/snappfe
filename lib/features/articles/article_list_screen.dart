import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/util/navigation.dart';
import '../../core/widgets/async_value_widget.dart';
import 'article.dart';

class ArticleListScreen extends ConsumerStatefulWidget {
  final bool newsletters;
  const ArticleListScreen({super.key, this.newsletters = false});

  @override
  ConsumerState<ArticleListScreen> createState() => _ArticleListScreenState();
}

class _ArticleListScreenState extends ConsumerState<ArticleListScreen> {
  final _scroll = ScrollController();

  String get _endpoint => widget.newsletters ? '/newsletters' : '/articles';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Carica la pagina successiva quando mancano ~600px alla fine.
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 600) {
      ref.read(articlesPagedProvider(_endpoint).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(articlesPagedProvider(_endpoint));
    final notifier = ref.read(articlesPagedProvider(_endpoint).notifier);
    final title = widget.newsletters ? 'Newsletter' : 'Articoli';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _buildBody(context, state, notifier),
    );
  }

  Widget _buildBody(BuildContext context, PagedArticles state, ArticlesNotifier notifier) {
    // Primo caricamento
    if (state.loadingInitial) {
      return const Center(
        child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()),
      );
    }
    // Errore sul primo caricamento (lista vuota)
    if (state.initialError != null && state.items.isEmpty) {
      return ErrorView(message: state.initialError.toString(), onRetry: notifier.loadInitial);
    }
    // Vuoto
    if (state.items.isEmpty) {
      return EmptyView(widget.newsletters ? 'Nessuna newsletter.' : 'Nessun articolo.');
    }

    // Lista con footer (loader / retry / fine elenco)
    return RefreshIndicator(
      onRefresh: notifier.loadInitial,
      child: ListView.separated(
        controller: _scroll,
        padding: const EdgeInsets.all(16),
        itemCount: state.items.length + 1, // +1 per il footer
        separatorBuilder: (_, i) => i < state.items.length - 1
            ? const SizedBox(height: 12)
            : const SizedBox.shrink(),
        itemBuilder: (_, i) {
          if (i < state.items.length) {
            return _ArticleCard(article: state.items[i]);
          }
          return _Footer(state: state, onRetry: notifier.loadMore);
        },
      ),
    );
  }
}

/// Footer della lista: spinner durante il caricamento, retry su errore,
/// nulla quando non c'è altro da caricare.
class _Footer extends StatelessWidget {
  final PagedArticles state;
  final VoidCallback onRetry;
  const _Footer({required this.state, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    if (state.loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))),
      );
    }
    if (state.moreError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Carica altri'),
          ),
        ),
      );
    }
    if (!state.hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text('Fine', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ),
      );
    }
    return const SizedBox(height: 8);
  }
}

class _ArticleCard extends StatelessWidget {
  final Article article;
  const _ArticleCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => pushWithRipple(context, '/articles/${article.id}'),
        child: Row(
          children: [
            if (article.image != null)
              CachedNetworkImage(
                imageUrl: article.image!,
                width: 100,
                height: 104,
                fit: BoxFit.cover,
                memCacheWidth: 240,
                placeholder: (_, __) => const SizedBox(
                  width: 100,
                  height: 104,
                  child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 100,
                  height: 104,
                  color: Colors.grey.shade200,
                  child: Icon(Icons.image_not_supported_outlined, color: Colors.grey.shade400),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(article.title, style: const TextStyle(color: kNavy, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (article.excerpt != null) ...[
                      const SizedBox(height: 6),
                      Text(article.excerpt!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
