import 'package:flutter_test/flutter_test.dart';
import 'package:snapp/core/util/html.dart';

/// Struttura reale delle newsletter del sito: banner, "N. xx del …", <h1> titolo,
/// corpo con caratteri invisibili, blocco di condivisione Elementor in fondo.
const _newsletter = '''
<p><img src="https://snaservice.it/wp-content/uploads/2025/02/Newsletter.png" alt="Newsletter.png" /></p>
<p>N. 20 del 7 settembre 2026</p>
<h1>Nasce la Scuola-Politico Sindacale SNA</h1>
<p>​Dopo un lungo percorso 🚀</p>
<ul><li>​Consolida il nostro ruolo</li></ul>
<style>.x{color:red}</style>
<p><iframe src="https://www.youtube.com/embed/abc"></iframe></p>
<p>
  <svg viewBox="0 0 512 512"><path d="M1"></path></svg><br />
  Facebook<br />
  <svg viewBox="0 0 448 512"><path d="M2"></path></svg><br />
  LinkedIn<br />
  WhatsApp</p>
''';

void main() {
  group('cleanArticleHtml', () {
    final out = cleanArticleHtml(_newsletter);

    test('toglie il primo <h1> (titolo ripetuto)', () {
      expect(out, isNot(contains('<h1')));
      expect(out, isNot(contains('Scuola-Politico Sindacale')));
    });

    test('tiene banner, numero, emoji ed elenchi', () {
      expect(out, contains('Newsletter.png'));
      expect(out, contains('N. 20 del 7 settembre 2026'));
      expect(out, contains('🚀'));
      expect(out, contains('<li>Consolida il nostro ruolo</li>'));
    });

    test('elimina caratteri invisibili, svg, style e bottoni social', () {
      expect(out, isNot(contains('​')));
      expect(out, isNot(contains('<svg')));
      expect(out, isNot(contains('<style')));
      expect(out, isNot(contains('Facebook')));
      expect(out, isNot(contains('WhatsApp')));
    });

    test('iframe diventa un link', () {
      expect(out, contains('<a href="https://www.youtube.com/embed/abc">Guarda il video</a>'));
      expect(out, isNot(contains('<iframe')));
    });

    test('toglie solo il primo <h1>', () {
      expect(cleanArticleHtml('<h1>A</h1><p>x</p><h1>B</h1>'), '<p>x</p><h1>B</h1>');
    });

    test('null e vuoto', () {
      expect(cleanArticleHtml(null), '');
      expect(cleanArticleHtml(''), '');
    });
  });

  group('splitNewsletterExcerpt', () {
    test('separa il numero e toglie il titolo ripetuto (ignorando punteggiatura)', () {
      final r = splitNewsletterExcerpt(
        'N. 20 del 7 settembre 2026 Nasce la Scuola-Politico Sindacale SNA Dopo un lungo percorso',
        'Nasce la scuola Politico-Sindacale SNA',
      );
      expect(r.label, 'N. 20 del 7 settembre 2026');
      expect(r.text, 'Dopo un lungo percorso');
    });

    test('se il testo non inizia col titolo lo lascia com\'è', () {
      final r = splitNewsletterExcerpt(
        'N. 22 del 28 settembre 2026 Un nuovo passo per Assicuramente Cari Colleghi',
        'Oltre il convegno',
      );
      expect(r.label, 'N. 22 del 28 settembre 2026');
      expect(r.text, 'Un nuovo passo per Assicuramente Cari Colleghi');
    });

    test('estratto di un articolo normale: nessuna etichetta', () {
      final r = splitNewsletterExcerpt('Testo qualsiasi', 'Titolo');
      expect(r.label, isNull);
      expect(r.text, 'Testo qualsiasi');
    });
  });

  test('stripHtml elimina i caratteri invisibili', () {
    expect(stripHtml('<p>​Ciao­</p>'), 'Ciao');
  });
}
