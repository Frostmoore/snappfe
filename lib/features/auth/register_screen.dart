import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Aggiorna la checklist dei requisiti mentre l'utente digita.
    _password.addListener(_onChanged);
    _confirm.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  // Requisiti password (allineati a Password::defaults() lato backend).
  bool get _hasMinLen => _password.text.length >= 10;
  bool get _hasMixedCase => RegExp(r'[a-z]').hasMatch(_password.text) && RegExp(r'[A-Z]').hasMatch(_password.text);
  bool get _hasNumber => RegExp(r'\d').hasMatch(_password.text);
  bool get _hasSymbol => RegExp(r'[^A-Za-z0-9]').hasMatch(_password.text);
  bool get _matches => _confirm.text.isNotEmpty && _confirm.text == _password.text;
  bool get _isStrong => _hasMinLen && _hasMixedCase && _hasNumber && _hasSymbol;
  bool get _canSubmit => _name.text.trim().isNotEmpty && _email.text.trim().isNotEmpty && _isStrong && _matches;

  Future<void> _submit() async {
    if (!_isStrong) {
      setState(() => _error = 'La password non rispetta i requisiti di sicurezza.');
      return;
    }
    if (!_matches) {
      setState(() => _error = 'Le due password non coincidono.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    await ref.read(authControllerProvider.notifier).register(
          _name.text.trim(),
          _email.text.trim(),
          _password.text,
          _confirm.text,
        );
    final state = ref.read(authControllerProvider);
    if (!mounted) return;
    if (state.hasError) {
      setState(() {
        _busy = false;
        _error = state.error.toString();
      });
    } else if (state.value != null) {
      // Account creato ma non attivo finché l'email non è verificata → gate.
      context.go(state.value!.emailVerified ? '/' : '/verify-email');
    } else {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrati')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            textInputAction: TextInputAction.next,
            onChanged: (_) => _onChanged(),
            decoration: const InputDecoration(labelText: 'Nome', prefixIcon: Icon(Icons.person_outline)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            onChanged: (_) => _onChanged(),
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: _obscure,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Password',
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
            onSubmitted: (_) => _canSubmit && !_busy ? _submit() : null,
            decoration: InputDecoration(
              labelText: 'Conferma password',
              prefixIcon: const Icon(Icons.lock_reset_outlined),
              errorText: _confirm.text.isNotEmpty && !_matches ? 'Le password non coincidono' : null,
            ),
          ),
          const SizedBox(height: 16),
          if (_password.text.isNotEmpty) ...[
            _Req(ok: _hasMinLen, text: 'Almeno 10 caratteri'),
            _Req(ok: _hasMixedCase, text: 'Maiuscole e minuscole'),
            _Req(ok: _hasNumber, text: 'Almeno un numero'),
            _Req(ok: _hasSymbol, text: 'Almeno un simbolo'),
            const SizedBox(height: 8),
          ],
          if (_error != null) ...[
            const SizedBox(height: 4),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          FilledButton(
            onPressed: (_busy || !_canSubmit) ? null : _submit,
            child: _busy
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Crea account'),
          ),
        ],
      ),
    );
  }
}

/// Riga della checklist requisiti password (verde se soddisfatto).
class _Req extends StatelessWidget {
  final bool ok;
  final String text;
  const _Req({required this.ok, required this.text});

  @override
  Widget build(BuildContext context) {
    final color = ok ? Colors.green : Colors.grey;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked, size: 18, color: color),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontSize: 13)),
        ],
      ),
    );
  }
}
