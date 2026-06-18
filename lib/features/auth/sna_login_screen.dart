import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth.dart';
import 'biometric_optin.dart';

/// Accesso con le credenziali del sito snaservice.it: crea l'utente app e lo
/// collega direttamente all'account WordPress (ereditando il livello).
class SnaLoginScreen extends ConsumerStatefulWidget {
  const SnaLoginScreen({super.key});

  @override
  ConsumerState<SnaLoginScreen> createState() => _SnaLoginScreenState();
}

class _SnaLoginScreenState extends ConsumerState<SnaLoginScreen> {
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

  Future<void> _submit() async {
    final id = _identifier.text.trim();
    final pwd = _password.text;
    if (id.isEmpty || pwd.isEmpty) {
      setState(() => _error = 'Inserisci email/username e password di snaservice.it.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    await ref.read(authControllerProvider.notifier).snaLogin(id, pwd);
    final state = ref.read(authControllerProvider);
    if (!mounted) return;
    if (state.hasError) {
      setState(() {
        _busy = false;
        _error = state.error.toString();
      });
    } else if (state.value != null) {
      // Account già attivo (email WP verificata): proponi l'opt-in biometrico.
      await offerBiometricOptIn(context, ref);
      if (mounted) context.go('/');
    } else {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accedi con SNA')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          Text(
            'Accedi con le credenziali del sito snaservice.it. Creeremo il tuo account '
            'nell\'app collegandolo automaticamente al tuo profilo SNA.',
            style: TextStyle(color: Colors.grey.shade700, height: 1.5),
          ),
          const SizedBox(height: 20),
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
            onSubmitted: (_) => _busy ? null : _submit(),
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
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Accedi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          TextButton(
            onPressed: _busy ? null : () => context.push('/sna-reset'),
            child: const Text('Password SNA dimenticata?'),
          ),
        ],
      ),
    );
  }
}
