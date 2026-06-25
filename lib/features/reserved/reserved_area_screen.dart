import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/util/navigation.dart';
import '../../core/widgets/async_value_widget.dart';
import '../../core/widgets/tap_card.dart';
import '../auth/auth.dart';
import 'reserved_tile.dart';

/// Area riservata: griglia di tiles costruite dal pannello, filtrate per ruolo SNA.
class ReservedAreaScreen extends ConsumerWidget {
  const ReservedAreaScreen({super.key});

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
                const Text('Accedi per entrare nell\'area riservata.',
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                    onPressed: () => context.push('/login'),
                    child: const Text('Accedi')),
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
                      subtitle: const Text(
                          'Per vedere i contenuti riservati al tuo ruolo.'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/account/settings'),
                    ),
                  ),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text('Nessun contenuto disponibile.',
                          style: TextStyle(color: Colors.grey.shade600)),
                    ),
                  )
                else
                  for (final t in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TileCard(tile: t),
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
  const _TileCard({required this.tile});

  @override
  Widget build(BuildContext context) {
    return TapCard(
      onTap: () => pushWithRipple(context, '/reserved/tiles/${tile.id}'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Icona a sinistra (immagine custom o fallback).
            SizedBox(
              width: 48,
              height: 48,
              child: tile.icon != null
                  ? CachedNetworkImage(imageUrl: tile.icon!, fit: BoxFit.contain)
                  : const Icon(Icons.folder_open, size: 40, color: kNavy),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tile.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: kNavy, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (tile.subtitle != null && tile.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      tile.subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
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
