import 'dart:convert';

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

  void _addToCalendar(BuildContext context, {
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
      endDate: end ?? start.add(const Duration(hours: 1)),
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
            Text(e.title, style: const TextStyle(color: kNavy, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (e.startsAt != null)
              Row(children: [const Icon(Icons.event), const SizedBox(width: 8), Expanded(child: Text(df.format(e.startsAt!.toLocal())))]),
            if (e.location != null) ...[
              const SizedBox(height: 8),
              Row(children: [const Icon(Icons.place_outlined), const SizedBox(width: 8), Expanded(child: Text(e.location!))]),
            ],
            const SizedBox(height: 16),
            if (e.description != null) Text(stripHtml(e.description), style: const TextStyle(fontSize: 16, height: 1.5)),
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
                  builder: (_) => _RegistrationWebView(
                    url: e.registrationUrl!,
                    onRegistered: (data) {
                      // A registrazione avvenuta: aggiunge l'evento al calendario del device.
                      final start = DateTime.tryParse(data['start']?.toString() ?? '') ?? e.startsAt ?? DateTime.now();
                      _addToCalendar(context,
                          title: (data['title'] ?? e.title).toString(),
                          location: (data['location'] ?? e.location)?.toString(),
                          start: start,
                          end: DateTime.tryParse(data['end']?.toString() ?? ''));
                    },
                  ),
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

/// WebView del form di registrazione su WordPress. Riceve i dati dell'evento dal
/// canale JS `SnappBridge` (contratto del plugin) per creare l'evento in calendario.
class _RegistrationWebView extends StatefulWidget {
  final String url;
  final void Function(Map<String, dynamic> eventData) onRegistered;

  const _RegistrationWebView({required this.url, required this.onRegistered});

  @override
  State<_RegistrationWebView> createState() => _RegistrationWebViewState();
}

class _RegistrationWebViewState extends State<_RegistrationWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('SnappBridge', onMessageReceived: (message) {
        try {
          final decoded = jsonDecode(message.message);
          if (decoded is Map && decoded['type'] == 'event_registered') {
            final payload = decoded['payload'];
            final event = payload is Map ? payload['event'] : null;
            if (event is Map) {
              widget.onRegistered(Map<String, dynamic>.from(event));
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Registrazione completata. Evento aggiunto al calendario.')),
                );
              }
            }
          }
        } catch (_) {}
      })
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrazione')),
      body: WebViewWidget(controller: _controller),
    );
  }
}
