/// Decodifica le entità HTML in testo leggibile.
///
/// Gestisce sia i riferimenti numerici (`&#8220;`, `&#x201C;`) sia le entità
/// nominali più comuni che arrivano da WordPress (virgolette tipografiche,
/// trattini, accentate, ecc.). Da usare sui campi di testo semplice (titoli,
/// excerpt, autore), non sull'HTML che verrà renderizzato.
String unescapeHtml(String? input) {
  if (input == null || input.isEmpty) return '';

  var out = input;

  // Riferimenti numerici decimali: &#8220; -> "
  out = out.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
    final code = int.tryParse(m.group(1)!);
    return code != null ? String.fromCharCode(code) : m.group(0)!;
  });

  // Riferimenti numerici esadecimali: &#x201C; -> "
  out = out.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) {
    final code = int.tryParse(m.group(1)!, radix: 16);
    return code != null ? String.fromCharCode(code) : m.group(0)!;
  });

  // Entità nominali più frequenti.
  const named = <String, String>{
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&apos;': "'",
    '&nbsp;': ' ',
    '&hellip;': '…',
    '&ndash;': '–',
    '&mdash;': '—',
    '&laquo;': '«',
    '&raquo;': '»',
    '&lsquo;': '‘',
    '&rsquo;': '’',
    '&ldquo;': '“',
    '&rdquo;': '”',
    '&eacute;': 'é',
    '&egrave;': 'è',
    '&agrave;': 'à',
    '&igrave;': 'ì',
    '&ograve;': 'ò',
    '&ugrave;': 'ù',
    '&euro;': '€',
  };
  named.forEach((entity, char) => out = out.replaceAll(entity, char));

  // &amp; codificato due volte (&amp;#8220;) o residui.
  return out;
}

/// Caratteri invisibili che il sito lascia in testa a paragrafi e punti elenco
/// (zero-width space, BOM, soft hyphen): sul web non si vedono, ma su alcuni
/// device l'app li disegnava come "?".
final _invisibleChars = RegExp('[${String.fromCharCodes(const [0x200B, 0xFEFF, 0x00AD])}]');

/// Rimuove i tag HTML per una visualizzazione testuale semplice e decodifica
/// le entità.
String stripHtml(String? html) {
  if (html == null) return '';
  final noTags = html.replaceAll(RegExp(r'<[^>]*>'), ' ');
  return unescapeHtml(noTags).replaceAll(_invisibleChars, '').replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Prepara l'HTML di un articolo/newsletter WordPress per `HtmlWidget`:
///  - toglie il **primo `<h1>`**: è il titolo, già mostrato sopra dalla schermata;
///  - toglie `<svg>`/`<style>`/`<script>`/`<link>` (icone e CSS di Elementor);
///  - toglie il blocco di condivisione Elementor in fondo ("Facebook LinkedIn
///    WhatsApp"): l'app ha la sua barra di condivisione;
///  - trasforma gli `<iframe>` (video) in un link, che HtmlWidget sa aprire;
///  - elimina i caratteri invisibili e i paragrafi rimasti vuoti.
String cleanArticleHtml(String? html) {
  if (html == null || html.isEmpty) return '';
  var out = html.replaceAll(_invisibleChars, '');

  out = out.replaceAll(
      RegExp(r'<(svg|style|script)\b[^>]*>.*?</\1>', dotAll: true, caseSensitive: false), '');
  out = out.replaceAll(RegExp(r'<link\b[^>]*>', caseSensitive: false), '');
  out = out.replaceFirst(RegExp(r'<h1\b[^>]*>.*?</h1>', dotAll: true, caseSensitive: false), '');
  out = out.replaceAllMapped(
    RegExp(r'''<iframe\b[^>]*\bsrc=["']([^"']+)["'][^>]*>.*?</iframe>''', dotAll: true, caseSensitive: false),
    (m) => '<p><a href="${m.group(1)}">Guarda il video</a></p>',
  );

  // Paragrafi che contengono solo i nomi dei social (resti dei bottoni di condivisione).
  final shareOnly = RegExp(r'^((facebook|linkedin|whatsapp|twitter|email)\s*)+$', caseSensitive: false);
  out = out.replaceAllMapped(RegExp(r'<p\b[^>]*>(.*?)</p>', dotAll: true, caseSensitive: false), (m) {
    final text = stripHtml(m.group(1));
    if (text.isEmpty || shareOnly.hasMatch(text)) {
      // Vuoto: lo tolgo solo se non contiene immagini.
      return m.group(1)!.contains('<img') ? m.group(0)! : '';
    }
    return m.group(0)!;
  });

  return out.trim();
}

/// "N. 20 del 7 settembre 2026" in testa all'estratto delle newsletter.
final _issueLabel = RegExp(r'^\s*(N\.\s*\d+\s+del\s+\d{1,2}\s+\p{L}+\s+\d{4})\s*',
    unicode: true, caseSensitive: false);

/// Divide l'estratto di una newsletter in etichetta del numero ("N. 20 del …")
/// e testo, togliendo dal testo il titolo ripetuto in testa (l'estratto del sito
/// è "N. xx del … + titolo + corpo"). Il confronto col titolo ignora maiuscole,
/// punteggiatura e spazi (es. "Politico-Sindacale" vs "Politico Sindacale").
({String? label, String text}) splitNewsletterExcerpt(String excerpt, String title) {
  var text = excerpt.trim();
  String? label;
  final m = _issueLabel.firstMatch(text);
  if (m != null) {
    label = m.group(1);
    text = text.substring(m.end);
  }
  return (label: label, text: _stripLeadingTitle(text, title));
}

String _normalize(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');

String _stripLeadingTitle(String text, String title) {
  final target = _normalize(title);
  if (target.isEmpty) return text;
  final acc = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    acc.write(_normalize(text[i]));
    final soFar = acc.toString();
    if (soFar.length >= target.length) {
      return soFar == target ? text.substring(i + 1).trimLeft() : text;
    }
    if (!target.startsWith(soFar)) return text;
  }
  return text;
}
