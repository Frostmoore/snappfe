import 'package:add_2_calendar/add_2_calendar.dart' as cal;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/util/html.dart';
import '../../core/widgets/async_value_widget.dart';
import 'event.dart';

class EventDetailScreen extends ConsumerWidget {
  final int id;
  const EventDetailScreen({super.key, required this.id});

  void _addToCalendar(
    BuildContext context, {
    required String title,
    String? description,
    String? location,
    required DateTime start,
    DateTime? end,
  }) {
    cal.Add2Calendar.addEvent2Cal(cal.Event(
      title: title,
      description: description ?? '',
      location: location ?? '',
      startDate: start,
      endDate: end ?? start.add(const Duration(hours: 2)),
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(eventDetailProvider(id));
    final df = DateFormat('EEEE d MMMM yyyy, HH:mm', 'it');

    return Scaffold(
      appBar: AppBar(title: const Text('Evento')),
      body: AsyncValueWidget<Event>(
        value: event,
        onRetry: () => ref.invalidate(eventDetailProvider(id)),
        data: (e) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (e.cover != null)
              ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: e.cover!)),
            const SizedBox(height: 16),
            if (e.typeLabel != null && e.typeLabel!.isNotEmpty) ...[
              _TypeBadge(label: e.typeLabel!, type: e.type),
              const SizedBox(height: 10),
            ],
            Text(e.title, style: const TextStyle(color: kNavy, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (e.startsAt != null)
              _InfoRow(icon: Icons.event, text: df.format(e.startsAt!.toLocal())),
            if (e.place != null) _InfoRow(icon: Icons.map_outlined, text: e.place!),
            if (e.location != null && e.location!.isNotEmpty)
              _InfoRow(icon: Icons.place_outlined, text: e.location!),
            const SizedBox(height: 16),
            if (e.description != null && e.description!.isNotEmpty)
              Text(stripHtml(e.description), style: const TextStyle(fontSize: 16, height: 1.5)),
            const SizedBox(height: 24),
            if (e.startsAt != null)
              OutlinedButton.icon(
                onPressed: () => _addToCalendar(context,
                    title: e.title, description: e.description, location: e.location, start: e.startsAt!, end: e.endsAt),
                icon: const Icon(Icons.calendar_month),
                label: const Text('Aggiungi al calendario'),
              ),
            if (e.hasRegistration) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => _EventPageWebView(url: e.registrationUrl!, title: e.title),
                )),
                icon: const Icon(Icons.how_to_reg),
                label: const Text('Registrati all\'evento'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, color: kNavy),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ]),
    );
  }
}

/// Etichetta colorata del tipo di evento (Formativo/Politico/Altro).
class _TypeBadge extends StatelessWidget {
  final String label;
  final String? type;
  const _TypeBadge({required this.label, this.type});

  Color get _color {
    switch (type) {
      case 'formativo':
        return const Color(0xFF1E88E5);
      case 'politico':
        return const Color(0xFFE65100);
      default:
        return const Color(0xFF607D8B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(color: _color, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.5),
        ),
      ),
    );
  }
}

/// Apre la pagina WordPress dell'evento in una WebView in-app (registrazione).
class _EventPageWebView extends StatefulWidget {
  final String url;
  final String title;

  const _EventPageWebView({required this.url, required this.title});

  @override
  State<_EventPageWebView> createState() => _EventPageWebViewState();
}

class _EventPageWebViewState extends State<_EventPageWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title, overflow: TextOverflow.ellipsis)),
      body: WebViewWidget(controller: _controller),
    );
  }
}
