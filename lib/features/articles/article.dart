import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/providers.dart';
import '../../core/util/html.dart';

class Article {
  final int id;
  final String title;
  final String? excerpt;
  final String? image;
  final String? link;
  final String? author;
  final List<String> categories;
  final String? content;
  final String? publishedAt;

  Article({
    required this.id,
    required this.title,
    this.excerpt,
    this.image,
    this.link,
    this.author,
    this.categories = const [],
    this.content,
    this.publishedAt,
  });

  factory Article.fromJson(Map<String, dynamic> j) => Article(
        id: j['id'] as int,
        title: unescapeHtml((j['title'] ?? '') as String),
        excerpt: j['excerpt'] != null ? stripHtml(j['excerpt'] as String) : null,
        image: j['image'] as String?,
        link: j['link'] as String?,
        author: j['author'] != null ? unescapeHtml(j['author'] as String) : null,
        categories: (j['categories'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        content: j['content'] as String?,
        publishedAt: j['published_at'] as String?,
      );
}

/// Stato di una lista paginata di articoli (infinite scroll).
class PagedArticles {
  final List<Article> items;
  final int nextPage; // prossima pagina da caricare
  final int totalPages; // dal meta del backend
  final bool loadingInitial; // primo caricamento (lista ancora vuota)
  final bool loadingMore; // caricamento di una pagina successiva
  final Object? initialError; // errore sul primo caricamento
  final Object? moreError; // errore caricando una pagina successiva

  const PagedArticles({
    this.items = const [],
    this.nextPage = 1,
    this.totalPages = 1,
    this.loadingInitial = true,
    this.loadingMore = false,
    this.initialError,
    this.moreError,
  });

  bool get hasMore => nextPage <= totalPages;

  PagedArticles copyWith({
    List<Article>? items,
    int? nextPage,
    int? totalPages,
    bool? loadingInitial,
    bool? loadingMore,
    Object? initialError,
    Object? moreError,
    bool clearMoreError = false,
  }) =>
      PagedArticles(
        items: items ?? this.items,
        nextPage: nextPage ?? this.nextPage,
        totalPages: totalPages ?? this.totalPages,
        loadingInitial: loadingInitial ?? this.loadingInitial,
        loadingMore: loadingMore ?? this.loadingMore,
        initialError: initialError ?? this.initialError,
        moreError: clearMoreError ? null : (moreError ?? this.moreError),
      );
}

/// Carica una lista di articoli a pagine, accumulando i risultati.
/// `endpoint` è `/articles` (sito) oppure `/newsletters`.
class ArticlesNotifier extends StateNotifier<PagedArticles> {
  ArticlesNotifier(this._api, this._endpoint) : super(const PagedArticles()) {
    loadInitial();
  }

  final ApiClient _api;
  final String _endpoint;
  static const _perPage = 15;

  List<Article> _parse(dynamic data) => (data as List? ?? const [])
      .map((e) => Article.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();

  int _totalPages(Map<String, dynamic> res, int fallback) {
    final meta = res['meta'];
    final tp = meta is Map ? meta['total_pages'] : null;
    return (tp is int && tp > 0) ? tp : fallback;
  }

  Future<void> loadInitial() async {
    state = const PagedArticles(loadingInitial: true);
    try {
      final res = await _api.getRaw(_endpoint, query: {'page': 1, 'per_page': _perPage});
      state = PagedArticles(
        items: _parse(res['data']),
        nextPage: 2,
        totalPages: _totalPages(res, 1),
        loadingInitial: false,
      );
    } catch (e) {
      state = PagedArticles(loadingInitial: false, initialError: e);
    }
  }

  Future<void> loadMore() async {
    if (state.loadingInitial || state.loadingMore || !state.hasMore) return;
    state = state.copyWith(loadingMore: true, clearMoreError: true);
    try {
      final res = await _api.getRaw(_endpoint, query: {'page': state.nextPage, 'per_page': _perPage});
      state = state.copyWith(
        items: [...state.items, ..._parse(res['data'])],
        nextPage: state.nextPage + 1,
        totalPages: _totalPages(res, state.totalPages),
        loadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(loadingMore: false, moreError: e);
    }
  }
}

/// Family per endpoint: '/articles' o '/newsletters'.
final articlesPagedProvider =
    StateNotifierProvider.autoDispose.family<ArticlesNotifier, PagedArticles, String>(
  (ref, endpoint) => ArticlesNotifier(ref.read(apiClientProvider), endpoint),
);

final articleDetailProvider = FutureProvider.family<Article, int>((ref, id) async {
  final data = await ref.read(apiClientProvider).getData('/articles/$id');
  return Article.fromJson(Map<String, dynamic>.from(data as Map));
});
