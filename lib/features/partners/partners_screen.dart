import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/widgets/async_value_widget.dart';
import 'partner.dart';

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
          data: (items) => items.isEmpty
              ? const EmptyView('Nessun partner.')
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.3,
                  ),
                  itemCount: items.length,
                  itemBuilder: (_, i) => _PartnerCard(partner: items[i]),
                ),
        ),
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  final Partner partner;
  const _PartnerCard({required this.partner});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: partner.url != null ? () => launchUrl(Uri.parse(partner.url!), mode: LaunchMode.externalApplication) : null,
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
