import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/app_colors.dart';
import '../../core/util/color.dart';
import '../../core/util/navigation.dart';
import '../../core/widgets/async_value_widget.dart';
import '../app_settings/app_settings.dart';
import '../auth/auth.dart';
import '../partners/partner.dart';
import '../social/social_link.dart';
import 'home_section.dart';

// ---------------------------------------------------------------------------
// Default per sezione (usati se l'admin non carica icona/colore custom)
// ---------------------------------------------------------------------------
IconData _defaultIcon(String route) => switch (route) {
      '/newsletters' => Icons.mark_email_read_outlined,
      '/articles' => Icons.article_outlined,
      '/provincial' => Icons.location_on_outlined,
      '/events' => Icons.event_outlined,
      '/magazine' => Icons.menu_book_outlined,
      '/orgchart' => Icons.account_tree_outlined,
      '/partners' => Icons.handshake_outlined,
      '/posts' => Icons.campaign_outlined,
      '/account' => Icons.lock_outline,
      _ => Icons.chevron_right,
    };

Color _defaultColor(String route) => switch (route) {
      '/newsletters' => const Color(0xFF0B3D66),
      '/articles' => const Color(0xFF1565C0),
      '/provincial' => const Color(0xFF00897B),
      '/events' => const Color(0xFF2E7D32),
      '/magazine' => const Color(0xFF6A1B9A),
      '/orgchart' => const Color(0xFF455A64),
      '/partners' => const Color(0xFFEF6C00),
      '/posts' => const Color(0xFFC62828),
      _ => const Color(0xFF0B3D66),
    };

/// Box icona della sezione: icona custom (png/svg con tinta) o fallback Material.
class _SectionIcon extends StatelessWidget {
  final HomeSection section;
  final double size;
  const _SectionIcon(this.section, {this.size = 26});

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(section.backgroundColor) ?? _defaultColor(section.route);
    Widget inner;
    if (section.icon != null) {
      if (section.isSvg) {
        inner = SvgPicture.network(
          section.icon!,
          width: size,
          height: size,
          colorFilter: parseHexColor(section.iconColor) != null
              ? ColorFilter.mode(parseHexColor(section.iconColor)!, BlendMode.srcIn)
              : null,
        );
      } else {
        inner = CachedNetworkImage(imageUrl: section.icon!, width: size, height: size, fit: BoxFit.contain);
      }
    } else {
      inner = Icon(_defaultIcon(section.route), color: color, size: size);
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
      child: inner,
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final auth = ref.watch(authControllerProvider);
    final sections = ref.watch(homeSectionsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(appSettingsProvider);
          ref.invalidate(socialLinksProvider);
          ref.invalidate(homeSectionsProvider);
          ref.invalidate(partnersProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF0B3D66),
              actions: [
                IconButton(
                  tooltip: 'Notifiche',
                  icon: const Icon(Icons.notifications_none),
                  onPressed: () => pushWithRipple(context, '/posts'),
                ),
                auth.maybeWhen(
                  // Loggato → l'omino porta DIRETTAMENTE all'area riservata (il logout è lì).
                  data: (user) => user == null
                      ? IconButton(
                          tooltip: 'Accedi',
                          icon: const Icon(Icons.person_outline),
                          onPressed: () => pushWithRipple(context, '/login'),
                        )
                      : IconButton(
                          tooltip: 'Area riservata',
                          icon: const Icon(Icons.account_circle),
                          onPressed: () => pushWithRipple(context, '/account'),
                        ),
                  orElse: () => IconButton(
                    icon: const Icon(Icons.person_outline),
                    onPressed: () => pushWithRipple(context, '/login'),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _Header(settings: settings.valueOrNull),
              ),
            ),
            const SliverToBoxAdapter(child: _SocialCircles()),
            if (settings.valueOrNull?.reservedButtonEnabled ?? false)
              const SliverToBoxAdapter(child: _ReservedButton()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: AsyncValueWidget<List<HomeSection>>(
                  value: sections,
                  onRetry: () => ref.invalidate(homeSectionsProvider),
                  data: (items) => Column(children: _buildCards(context, items)),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(16, 8, 16, 8), child: _PartnersStrip())),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  /// Costruisce le card: 'wide' a tutta pagina, 'half' accoppiate due per riga.
  List<Widget> _buildCards(BuildContext context, List<HomeSection> sections) {
    final widgets = <Widget>[];
    var i = 0;
    while (i < sections.length) {
      final s = sections[i];
      if (s.isWide) {
        widgets.add(_WideCard(section: s));
        i++;
      } else {
        final next = (i + 1 < sections.length && !sections[i + 1].isWide) ? sections[i + 1] : null;
        widgets.add(IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _HalfCard(section: s)),
              const SizedBox(width: 12),
              Expanded(child: next != null ? _HalfCard(section: next) : const SizedBox.shrink()),
            ],
          ),
        ));
        i += next != null ? 2 : 1;
      }
      widgets.add(const SizedBox(height: 12));
    }
    return widgets;
  }
}

/// Colore del bordo sinistro che appare al tap.
const Color _cardActiveBorder = Color(0xFF4594F5);


/// Card della home: angoli vivi, ombra sotto, e bordo sinistro #4594f5 che
/// compare al tap (come il ripple) per un istante, prima di navigare alla pagina.
class _HomeCard extends StatefulWidget {
  final String route;
  final Widget child;
  const _HomeCard({required this.route, required this.child});

  @override
  State<_HomeCard> createState() => _HomeCardState();
}

class _HomeCardState extends State<_HomeCard> {
  bool _active = false;

  Future<void> _onTap() async {
    setState(() => _active = true);
    // Lascia vedere bordo + ripple, poi naviga.
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    context.push(widget.route);
    setState(() => _active = false);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3, // un po' di ombra sotto
      shadowColor: Colors.black54,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero), // angoli vivi
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _onTap,
        child: Stack(
          children: [
            // Al tap il contenuto scorre a destra per fare spazio al bordino.
            AnimatedPadding(
              duration: const Duration(milliseconds: 120),
              padding: EdgeInsets.only(left: _active ? 4 : 0),
              child: widget.child,
            ),
            // Il bordino blu cresce nello spazio liberato a sinistra.
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: _active ? 4 : 0,
                color: _cardActiveBorder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottone "Area Riservata" (attivabile dal pannello): bianco con bordo/testo
/// rossi; al tap inverte i colori (rosso pieno, testo bianco) + ripple, poi naviga.
class _ReservedButton extends StatefulWidget {
  const _ReservedButton();

  @override
  State<_ReservedButton> createState() => _ReservedButtonState();
}

class _ReservedButtonState extends State<_ReservedButton> {
  bool _active = false;

  Future<void> _onTap() async {
    setState(() => _active = true);
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    context.push('/account');
    setState(() => _active = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Material(
        color: Colors.transparent,
        shape: const RoundedRectangleBorder(side: BorderSide(color: kBrandRed, width: 2)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _onTap,
          splashColor: Colors.white24,
          highlightColor: Colors.white10,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: double.infinity,
            height: 52,
            color: _active ? kBrandRed : Colors.white,
            alignment: Alignment.center,
            child: Text(
              'Area Riservata',
              style: TextStyle(
                color: _active ? Colors.white : kBrandRed,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WideCard extends StatelessWidget {
  final HomeSection section;
  const _WideCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(section.backgroundColor) ?? _defaultColor(section.route);
    return _HomeCard(
      route: section.route,
      child: SizedBox(
        height: 104,
        child: Row(
          children: [
            Container(
              width: 96,
              color: color.withValues(alpha: 0.12),
              child: Center(child: _SectionIcon(section, size: 36)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(section.title, style: const TextStyle(color: kNavy, fontWeight: FontWeight.bold, fontSize: 18)),
                    if (section.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(section.subtitle!, style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card a mezza larghezza, rettangolare: icona sopra, titolo sotto (a capo per
/// parole, mai troncato). Altezza pari nella coppia via IntrinsicHeight.
class _HalfCard extends StatelessWidget {
  final HomeSection section;
  const _HalfCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return _HomeCard(
      route: section.route,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _SectionIcon(section, size: 26),
            const SizedBox(height: 12),
            Text(
              section.title,
              style: const TextStyle(color: kNavy, fontWeight: FontWeight.w600, fontSize: 15),
              softWrap: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final AppSettings? settings;
  const _Header({this.settings});

  Widget _background() {
    if (settings?.headerVideo != null) {
      return _HeaderVideo(videoUrl: settings!.headerVideo!, fallbackImage: settings?.headerImage);
    }
    if (settings?.headerImage != null) {
      return CachedNetworkImage(imageUrl: settings!.headerImage!, fit: BoxFit.cover);
    }
    return Container(color: const Color(0xFF0B3D66));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _background(),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black26, Colors.black54],
            ),
          ),
        ),
        if (settings?.logo != null)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Align(
              alignment: Alignment.topCenter,
              child: CachedNetworkImage(imageUrl: settings!.logo!, height: 64),
            ),
          ),
      ],
    );
  }
}

class _HeaderVideo extends StatefulWidget {
  final String videoUrl;
  final String? fallbackImage;
  const _HeaderVideo({required this.videoUrl, this.fallbackImage});

  @override
  State<_HeaderVideo> createState() => _HeaderVideoState();
}

class _HeaderVideoState extends State<_HeaderVideo> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..setLooping(true)
      ..setVolume(0);
    _controller = c;
    c.initialize().then((_) {
      if (!mounted) return;
      setState(() => _ready = true);
      c.play();
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Widget _fallback() {
    if (widget.fallbackImage != null) {
      return CachedNetworkImage(imageUrl: widget.fallbackImage!, fit: BoxFit.cover);
    }
    return Container(color: const Color(0xFF0B3D66));
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (_ready && c != null && c.value.isInitialized) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: c.value.size.width,
            height: c.value.size.height,
            child: VideoPlayer(c),
          ),
        ),
      );
    }
    return _fallback();
  }
}

class _SocialCircles extends ConsumerWidget {
  const _SocialCircles();

  IconData _icon(String platform) => switch (platform) {
        'facebook' => FontAwesomeIcons.facebookF,
        'instagram' => FontAwesomeIcons.instagram,
        'linkedin' => FontAwesomeIcons.linkedinIn,
        'youtube' => FontAwesomeIcons.youtube,
        'x' => FontAwesomeIcons.xTwitter,
        'tiktok' => FontAwesomeIcons.tiktok,
        'telegram' => FontAwesomeIcons.telegram,
        'whatsapp' => FontAwesomeIcons.whatsapp,
        _ => FontAwesomeIcons.globe,
      };

  Color _brand(String platform) => switch (platform) {
        'facebook' => const Color(0xFF1877F2),
        'instagram' => const Color(0xFFE4405F),
        'linkedin' => const Color(0xFF0A66C2),
        'youtube' => const Color(0xFFFF0000),
        'x' => Colors.black,
        'tiktok' => Colors.black,
        'telegram' => const Color(0xFF229ED9),
        'whatsapp' => const Color(0xFF25D366),
        _ => const Color(0xFF0B3D66),
      };

  Widget _inner(SocialLink l) {
    if (l.icon != null) {
      if (l.isSvg) {
        return SvgPicture.network(
          l.icon!,
          width: 24,
          height: 24,
          colorFilter: parseHexColor(l.iconColor) != null
              ? ColorFilter.mode(parseHexColor(l.iconColor)!, BlendMode.srcIn)
              : null,
        );
      }
      return CachedNetworkImage(imageUrl: l.icon!, width: 28, height: 28, fit: BoxFit.contain);
    }
    return FaIcon(_icon(l.platform), color: _brand(l.platform), size: 22);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final links = ref.watch(socialLinksProvider);
    return links.maybeWhen(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Card(
            elevation: 3,
            shadowColor: Colors.black54,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero), // angoli vivi
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 34, height: 3, color: kBrandOrange),
                      const SizedBox(width: 12),
                      const Text(
                        'LINK SOCIAL',
                        style: TextStyle(color: kNavy, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.5),
                      ),
                      const SizedBox(width: 12),
                      Container(width: 34, height: 3, color: kBrandOrange),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 16,
                    children: items.map((l) {
                      final bg = parseHexColor(l.backgroundColor) ??
                          (l.icon == null ? _brand(l.platform).withValues(alpha: 0.12) : Colors.grey.shade100);
                      return Material(
                        color: bg,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () async {
                            // Lascia vedere il ripple prima di aprire l'app esterna.
                            await Future.delayed(const Duration(milliseconds: 160));
                            launchUrl(Uri.parse(l.url), mode: LaunchMode.externalApplication);
                          },
                          child: SizedBox(
                            width: 54,
                            height: 54,
                            child: Center(child: _inner(l)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _PartnersStrip extends ConsumerWidget {
  const _PartnersStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partners = ref.watch(partnersProvider);
    return partners.maybeWhen(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Convenzioni & Partners', style: TextStyle(color: kNavy, fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                TextButton(onPressed: () => context.push('/partners'), child: const Text('Vedi tutti')),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _PartnerChip(partner: items[i]),
              ),
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _PartnerChip extends StatelessWidget {
  final Partner partner;
  const _PartnerChip({required this.partner});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: partner.url != null ? () => launchUrl(Uri.parse(partner.url!), mode: LaunchMode.externalApplication) : null,
        child: Container(
          width: 120,
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: partner.logo != null
                    ? CachedNetworkImage(imageUrl: partner.logo!, fit: BoxFit.contain)
                    : Icon(Icons.business, color: Colors.grey.shade400, size: 32),
              ),
              const SizedBox(height: 6),
              Text(partner.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
