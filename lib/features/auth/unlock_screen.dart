import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/biometric_service.dart';
import '../../core/router/app_router.dart';

/// Sovrappone la schermata di sblocco quando lo stato è [BioLockState.locked].
/// Si trova nel builder di MaterialApp, quindi copre qualsiasi rotta corrente.
class AppLockGate extends ConsumerWidget {
  final Widget child;
  const AppLockGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locked = ref.watch(appLockProvider) == BioLockState.locked;
    return Stack(
      children: [
        child,
        if (locked) const Positioned.fill(child: UnlockScreen()),
      ],
    );
  }
}

/// Schermata di sblocco biometrico: al primo frame lancia il prompt di sistema.
class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  bool _busy = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_busy) return;
    setState(() { _busy = true; _failed = false; });
    final ok = await ref.read(biometricServiceProvider).authenticate('Sblocca SNAPP per accedere al tuo account');
    if (!mounted) return;
    if (ok) {
      ref.read(appLockProvider.notifier).unlock();
    } else {
      setState(() { _busy = false; _failed = true; });
    }
  }

  /// Prosegue anonimo senza ripristinare la sessione (il token resta in storage).
  void _continueAnonymous() {
    ref.read(appLockProvider.notifier).skip();
  }

  /// Accesso con password: anonimo + vai al login.
  void _usePassword() {
    ref.read(appLockProvider.notifier).skip();
    goRouter.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fingerprint, size: 88, color: cs.primary),
                const SizedBox(height: 20),
                const Text('SNAPP è bloccata',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(
                  _failed
                      ? 'Sblocco non riuscito. Riprova con impronta/volto, oppure accedi con password.'
                      : 'Sblocca con la tua impronta o il volto per accedere al tuo account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.5),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: _busy ? null : _unlock,
                  icon: _busy
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.fingerprint),
                  label: const Text('Sblocca'),
                ),
                const SizedBox(height: 8),
                TextButton(onPressed: _busy ? null : _usePassword, child: const Text('Accedi con password')),
                TextButton(
                  onPressed: _busy ? null : _continueAnonymous,
                  child: Text('Continua senza accedere', style: TextStyle(color: Colors.grey.shade600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
