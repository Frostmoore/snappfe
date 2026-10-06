#!/bin/bash
# =============================================================================
# SNAPP — aggiorna la copia dell'app già presente sul Mac all'ultima versione
# pubblicata su GitHub e fa le build di produzione Android (AAB) e iOS (IPA).
#
# La copia locale è già configurata (firma Android in android/key.properties,
# Team Apple in Xcode): lo script NON la tocca, aggiorna solo il codice.
#
# Uso (dalla cartella dell'app, o indicandola):
#   ./tools/build_release_mac.sh                        # ultima versione (branch vX.Y.Z più alto)
#   ./tools/build_release_mac.sh --dir ~/Progetti/snappfe
#   ./tools/build_release_mac.sh --ref v1.1.0           # una versione precisa
#   ./tools/build_release_mac.sh --only android         # solo Android (oppure: --only ios)
#   ./tools/build_release_mac.sh --build-number 42      # forza il numero di build
#
# Numero di build: se non indicato è AAMMGGHH (es. 26100614), sempre crescente,
# come richiesto da Play Store e App Store a ogni caricamento.
# I file finali vanno in <app>/release/<versione>_build<numero>/ ; log in <app>/release/logs/.
# =============================================================================
set -uo pipefail

EXPECTED_FLUTTER="3.27"   # versione con cui è sviluppata l'app

APP_DIR=""
REF=""
ONLY=""
BUILD_NUMBER=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dir)          APP_DIR="${2:-}"; shift 2 ;;
    --ref)          REF="${2:-}"; shift 2 ;;
    --only)         ONLY="${2:-}"; shift 2 ;;
    --build-number) BUILD_NUMBER="${2:-}"; shift 2 ;;
    -h|--help)      sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "Argomento sconosciuto: $1 (usa --help)"; exit 2 ;;
  esac
done
if [ -n "$ONLY" ] && [ "$ONLY" != "android" ] && [ "$ONLY" != "ios" ]; then
  echo "--only accetta solo: android | ios"; exit 2
fi
if [ -n "$BUILD_NUMBER" ] && ! [[ "$BUILD_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "--build-number deve essere un numero intero"; exit 2
fi

# Cartella dell'app: --dir, altrimenti quella che contiene questo script (tools/..),
# altrimenti la cartella corrente.
if [ -z "$APP_DIR" ]; then
  SCRIPT_PARENT="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)"
  if [ -f "$SCRIPT_PARENT/pubspec.yaml" ]; then APP_DIR="$SCRIPT_PARENT"; else APP_DIR="$PWD"; fi
fi
cd "$APP_DIR" 2>/dev/null || { echo "Cartella non trovata: $APP_DIR"; exit 1; }
APP_DIR="$PWD"

mkdir -p "$APP_DIR/release/logs"
STAMP="$(date +%Y%m%d_%H%M%S)"
LOG="$APP_DIR/release/logs/build_$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

say()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m  ✓ %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m  ! %s\033[0m\n' "$*"; }
die()  { printf '\033[1;31m  ✗ %s\033[0m\n' "$*"; echo "Log completo: $LOG"; exit 1; }

DO_ANDROID=1; DO_IOS=1
[ "$ONLY" = "android" ] && DO_IOS=0
[ "$ONLY" = "ios" ] && DO_ANDROID=0

# --- Controlli -------------------------------------------------------------------
say "Controlli"
[ -f pubspec.yaml ] && grep -q '^name: snapp' pubspec.yaml || die "$APP_DIR non è la cartella dell'app SNAPP (manca pubspec.yaml di snapp)"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "$APP_DIR non è una copia git: scaricala una volta con  git clone https://github.com/Frostmoore/snappfe.git"
command -v flutter >/dev/null || die "flutter non trovato nel PATH"
FLUTTER_VER="$(flutter --version 2>/dev/null | head -1 | awk '{print $2}')"
ok "Cartella app: $APP_DIR"
ok "Flutter $FLUTTER_VER"
case "$FLUTTER_VER" in
  "$EXPECTED_FLUTTER".*) ;;
  *) warn "L'app è sviluppata con Flutter $EXPECTED_FLUTTER.x: con $FLUTTER_VER la build potrebbe comportarsi diversamente." ;;
esac
if [ $DO_ANDROID -eq 1 ] && [ ! -f android/key.properties ]; then
  die "Manca android/key.properties: senza la chiave di firma la build Android verrebbe firmata in debug e il Play Store la rifiuterebbe"
fi
if [ $DO_IOS -eq 1 ]; then
  command -v xcodebuild >/dev/null || die "Xcode non trovato"
  command -v pod >/dev/null        || die "CocoaPods non trovato (brew install cocoapods)"
fi

# --- Aggiornamento del codice ---------------------------------------------------------
say "Aggiornamento da GitHub"
# L'elenco delle versioni si chiede DIRETTAMENTE a GitHub (ls-remote), non ai branch
# che la copia locale conosce: una copia clonata con un solo branch
# (git clone --branch X / --single-branch / --depth) con un semplice "git fetch"
# vede solo quel branch e sceglierebbe sempre la versione vecchia.
REMOTE_VERSIONS="$(git ls-remote --heads origin 'refs/heads/v*' </dev/null \
  | sed -E 's#.*refs/heads/##' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$')" \
  || die "Impossibile leggere le versioni da GitHub (connessione?)"
[ -n "$REMOTE_VERSIONS" ] || die "Nessun branch di versione (vX.Y.Z) su GitHub"
if [ -z "$REF" ]; then
  # Il più alto per numero (v1.10 > v1.9, non ordine alfabetico).
  REF="v$(echo "$REMOTE_VERSIONS" | sed 's/^v//' | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)"
fi
echo "$REMOTE_VERSIONS" | grep -qx "$REF" || die "La versione $REF non esiste su GitHub"
ok "Ultima versione su GitHub: $REF (versioni disponibili: $(echo "$REMOTE_VERSIONS" | tr '\n' ' '))"
# Scarica esplicitamente quel branch, qualunque sia la configurazione del clone.
git fetch --quiet origin "+refs/heads/$REF:refs/remotes/origin/$REF" </dev/null \
  || die "Download della versione $REF fallito"

PREV="$(git rev-parse --short HEAD)"
# Le modifiche locali di configurazione (es. Team Apple nel progetto Xcode) vengono
# messe da parte e riapplicate dopo l'aggiornamento; i file non tracciati
# (key.properties, keystore) non vengono toccati.
STASHED=0
if ! git diff --quiet || ! git diff --cached --quiet; then
  git stash push --quiet -m "build_release_mac $STAMP" && STASHED=1
  ok "Modifiche locali messe da parte"
fi
if git show-ref --verify --quiet "refs/heads/$REF"; then
  git checkout --quiet "$REF" && git merge --quiet --ff-only "origin/$REF"
else
  git checkout --quiet -b "$REF" "origin/$REF"
fi
UPDATE_RC=$?
if [ $STASHED -eq 1 ]; then
  if git stash pop --quiet; then
    ok "Modifiche locali riapplicate"
  else
    die "Le modifiche locali sono in conflitto con la nuova versione: risolvi a mano (git status), il backup è in  git stash list"
  fi
fi
[ $UPDATE_RC -eq 0 ] || die "Aggiornamento a $REF non riuscito (vedi messaggi sopra)"
# Rete di sicurezza: mai compilare codice diverso dalla versione scelta.
[ "$(git rev-parse HEAD)" = "$(git rev-parse "origin/$REF")" ] \
  || die "Il codice locale non coincide con $REF su GitHub: aggiornamento non riuscito, build annullata"

COMMIT="$(git rev-parse --short HEAD)"
APP_VERSION="$(grep -E '^version:' pubspec.yaml | awk '{print $2}' | cut -d+ -f1)"
[ -n "$BUILD_NUMBER" ] || BUILD_NUMBER="$(date +%y%m%d%H)"
if [ "$PREV" = "$COMMIT" ]; then ok "Già aggiornato a $REF ($COMMIT)"; else ok "$PREV → $COMMIT ($REF)"; fi
echo "  File cambiati:"; git diff --stat "$PREV" "$COMMIT" | tail -15 | sed 's/^/    /'
ok "Versione app $APP_VERSION, build $BUILD_NUMBER"

OUT="$APP_DIR/release/${REF}_build${BUILD_NUMBER}"
mkdir -p "$OUT"

say "Dipendenze Flutter"
flutter pub get || die "flutter pub get fallito"

RESULT_ANDROID="saltata"; RESULT_IOS="saltata"

# --- Android -------------------------------------------------------------------------
if [ $DO_ANDROID -eq 1 ]; then
  say "Build Android (App Bundle per il Play Store)"
  if flutter build appbundle --release --build-name="$APP_VERSION" --build-number="$BUILD_NUMBER"; then
    cp build/app/outputs/bundle/release/app-release.aab "$OUT/snapp-$APP_VERSION-$BUILD_NUMBER.aab"
    RESULT_ANDROID="OK"; ok "AAB pronto"
  else
    RESULT_ANDROID="FALLITA"; warn "Build Android fallita (dettagli nel log)"
  fi
fi

# --- iOS -----------------------------------------------------------------------------
if [ $DO_IOS -eq 1 ]; then
  say "Build iOS (IPA per App Store Connect)"
  if flutter build ipa --release --build-name="$APP_VERSION" --build-number="$BUILD_NUMBER"; then
    cp build/ios/ipa/*.ipa "$OUT/" 2>/dev/null
    if ls "$OUT"/*.ipa >/dev/null 2>&1; then
      RESULT_IOS="OK"; ok "IPA pronta"
    else
      RESULT_IOS="ARCHIVIO OK, IPA non esportata"
      warn "Archivio creato ma IPA non esportata: apri build/ios/archive/Runner.xcarchive con Xcode → Distribute App"
    fi
  else
    RESULT_IOS="FALLITA"; warn "Build iOS fallita (firma? account Apple in Xcode → Settings → Accounts). Dettagli nel log"
  fi
fi

# --- Riepilogo ---------------------------------------------------------------------------
say "Riepilogo"
echo "  Versione:  $REF (commit $COMMIT) — app $APP_VERSION, build $BUILD_NUMBER"
echo "  Android:   $RESULT_ANDROID"
echo "  iOS:       $RESULT_IOS"
echo "  File:      $OUT"
echo "  Log:       $LOG"
open "$OUT" 2>/dev/null || true

[ "$RESULT_ANDROID" != "FALLITA" ] && [ "$RESULT_IOS" != "FALLITA" ]
