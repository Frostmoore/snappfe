import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/widgets/async_value_widget.dart';
import 'partner.dart';

/// Lista Convenzioni & Partners: due sezioni (prima le convenzioni) a griglia di
/// loghi; al tocco si apre il pannello con le info ([showPartnerSheet]).
class PartnersScreen extends ConsumerWidget {
  const PartnersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partners = ref.watch(partnersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Convenzioni & Partners')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(partnersProvider),
        child: AsyncValueWidget<List<Partner>>(
          value: partners,
          onRetry: () => ref.invalidate(partnersProvider),
          data: (items) {
            if (items.isEmpty) return const EmptyView('Nessun partner.');
            final convenzioni = items.where((p) => p.isConvenzione).toList();
            final altri = items.where((p) => !p.isConvenzione).toList();
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (convenzioni.isNotEmpty) ..._section('Convenzioni', convenzioni),
                if (altri.isNotEmpty) ..._section('Partners', altri),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _section(String title, List<Partner> items) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Text(title.toUpperCase(),
                style: const TextStyle(color: kNavy, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => _PartnerCard(partner: items[i]),
              childCount: items.length,
            ),
          ),
        ),
      ];
}

class _PartnerCard extends StatelessWidget {
  final Partner partner;
  const _PartnerCard({required this.partner});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => showPartnerSheet(context, partner),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Expanded(
                child: partner.logo != null
                    ? CachedNetworkImage(imageUrl: partner.logo!, fit: BoxFit.contain)
                    : const Icon(Icons.business, size: 40),
              ),
              const SizedBox(height: 8),
              Text(partner.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kNavy, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pannello info di un partner: logo, descrizione e contatti (sito, telefoni,
/// email) cliccabili. Usato dalla lista e dalla striscia in home.
Future<void> showPartnerSheet(BuildContext context, Partner partner) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) => SafeArea(child: _PartnerInfo(partner: partner)),
  );
}

class _PartnerInfo extends StatelessWidget {
  final Partner partner;
  const _PartnerInfo({required this.partner});

  Future<void> _open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  /// "www.sito.it" senza schema diventa https; in etichetta niente "https://".
  String _webUrl(String url) => url.startsWith('http') ? url : 'https://$url';
  String _webLabel(String url) =>
      url.replaceFirst(RegExp(r'^https?://'), '').replaceFirst(RegExp(r'/$'), '');

  @override
  Widget build(BuildContext context) {
    final p = partner;
    final hasWeb = p.url != null && p.url!.isNotEmpty;
    final hasEmail = p.email != null && p.email!.isNotEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (p.logo != null)
            SizedBox(height: 90, child: CachedNetworkImage(imageUrl: p.logo!, fit: BoxFit.contain)),
          const SizedBox(height: 12),
          Text(p.name,
              textAlign: TextAlign.center,
              style: const TextStyle(color: kNavy, fontWeight: FontWeight.bold, fontSize: 20)),
          if (p.description != null && p.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(p.description!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 15, height: 1.4)),
          ],
          if (hasWeb || p.phones.isNotEmpty || hasEmail) const SizedBox(height: 16),
          if (hasWeb)
            _ContactTile(icon: Icons.language, label: _webLabel(p.url!), onTap: () => _open(_webUrl(p.url!))),
          for (final phone in p.phones)
            _ContactTile(
              icon: Icons.phone_outlined,
              label: phone,
              onTap: () => _open('tel:${phone.replaceAll(RegExp(r'[^\d+]'), '')}'),
            ),
          if (hasEmail)
            _ContactTile(icon: Icons.mail_outline, label: p.email!, onTap: () => _open('mailto:${p.email}')),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ContactTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      elevation: 0,
      color: kNavy.withValues(alpha: 0.06),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: ListTile(
        leading: Icon(icon, color: kNavy),
        title: Text(label, style: const TextStyle(color: kNavy, fontWeight: FontWeight.w600)),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
        onTap: onTap,
      ),
    );
  }
}
