import 'package:flutter/material.dart';

/// Colore del bordino sinistro che appare al tap (come le card della home).
const Color kCardActiveBorder = Color(0xFF4594F5);

/// Card con angoli vivi, ombra, ripple e bordino blu sinistro che compare al
/// tap (poi esegue [onTap]). Stile uniforme con home e organigramma.
class TapCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const TapCard({super.key, required this.child, required this.onTap});

  @override
  State<TapCard> createState() => _TapCardState();
}

class _TapCardState extends State<TapCard> {
  bool _active = false;

  Future<void> _handle() async {
    setState(() => _active = true);
    // Lascia vedere bordo + ripple, poi esegue l'azione.
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    widget.onTap();
    setState(() => _active = false);
  }

  @override
  Widget build(BuildContext context) {
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
              padding: EdgeInsets.only(left: _active ? 4 : 0),
              child: widget.child,
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: _active ? 4 : 0,
                color: kCardActiveBorder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
