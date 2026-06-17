import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth.dart';

/// Se l'email (verificata) dell'utente combacia con un account del sito SNA,
/// propone UNA volta il collegamento automatico. "Collega" lega l'account senza
/// password (l'email è già prova di possesso); "Non ora" non lo ripropone più.
///
/// Best-effort: qualsiasi errore (rete, WP non raggiungibile) viene ignorato.
Future<void> maybeOfferSnaLink(BuildContext context, WidgetRef ref) async {
  try {
    final s = await ref.read(authRepositoryProvider).snaLinkSuggestion();
    if (!s.available || !context.mounted) return;

    final accept = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Collega il tuo account SNA'),
        content: Text(
          s.levelLabel != null
              ? 'La tua email risulta iscritta a SNA (${s.levelLabel}). Vuoi collegare l\'account per accedere ai contenuti riservati al tuo ruolo?'
              : 'La tua email risulta iscritta a SNA. Vuoi collegare l\'account per accedere ai contenuti riservati?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Non ora')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Collega')),
        ],
      ),
    );

    if (accept == true) {
      await ref.read(authRepositoryProvider).acceptSnaLink();
      // Ricarica /me: ora l'utente porta ruolo + livello ereditati.
      await ref.read(authControllerProvider.notifier).refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account SNA collegato.')),
        );
      }
    } else {
      await ref.read(authRepositoryProvider).dismissSnaLink();
    }
  } catch (_) {
    // proposta best-effort: in caso di errore non disturbiamo l'utente
  }
}
