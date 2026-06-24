import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Naviga dopo un brevissimo ritardo (così il bordino/ripple del tap fa in tempo
/// a mostrarsi prima della transizione) e attende fino al ritorno (pop) dalla
/// pagina di destinazione: chi chiama può tenere acceso il bordino nel frattempo.
Future<void> pushWithRipple(BuildContext context, String route) async {
  await Future<void>.delayed(const Duration(milliseconds: 140));
  if (context.mounted) await context.push(route);
}
