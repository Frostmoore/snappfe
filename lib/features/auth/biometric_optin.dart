import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/biometric_service.dart';

/// Dopo il primo accesso propone (una sola volta) di abilitare lo sblocco
/// biometrico. Da chiamare solo per account ATTIVI (email verificata).
Future<void> offerBiometricOptIn(BuildContext context, WidgetRef ref) async {
  final bio = ref.read(biometricServiceProvider);
  if (await bio.isEnabled()) return; // già attivo
  if (await bio.wasAsked()) return; // già proposto in passato
  if (!await bio.isDeviceCapable()) return; // device senza biometria
  await bio.markAsked();
  if (!context.mounted) return;

  final enable = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.fingerprint, size: 36),
      title: const Text('Accesso biometrico'),
      content: const Text(
        'Vuoi accedere più velocemente sbloccando l\'app con impronta o volto? '
        'Potrai disattivarlo quando vuoi dal tuo account.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No, grazie')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Abilita')),
      ],
    ),
  );

  if (enable == true) {
    // Conferma la presenza dell'utente (il sistema mostra il prompt impronta/volto).
    final ok = await bio.authenticate('Conferma per abilitare l\'accesso biometrico');
    if (ok) await bio.setEnabled(true);
    // Se fallisce, di solito è perché non c'è alcuna biometria registrata.
    final enrolled = ok || await bio.hasEnrolledBiometrics();
    if (!context.mounted) return;

    final String message;
    if (ok) {
      message = 'Accesso biometrico attivato.';
    } else if (enrolled) {
      message = 'Attivazione annullata.';
    } else {
      message = 'Nessuna impronta/volto registrati sul telefono. Configurali nelle impostazioni del dispositivo, poi riprova dal tuo account.';
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
