import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth.dart';
import 'biometric_optin.dart';

/// Gate di verifica email: l'account non è attivo finché l'utente non clicca il
/// link ricevuto via email. Da qui può reinviare l'email e ricontrollare lo stato.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _busy = false;
  String? _info;
  String? _error;

  Future<void> _resend() async {
    setState(() { _busy = true; _info = null; _error = null; });
    try {
      await ref.read(authRepositoryProvider).resendVerification();
      if (mounted) setState(() => _info = 'Email di verifica inviata di nuovo. Controlla la posta.');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkVerified() async {
    setState(() { _busy = true; _info = null; _error = null; });
    await ref.read(authControllerProvider.notifier).refresh();
    if (!mounted) return;
    final user = ref.read(authControllerProvider).value;
    setState(() => _busy = false);
    if (user != null && user.emailVerified) {
      // Primo accesso (post-verifica): proponi (una volta) lo sblocco biometrico.
      await offerBiometricOptIn(context, ref);
      if (mounted) context.go('/');
    } else {
      setState(() => _error = 'Email non ancora verificata. Clicca il link nell\'email, poi riprova.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifica email'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 20),
          Icon(Icons.mark_email_unread_outlined, size: 72, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 20),
          const Text(
            'Verifica la tua email',
            textAlign: TextAlign.center,
            style: TextStyle(color: kNavy, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            user != null
                ? 'Abbiamo inviato un link di conferma a ${user.email}. Il tuo account sarà attivo solo dopo aver verificato l\'email.'
                : 'Abbiamo inviato un link di conferma alla tua email. Il tuo account sarà attivo solo dopo aver verificato l\'email.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, height: 1.5),
          ),
          if (_info != null) ...[
            const SizedBox(height: 16),
            _Banner(text: _info!, color: Colors.green),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            _Banner(text: _error!, color: Colors.red),
          ],
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _busy ? null : _checkVerified,
            icon: _busy
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle_outline),
            label: const Text('Ho verificato l\'email'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy ? null : _resend,
            icon: const Icon(Icons.refresh),
            label: const Text('Reinvia email'),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final String text;
  final Color color;
  const _Banner({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(text, style: TextStyle(color: color.withValues(alpha: 0.9))),
    );
  }
}
