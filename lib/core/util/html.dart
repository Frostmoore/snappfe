/// Rimuove i tag HTML per una visualizzazione testuale semplice.
/// (Per un rendering ricco si potrà aggiungere flutter_widget_from_html.)
String stripHtml(String? html) {
  if (html == null) return '';
  return html
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#039;', "'")
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
