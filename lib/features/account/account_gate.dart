import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/biometric_service.dart';
import '../auth/auth.dart';
import '../reserved/reserved_area_screen.dart';

/// Protegge l'area riservata: se la biometria è attiva, ogni apertura richiede
/// impronta/volto (con email+password come fallback). Senza biometria attiva,
/// mostra direttamente l'area riservata.
class AccountGate extends ConsumerStatefulWidget {
  const AccountGate({super.key});

  @override
  ConsumerState<AccountGate> createState() => _AccountGateState();
}

class _AccountGateState extends ConsumerState<AccountGate> {
  bool _checked = false; // valutazione iniziale completata
  bool _unlocked = false; // gate superato
  bool _passwordMode = false; // form password (fallback) visibile
  bool _busy = false;
  bool _obscure = true;
  String? _error;
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final enabled = await ref.read(biometricServiceProvider).isEnabled();
    if (!mounted) return;
    setState(() {
      _checked = true;
      _unlocked = !enabled; // niente biometria → nessun gate
    });
    if (enabled) _tryBiometric();
  }

  Future<void> _tryBiometric() async {
    setState(() { _busy = true; _error = null; });
    final ok = await ref.read(biometricServiceProvider).authenticate('Accedi all\'area riservata');
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) _unlocked = true;
    });
  }

  Future<void> _confirmPassword() async {
    if (_password.text.isEmpty) {
      setState(() => _error = 'Inserisci la password.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      await ref.read(authRepositoryProvider).confirmPassword(_password.text);
      if (!mounted) return;
      setState(() => _unlocked = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;

    if (!_checked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // Sbloccato, oppure non loggato (ReservedAreaScreen mostra il prompt di login).
    if (_unlocked || user == null) {
      return const ReservedAreaScreen();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Area riservata')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _passwordMode ? _passwordFallback(user) : _biometricLock(),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _biometricLock() {
    final cs = Theme.of(context).colorScheme;
    return [
      Icon(Icons.fingerprint, size: 80, color: cs.primary),
      const SizedBox(height: 18),
      const Text('Area riservata protetta',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      const SizedBox(height: 10),
      Text('Sblocca con impronta o volto per accedere al tuo account.',
          textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700, height: 1.5)),
      if (_error != null) ...[
        const SizedBox(height: 14),
        Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
      ],
      const SizedBox(height: 26),
      FilledButton.icon(
        onPressed: _busy ? null : _tryBiometric,
        icon: _busy
            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.fingerprint),
        label: const Text('Usa impronta o volto'),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: _busy ? null : () => setState(() { _passwordMode = true; _error = null; }),
        child: const Text('Usa email e password'),
      ),
    ];
  }

  List<Widget> _passwordFallback(User user) {
    return [
      const Icon(Icons.lock_outline, size: 64),
      const SizedBox(height: 16),
      const Text('Conferma la tua identità',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      TextField(
        readOnly: true,
        controller: TextEditingController(text: user.email),
        decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _password,
        obscureText: _obscure,
        autocorrect: false,
        enableSuggestions: false,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _busy ? null : _confirmPassword(),
        decoration: InputDecoration(
          labelText: 'Password',
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
      const SizedBox(height: 18),
      FilledButton(
        onPressed: _busy ? null : _confirmPassword,
        child: _busy
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Conferma'),
      ),
      const SizedBox(height: 8),
      TextButton.icon(
        onPressed: _busy ? null : () => setState(() { _passwordMode = false; _error = null; }),
        icon: const Icon(Icons.fingerprint),
        label: const Text('Torna alla biometria'),
      ),
    ];
  }
}
