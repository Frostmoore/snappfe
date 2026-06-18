import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth.dart';

/// Reset password del sito SNA in tre passi, tutto in-app:
/// 1) email → ti arriva un codice;
/// 2) inserisci il codice → viene **verificato**;
/// 3) (solo dopo) imposti la nuova password. Nessun passaggio dal sito web.
class SnaPasswordResetScreen extends ConsumerStatefulWidget {
  const SnaPasswordResetScreen({super.key});

  @override
  ConsumerState<SnaPasswordResetScreen> createState() => _SnaPasswordResetScreenState();
}

class _SnaPasswordResetScreenState extends ConsumerState<SnaPasswordResetScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  int _step = 0; // 0 = email · 1 = codice · 2 = nuova password
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Inserisci un\'email valida.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).snaForgotPassword(email);
    } catch (_) {
      // risposta generica: si avanza comunque al passo del codice
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _step = 1;
        });
      }
    }
  }

  Future<void> _verifyCode() async {
    final code = _code.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Inserisci il codice ricevuto via email.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).snaVerifyCode(_email.text.trim(), code);
      if (mounted) setState(() => _step = 2);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Codice non valido o scaduto. Controlla l\'email o richiedi un nuovo codice.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    final pwd = _password.text;
    if (pwd.length < 8) {
      setState(() => _error = 'La password deve avere almeno 8 caratteri.');
      return;
    }
    if (pwd != _confirm.text) {
      setState(() => _error = 'Le password non coincidono.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).snaResetPassword(_email.text.trim(), _code.text.trim(), pwd, _confirm.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password SNA aggiornata. Ora puoi accedere con la nuova password.')),
      );
      context.pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Impossibile reimpostare la password. Il codice potrebbe essere scaduto: richiedine uno nuovo.';
        });
      }
    }
  }

  void _restart() => setState(() {
        _step = 0;
        _code.clear();
        _password.clear();
        _confirm.clear();
        _error = null;
      });

  @override
  Widget build(BuildContext context) {
    final (intro, action, label) = switch (_step) {
      0 => (
          'Inserisci l\'email del tuo account SNA: ti invieremo un codice per impostare una nuova password, direttamente qui nell\'app.',
          _requestCode,
          'Invia codice',
        ),
      1 => (
          'Ti abbiamo inviato un codice a ${_email.text.trim()} (se l\'email è registrata su SNA). Inseriscilo per continuare.',
          _verifyCode,
          'Verifica codice',
        ),
      _ => (
          'Codice verificato ✓. Imposta ora la nuova password del tuo account SNA.',
          _reset,
          'Reimposta password',
        ),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Reimposta password SNA')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          Text(intro, style: TextStyle(color: Colors.grey.shade700, height: 1.5)),
          const SizedBox(height: 20),

          if (_step == 0)
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _busy ? null : _requestCode(),
              decoration: const InputDecoration(labelText: 'Email SNA', prefixIcon: Icon(Icons.email_outlined)),
            )
          else if (_step == 1)
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _busy ? null : _verifyCode(),
              decoration: const InputDecoration(labelText: 'Codice (6 cifre)', prefixIcon: Icon(Icons.pin_outlined)),
            )
          else ...[
            TextField(
              controller: _password,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: 'Nuova password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirm,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _busy ? null : _reset(),
              decoration: const InputDecoration(labelText: 'Conferma nuova password', prefixIcon: Icon(Icons.lock_outline)),
            ),
          ],

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],

          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _busy ? null : action,
              child: _busy
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          if (_step > 0)
            TextButton(
              onPressed: _busy ? null : _restart,
              child: const Text('Cambia email / richiedi un nuovo codice'),
            ),
        ],
      ),
    );
  }
}
