import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/util/navigation.dart';
import '../../core/widgets/async_value_widget.dart';
import '../auth/auth.dart';
import 'reserved_tile.dart';

/// Area riservata: griglia di tiles costruite dal pannello, filtrate per ruolo SNA.
class ReservedAreaScreen extends ConsumerWidget {
  const ReservedAreaScreen({super.key});

  Color? _parseColor(String? hex) {
    if (hex == null) return null;
    var h = hex.replaceAll('#', '').trim();
    if (h.length == 6) h = 'FF$h';
    final v = int.tryParse(h, radix: 16);
    return v == null ? null : Color(v);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Area riservata')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                const Text('Accedi per entrare nell\'area riservata.', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: () => context.push('/login'), child: const Text('Accedi')),
              ],
            ),
          ),
        ),
      );
    }

    final tiles = ref.watch(reservedTilesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Area riservata'),
        actions: [
          IconButton(
            tooltip: 'Account',
            icon: const Icon(Icons.manage_accounts_outlined),
            onPressed: () => context.push('/account/settings'),
          ),
          IconButton(
            tooltip: 'Esci',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go('/');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(reservedTilesProvider),
        child: AsyncValueWidget<List<ReservedTile>>(
          value: tiles,
          onRetry: () => ref.invalidate(reservedTilesProvider),
          data: (items) {
            final notLinked = user.wpRole == null;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (notLinked)
                  Card(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: ListTile(
                      leading: const Icon(Icons.link),
                      title: const Text('Collega il tuo account SNA'),
                      subtitle: const Text('Per vedere i contenuti riservati al tuo ruolo.'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/account/settings'),
                    ),
                  ),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text('Nessun contenuto disponibile.', style: TextStyle(color: Colors.grey.shade600)),
                    ),
                  )
                else
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1,
                    children: items.map((t) => _TileCard(tile: t, bg: _parseColor(t.color))).toList(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TileCard extends StatelessWidget {
  final ReservedTile tile;
  final Color? bg;
  const _TileCard({required this.tile, this.bg});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: bg,
      child: InkWell(
        onTap: () => pushWithRipple(context, '/reserved/tiles/${tile.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (tile.icon != null)
                CachedNetworkImage(imageUrl: tile.icon!, width: 48, height: 48, fit: BoxFit.contain)
              else
                Icon(Icons.folder_open, size: 44, color: bg != null ? Colors.white : cs.primary),
              const SizedBox(height: 12),
              Text(
                tile.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold, color: bg != null ? Colors.white : null),
              ),
              if (tile.subtitle != null && tile.subtitle!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  tile.subtitle!,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: bg != null ? Colors.white70 : Colors.grey.shade600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
