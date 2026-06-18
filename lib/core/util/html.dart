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

/// Rimuove i tag HTML per una visualizzazione testuale semplice e decodifica
/// le entità.
String stripHtml(String? html) {
  if (html == null) return '';
  final noTags = html.replaceAll(RegExp(r'<[^>]*>'), ' ');
  return unescapeHtml(noTags).replaceAll(RegExp(r'\s+'), ' ').trim();
}
