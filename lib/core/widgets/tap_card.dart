import 'package:flutter/material.dart';

/// Colore del bordino sinistro che appare al tap (come le card della home).
const Color kCardActiveBorder = Color(0xFF4594F5);

/// Card con angoli vivi, ombra, ripple e bordino blu sinistro. Due modalità:
///  - **navigazione** ([selected] null): il bordino resta acceso dal tap finché
///    [onTap] (la navigazione) non completa, poi si spegne al ritorno.
///  - **selezione** ([selected] valorizzato): il bordino riflette [selected],
///    gestito dal parent (resta finché non si seleziona altro / si tocca fuori).
///    Utile quando [onTap] apre il browser e non c'è un "ritorno".
class TapCard extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onTap;
  final bool? selected;
  const TapCard({super.key, required this.child, required this.onTap, this.selected});

  @override
  State<TapCard> createState() => _TapCardState();
}

class _TapCardState extends State<TapCard> {
  bool _active = false;

  Future<void> _handle() async {
    // Modalità selezione: il bordino è gestito dal parent → esegui solo l'azione.
    if (widget.selected != null) {
      await widget.onTap();
      return;
    }
    // Modalità navigazione: bordino acceso durante la navigazione, spento al ritorno.
    setState(() => _active = true);
    await widget.onTap();
    if (mounted) setState(() => _active = false);
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.selected ?? _active;
    return Card(
      elevation: 3,
      shadowColor: Colors.black54,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero), // angoli vivi
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _handle,
        child: Stack(
          children: [
            AnimatedPadding(
              duration: const Duration(milliseconds: 120),
              padding: EdgeInsets.only(left: active ? 4 : 0),
              child: widget.child,
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: active ? 4 : 0,
                color: kCardActiveBorder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
