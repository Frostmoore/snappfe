# Branding — icona app & splash

Metti qui i file sorgente con questi nomi esatti. Poi si rigenerano le risorse native.

## File richiesti

| File | Dimensione | Trasparenza | Note |
|---|---|---|---|
| `icon.png` | 1024×1024 | NO (sfondo pieno) | Icona base (iOS + Android) |
| `icon_foreground.png` | 1024×1024 | SÌ | Solo logo, ~65% al centro (Android adattiva) |
| `splash.png` | ~1152×1152 | SÌ | Logo centrato; su Android 12 tienilo entro ~768×768 |
| `splash_dark.png` (opz.) | ~1152×1152 | SÌ | Versione per dark mode |

## Colori (in `pubspec.yaml`)

- `adaptive_icon_background` — sfondo dell'icona adattiva Android
- `flutter_native_splash.color` — sfondo della splash

## Rigenerare

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```
