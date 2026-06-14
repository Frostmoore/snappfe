import 'package:flutter_test/flutter_test.dart';
import 'package:snapp/core/util/html.dart';

void main() {
  test('stripHtml rimuove i tag e normalizza gli spazi', () {
    expect(stripHtml('<p>Ciao&nbsp;mondo</p>'), 'Ciao mondo');
    expect(stripHtml('<b>A</b>  <i>B</i>'), 'A B');
    expect(stripHtml(null), '');
  });
}
