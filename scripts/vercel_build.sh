#!/usr/bin/env bash
# Gene - Nov, 08, 2026: Automated Flutter Web build script for Vercel CI/CD & Beta Deployments
set -euo pipefail

echo "==> Preparing BookIt Flutter Web build for Vercel..."

# 1. Resolve or install Flutter SDK in Vercel Linux build container
if command -v flutter >/dev/null 2>&1; then
  echo "==> Using system Flutter SDK: $(command -v flutter)"
else
  FLUTTER_DIR="/tmp/flutter"
  if [ ! -d "$FLUTTER_DIR" ]; then
    echo "==> Cloning Flutter stable SDK into $FLUTTER_DIR..."
    git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_DIR"
  fi
  export PATH="$FLUTTER_DIR/bin:$PATH"
fi

flutter --version
flutter config --enable-web

# 2. Install Dart/Flutter package dependencies
flutter pub get

# 3. Assemble optional --dart-define arguments from Vercel Environment Variables
DART_DEFINES=()
if [ -n "${SUPABASE_URL:-}" ]; then
  DART_DEFINES+=("--dart-define=SUPABASE_URL=${SUPABASE_URL}")
fi
if [ -n "${SUPABASE_ANON_KEY:-}" ]; then
  DART_DEFINES+=("--dart-define=SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}")
fi
if [ -n "${FORCE_MOCK_MODE:-}" ]; then
  DART_DEFINES+=("--dart-define=FORCE_MOCK_MODE=${FORCE_MOCK_MODE}")
fi

# 4. Build release web bundle into build/web
echo "==> Running flutter build web --release..."
if [ ${#DART_DEFINES[@]} -gt 0 ]; then
  flutter build web --release "${DART_DEFINES[@]}"
else
  flutter build web --release
fi

echo "==> BookIt Web build completed successfully in build/web!"
