import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/biometric_service.dart';
import '../../core/widgets/async_value_widget.dart';
import '../auth/auth.dart';
import 'account_link.dart';

class AccountLinkScreen extends ConsumerStatefulWidget {
  const AccountLinkScreen({super.key});

  @override
  ConsumerState<AccountLinkScreen> createState() => _AccountLinkScreenState();
}

class _AccountLinkScreenState extends ConsumerState<AccountLinkScreen> {
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _link() async {
    final identifier = _identifier.text.trim();
    final password = _password.text;
    if (identifier.isEmpty || password.isEmpty) {
      setState(() => _error = 'Inserisci email/username e password del sito SNA.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      await ref.read(accountRepositoryProvider).link(identifier, password);
      ref.invalidate(accountLinkProvider);
      await ref.read(authControllerProvider.notifier).refresh();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unlink() async {
    setState(() => _busy = true);
    await ref.read(accountRepositoryProvider).unlink();
    ref.invalidate(accountLinkProvider);
    await ref.read(authControllerProvider.notifier).refresh();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Account SNA')),
      body: auth.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (user) {
          if (user == null) {
            return _LoginPrompt();
          }
          if (!user.emailVerified) {
            return _VerifyPrompt();
          }
          final link = ref.watch(accountLinkProvider);
          return AsyncValueWidget<AccountLink?>(
            value: link,
            onRetry: () => ref.invalidate(accountLinkProvider),
            data: (current) => ListView(
              padding: const EdgeInsets.all(20),
              children: [
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(user.name),
                  subtitle: Text(user.email),
                ),
                const SizedBox(height: 8),
                const _BiometricTile(),
                const Divider(height: 32),
                if (current != null) ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.verified, color: Colors.green),
                      title: Text('Collegato a ${current.username ?? 'account SNA'}'),
                      subtitle: Text('Ruolo: ${user.wpRoleLabel ?? user.wpRole ?? '—'}'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _unlink,
                    icon: const Icon(Icons.link_off),
                    label: const Text('Scollega account'),
                  ),
                ] else ...[
                  const Text('Collega il tuo account del sito SNA per sbloccare i contenuti riservati al tuo livello. Inserisci le credenziali che usi su snaservice.it.'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _identifier,
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Email o username SNA', prefixIcon: Icon(Icons.badge_outlined)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: _obscure,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _busy ? null : _link(),
                    decoration: InputDecoration(
                      labelText: 'Password SNA',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy ? null : _link,
                    child: _busy
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Collega account'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('Accedi per gestire il tuo account SNA e l\'area riservata.', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => context.push('/login'), child: const Text('Accedi')),
          ],
        ),
      ),
    );
  }
}

/// Toggle per attivare/disattivare lo sblocco biometrico. Nascosto se il device
/// non supporta la biometria.
class _BiometricTile extends ConsumerStatefulWidget {
  const _BiometricTile();

  @override
  ConsumerState<_BiometricTile> createState() => _BiometricTileState();
}

class _BiometricTileState extends ConsumerState<_BiometricTile> {
  bool? _capable;
  bool _enabled = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bio = ref.read(biometricServiceProvider);
    final capable = await bio.isDeviceCapable();
    final enabled = await bio.isEnabled();
    if (mounted) setState(() { _capable = capable; _enabled = enabled; });
  }

  Future<void> _toggle(bool value) async {
    final bio = ref.read(biometricServiceProvider);
    setState(() => _busy = true);
    if (value) {
      // Conferma con biometria prima di attivare.
      final ok = await bio.authenticate('Conferma per abilitare l\'accesso biometrico');
      if (ok) await bio.setEnabled(true);
      if (mounted) setState(() { _enabled = ok; _busy = false; });
    } else {
      await bio.setEnabled(false);
      if (mounted) setState(() { _enabled = false; _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_capable != true) return const SizedBox.shrink();
    return Card(
      child: SwitchListTile(
        secondary: _busy
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.fingerprint),
        title: const Text('Accesso biometrico'),
        subtitle: const Text('Sblocca l\'app con impronta o volto'),
        value: _enabled,
        onChanged: _busy ? null : _toggle,
      ),
    );
  }
}

/// Mostrato quando l'utente è loggato ma non ha ancora verificato l'email:
/// l'account non è attivo, quindi le funzioni (collegamento SNA) sono bloccate.
class _VerifyPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mark_email_unread_outlined, size: 48, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            const Text(
              'Verifica la tua email per attivare l\'account e collegare l\'account SNA.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => context.push('/verify-email'), child: const Text('Verifica email')),
          ],
        ),
      ),
    );
  }
}
