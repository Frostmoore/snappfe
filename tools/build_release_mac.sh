#!/bin/bash
# =============================================================================
# SNAPP — build di produzione Android (AAB) + iOS (IPA) dall'ultima versione
# pubblicata su GitHub. Da eseguire su un Mac con Flutter, Xcode e CocoaPods.
#
# Uso:
#   ./build_release_mac.sh                     # ultima versione (branch vX.Y.Z più alto)
#   ./build_release_mac.sh --ref v1.1.0        # una versione precisa
#   ./build_release_mac.sh --only android      # solo Android (oppure: --only ios)
#   ./build_release_mac.sh --build-number 42   # forza il numero di build
#
# Cartelle (tutte sotto ~/snapp-build, create al primo avvio):
#   config.sh          impostazioni (Team Apple). Vedi il modello creato al primo avvio.
#   secrets/           key.properties + keystore .jks della firma Android (NON condividere)
#   work/              copia del codice scaricata a ogni build (viene ricreata)
#   output/            i file finali, una sottocartella per build
#   logs/              log completo di ogni build
#
# Numero di build: se non indicato è AAMMGGHH (es. 26100614), sempre crescente,
# come richiesto da Play Store e App Store a ogni caricamento.
# =============================================================================
set -uo pipefail

REPO_URL="https://github.com/Frostmoore/snappfe.git"
EXPECTED_FLUTTER="3.27"          # versione con cui è sviluppata l'app
BASE="$HOME/snapp-build"
CONFIG="$BASE/config.sh"
SECRETS="$BASE/secrets"

REF=""
ONLY=""
BUILD_NUMBER=""

# --- Argomenti -----------------------------------------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    --ref)          REF="${2:-}"; shift 2 ;;
    --only)         ONLY="${2:-}"; shift 2 ;;
    --build-number) BUILD_NUMBER="${2:-}"; shift 2 ;;
    -h|--help)      sed -n '2,24p' "$0"; exit 0 ;;
    *) echo "Argomento sconosciuto: $1 (usa --help)"; exit 2 ;;
  esac
done
if [ -n "$ONLY" ] && [ "$ONLY" != "android" ] && [ "$ONLY" != "ios" ]; then
  echo "--only accetta solo: android | ios"; exit 2
fi
if [ -n "$BUILD_NUMBER" ] && ! [[ "$BUILD_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "--build-number deve essere un numero intero"; exit 2
fi

mkdir -p "$BASE/work" "$BASE/output" "$BASE/logs" "$SECRETS"
chmod 700 "$SECRETS"

STAMP="$(date +%Y%m%d_%H%M%S)"
LOG="$BASE/logs/build_$STAMP.log"
exec > >(tee -a "$LOG") 2>&1

say()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m  ✓ %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m  ! %s\033[0m\n' "$*"; }
die()  { printf '\033[1;31m  ✗ %s\033[0m\n' "$*"; echo "Log completo: $LOG"; exit 1; }

# --- Config: al primo avvio crea il modello e si ferma ---------------------------
if [ ! -f "$CONFIG" ]; then
  cat > "$CONFIG" <<'EOF'
# Impostazioni build SNAPP (questo file resta sul Mac, non va su GitHub).

# Team ID Apple (10 caratteri, es. AB12CD34EF): developer.apple.com → Membership.
# Serve per firmare la build iOS. L'account Apple deve essere aggiunto in
# Xcode → Settings → Accounts.
APPLE_TEAM_ID=""
EOF
  say "Primo avvio: creato $CONFIG"
  echo "  1) Compila APPLE_TEAM_ID in $CONFIG"
  echo "  2) Copia in $SECRETS i file di firma Android: key.properties + il file .jks"
  echo "  Poi rilancia lo script."
  exit 0
fi
# shellcheck source=/dev/null
. "$CONFIG"
APPLE_TEAM_ID="${APPLE_TEAM_ID:-}"

DO_ANDROID=1; DO_IOS=1
[ "$ONLY" = "android" ] && DO_IOS=0
[ "$ONLY" = "ios" ] && DO_ANDROID=0

# --- Prerequisiti ---------------------------------------------------------------
say "Controllo prerequisiti"
command -v git >/dev/null     || die "git non trovato (installa gli strumenti da riga di comando: xcode-select --install)"
command -v flutter >/dev/null || die "flutter non trovato nel PATH"
FLUTTER_VER="$(flutter --version 2>/dev/null | head -1 | awk '{print $2}')"
ok "Flutter $FLUTTER_VER"
case "$FLUTTER_VER" in
  "$EXPECTED_FLUTTER".*) ;;
  *) warn "L'app è sviluppata con Flutter $EXPECTED_FLUTTER.x: con $FLUTTER_VER la build potrebbe fallire o comportarsi diversamente." ;;
esac
if [ $DO_ANDROID -eq 1 ]; then
  # Su macOS /usr/bin/java esiste anche senza JDK: si controlla l'SDK Android.
  if [ -z "${ANDROID_HOME:-}" ] && [ ! -d "$HOME/Library/Android/sdk" ]; then
    warn "SDK Android non trovato (ANDROID_HOME o ~/Library/Android/sdk): installa Android Studio se la build fallisce"
  fi
fi
if [ $DO_IOS -eq 1 ]; then
  command -v xcodebuild >/dev/null || die "Xcode non trovato"
  command -v pod >/dev/null        || die "CocoaPods non trovato (brew install cocoapods)"
  [ -n "$APPLE_TEAM_ID" ]          || die "APPLE_TEAM_ID vuoto in $CONFIG"
  [[ "$APPLE_TEAM_ID" =~ ^[A-Z0-9]{10}$ ]] || die "APPLE_TEAM_ID non valido: deve essere di 10 caratteri (lettere maiuscole e cifre)"
fi

# Firma Android: senza chiave di upload NON si procede (la build firmata col
# keystore di debug verrebbe rifiutata dal Play Store).
if [ $DO_ANDROID -eq 1 ]; then
  [ -f "$SECRETS/key.properties" ] || die "Manca $SECRETS/key.properties (firma Android)"
  JKS="$(ls "$SECRETS"/*.jks "$SECRETS"/*.keystore 2>/dev/null | head -1)"
  [ -n "$JKS" ] || die "Manca il keystore (.jks) in $SECRETS"
  ok "Firma Android: $(basename "$JKS")"
fi

# --- Versione da scaricare ------------------------------------------------------
say "Ricerca della versione"
if [ -z "$REF" ]; then
  # Branch vX.Y.Z → il più alto per numero (non per ordine alfabetico: v1.10 > v1.9).
  REF="$(git ls-remote --heads "$REPO_URL" 'v*' \
        | sed -E 's#.*refs/heads/##' \
        | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' \
        | sed 's/^v//' | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)"
  [ -n "$REF" ] || die "Nessun branch di versione (vX.Y.Z) trovato su $REPO_URL"
  REF="v$REF"
fi
ok "Versione: $REF"

# --- Download pulito -------------------------------------------------------------
say "Download del codice ($REF)"
WORK="$BASE/work/snappfe"
rm -rf "$WORK"
git clone --quiet --depth 1 --branch "$REF" "$REPO_URL" "$WORK" || die "Clone fallito (versione $REF esistente?)"
cd "$WORK" || die "Cartella di lavoro non accessibile"
COMMIT="$(git rev-parse --short HEAD)"
APP_VERSION="$(grep -E '^version:' pubspec.yaml | awk '{print $2}' | cut -d+ -f1)"
[ -n "$BUILD_NUMBER" ] || BUILD_NUMBER="$(date +%y%m%d%H)"
ok "Commit $COMMIT — versione app $APP_VERSION, build $BUILD_NUMBER"

OUT="$BASE/output/${REF}_build${BUILD_NUMBER}_$STAMP"
mkdir -p "$OUT"

say "Dipendenze Flutter"
flutter pub get || die "flutter pub get fallito"

RESULT_ANDROID="saltata"; RESULT_IOS="saltata"

# --- Android ----------------------------------------------------------------------
if [ $DO_ANDROID -eq 1 ]; then
  say "Build Android (App Bundle per il Play Store)"
  # key.properties va in android/; storeFile reso assoluto (Gradle lo risolve da android/app).
  sed -E "s#^storeFile=.*#storeFile=$JKS#" "$SECRETS/key.properties" > android/key.properties
  chmod 600 android/key.properties
  if flutter build appbundle --release --build-name="$APP_VERSION" --build-number="$BUILD_NUMBER"; then
    mkdir -p "$OUT/android"
    cp build/app/outputs/bundle/release/app-release.aab "$OUT/android/snapp-$APP_VERSION-$BUILD_NUMBER.aab"
    RESULT_ANDROID="OK"
    ok "AAB pronto"
  else
    RESULT_ANDROID="FALLITA"
    warn "Build Android fallita (dettagli nel log)"
  fi
  rm -f android/key.properties   # niente credenziali lasciate nella copia di lavoro
fi

# --- iOS --------------------------------------------------------------------------
if [ $DO_IOS -eq 1 ]; then
  say "Build iOS (IPA per App Store Connect)"
  # Il Team Apple non è nel repo: lo si imposta solo nella copia di lavoro, sulle
  # configurazioni del target Runner (bundle com.gsv.snapp).
  # (Stessa riga: il formato .pbxproj ignora gli a capo, e il sed resta portabile.)
  sed -i '' -E "s#^([[:space:]]*)PRODUCT_BUNDLE_IDENTIFIER = com\.gsv\.snapp;#\1DEVELOPMENT_TEAM = $APPLE_TEAM_ID; PRODUCT_BUNDLE_IDENTIFIER = com.gsv.snapp;#" ios/Runner.xcodeproj/project.pbxproj
  [ "$(grep -c "DEVELOPMENT_TEAM = $APPLE_TEAM_ID;" ios/Runner.xcodeproj/project.pbxproj)" -ge 1 ] \
    || die "Impossibile impostare il Team Apple nel progetto Xcode"
  if flutter build ipa --release --build-name="$APP_VERSION" --build-number="$BUILD_NUMBER"; then
    mkdir -p "$OUT/ios"
    cp build/ios/ipa/*.ipa "$OUT/ios/" 2>/dev/null
    cp -R build/ios/archive/Runner.xcarchive "$OUT/ios/" 2>/dev/null
    if ls "$OUT"/ios/*.ipa >/dev/null 2>&1; then
      RESULT_IOS="OK"
      ok "IPA pronta"
    else
      RESULT_IOS="ARCHIVIO OK, IPA non esportata"
      warn "Archivio creato ma IPA non esportata: apri $OUT/ios/Runner.xcarchive con Xcode → Distribute App"
    fi
  else
    RESULT_IOS="FALLITA"
    warn "Build iOS fallita: controlla che l'account Apple sia in Xcode → Settings → Accounts (dettagli nel log)"
  fi
fi

# --- Riepilogo ----------------------------------------------------------------------
say "Riepilogo"
echo "  Versione:  $REF (commit $COMMIT) — app $APP_VERSION, build $BUILD_NUMBER"
echo "  Android:   $RESULT_ANDROID"
echo "  iOS:       $RESULT_IOS"
echo "  File:      $OUT"
echo "  Log:       $LOG"
open "$OUT" 2>/dev/null || true

[ "$RESULT_ANDROID" != "FALLITA" ] && [ "$RESULT_IOS" != "FALLITA" ]
