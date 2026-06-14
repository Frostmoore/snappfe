import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import 'auth.dart';
import 'biometric_optin.dart';
import 'social_auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Navigazione post-autenticazione condivisa (email/password e social).
  Future<void> _afterAuth() async {
    final state = ref.read(authControllerProvider);
    if (!mounted) return;
    if (state.hasError) {
      setState(() {
        _busy = false;
        _error = state.error.toString();
      });
    } else if (state.value != null) {
      // Account non attivo finché l'email non è verificata → gate di verifica.
      if (!state.value!.emailVerified) {
        context.go('/verify-email');
        return;
      }
      // Primo accesso riuscito: proponi (una volta) lo sblocco biometrico.
      await offerBiometricOptIn(context, ref);
      if (mounted) context.go('/');
    } else {
      setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    await ref.read(authControllerProvider.notifier).login(_email.text.trim(), _password.text);
    await _afterAuth();
  }

  Future<void> _social(String provider) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      String token;
      if (AppConfig.socialLoginEnabled) {
        // Flusso reale: l'app ottiene il token nativamente dal provider.
        final svc = SocialAuthService();
        final t = provider == 'google' ? await svc.google() : await svc.apple();
        if (t == null) {
          if (mounted) setState(() => _busy = false); // annullato dall'utente
          return;
        }
        token = t;
      } else {
        // Flusso mock (dev): il backend crea/accede a un utente mock.
        token = 'mock';
      }
      await ref.read(authControllerProvider.notifier).socialLogin(provider, token);
      await _afterAuth();
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accedi')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Accedi'),
          ),
          TextButton(
            onPressed: _busy ? null : () => context.push('/register'),
            child: const Text('Non hai un account? Registrati'),
          ),

          // ── Login social (Google / Apple) ──
          Row(children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('oppure', style: TextStyle(color: Colors.grey.shade500)),
            ),
            const Expanded(child: Divider()),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _busy ? null : () => context.push('/sna-login'),
              icon: const Icon(Icons.verified_user_outlined),
              label: const Text('Accedi con SNA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _busy ? null : () => _social('google'),
              icon: const FaIcon(FontAwesomeIcons.google, size: 20, color: Colors.white),
              label: const Text('Accedi con Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDB4437), // rosso Google
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _busy ? null : () => _social('apple'),
              icon: const FaIcon(FontAwesomeIcons.apple, size: 22, color: Colors.white),
              label: const Text('Accedi con Apple', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
            ),
          ),
          if (!AppConfig.socialLoginEnabled) ...[
            const SizedBox(height: 10),
            Center(
              child: Text('Login social in modalità demo (mock)',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }
}
