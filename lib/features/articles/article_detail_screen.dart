import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
            Text(a.title, style: const TextStyle(color: kNavy, fontSize: 22, fontWeight: FontWeight.bold)),
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
              const SizedBox(height: 24),
              const Text('Condividi', style: TextStyle(color: kNavy, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              _ShareBar(url: a.link!),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pulsanti di condivisione del link (sito) sui social + copia link.
class _ShareBar extends StatelessWidget {
  final String url;
  const _ShareBar({required this.url});

  Future<void> _open(String shareUrl) =>
      launchUrl(Uri.parse(shareUrl), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final enc = Uri.encodeComponent(url);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _ShareButton(
          label: 'Facebook',
          color: const Color(0xFF1877F2),
          icon: const FaIcon(FontAwesomeIcons.facebookF, color: Colors.white, size: 18),
          onTap: () => _open('https://www.facebook.com/sharer/sharer.php?u=$enc'),
        ),
        _ShareButton(
          label: 'LinkedIn',
          color: const Color(0xFF0A66C2),
          icon: const FaIcon(FontAwesomeIcons.linkedinIn, color: Colors.white, size: 18),
          onTap: () => _open('https://www.linkedin.com/sharing/share-offsite/?url=$enc'),
        ),
        _ShareButton(
          label: 'WhatsApp',
          color: const Color(0xFF25D366),
          icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white, size: 20),
          onTap: () => _open('https://wa.me/?text=$enc'),
        ),
        _ShareButton(
          label: 'Copia link',
          color: kNavy,
          icon: const Icon(Icons.link, color: Colors.white, size: 20),
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: url));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copiato negli appunti')),
              );
            }
          },
        ),
      ],
    );
  }
}

class _ShareButton extends StatelessWidget {
  final String label;
  final Color color;
  final Widget icon;
  final VoidCallback onTap;
  const _ShareButton({required this.label, required this.color, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
