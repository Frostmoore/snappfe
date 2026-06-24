# SNAPP — App (Flutter)

Client mobile (iOS e Android) dell'app **SNAPP**. Mostra aggiornamenti, strumenti, newsletter ed eventi, con un'area riservata accessibile dopo autenticazione.

## Stack

- **Flutter** (Dart **3.6+**)
- **flutter_riverpod** — gestione dello stato
- **go_router** — routing e deep-link
- **dio** — networking
- **flutter_secure_storage** — archiviazione sicura dei token
- **local_auth** — sblocco biometrico
- **google_sign_in** / **sign_in_with_apple** — login social
- **onesignal_flutter** — notifiche push

## Architettura

Codebase organizzata a feature: un nucleo condiviso (`core/`) per configurazione, networking, storage sicuro, tema, routing e widget riusabili, e moduli indipendenti in `features/`. Ogni modulo espone i propri model, provider e schermate.

Lo strato dati è reattivo, con gestione esplicita degli stati di caricamento, errore e vuoto. Una parte dei contenuti è consumata in tempo reale da una sorgente esterna: il refresh forza la rilettura dei dati aggiornati e l'interfaccia tollera i tempi di risposta della sorgente. Le notifiche push includono un controllo che verifica e ripristina l'iscrizione del dispositivo, per ridurre i casi di mancata ricezione.

Push e login social sono attivati da configurazione: in assenza delle relative impostazioni la build resta funzionante con quelle funzioni disattivate.

## Requisiti

- Flutter SDK (canale stabile) con Dart 3.6+
- Toolchain Android (SDK) e/o Xcode per iOS

## Setup

```bash
flutter pub get
flutter run
```

## Configurazione

I parametri di runtime (endpoint API, credenziali OAuth, identificativo del provider push) si forniscono tramite la configurazione dell'app / `--dart-define`. Chiavi, keystore e file di firma non sono inclusi nel repository.

## Build

```bash
flutter build apk --release      # Android
flutter build ipa                # iOS
```

## Test

```bash
flutter analyze
flutter test
```

## Struttura

```
lib/
  core/
    config/     # configurazione e feature-gating
    network/    # client HTTP e gestione errori
    storage/    # archiviazione sicura
    theme/      # tema dell'app
    router/     # rotte e deep-link
    widgets/    # widget riutilizzabili
    util/       # utility
  features/     # moduli applicativi (auth, home, eventi, ecc.)
```

## Funzionalità

- Autenticazione email e login social (Google/Apple); sblocco biometrico dell'area riservata.
- Feed dei contenuti, articoli e newsletter, eventi con filtri, sezioni informative.
- Notifiche push con apertura diretta del contenuto (deep-link).
- Integrazioni di sistema: apertura link esterni, aggiunta eventi al calendario, condivisione.

## Note

- Backend (API e pannello): repository **snappbe**.
- App localizzata in italiano.
