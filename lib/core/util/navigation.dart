import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Naviga dopo un brevissimo ritardo, così il ripple del tap fa in tempo a
/// mostrarsi prima che la transizione di pagina copra l'elemento toccato.
Future<void> pushWithRipple(BuildContext context, String route) async {
  await Future<void>.delayed(const Duration(milliseconds: 160));
  if (context.mounted) context.push(route);
}
