#!/bin/bash

echo "🛠️ Course Scheduler - Development Build"
echo "======================================"

# Environment variables yükle
source .env

GIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || true)
GIT_DEFINE=""
if [ -n "$GIT_SHA" ]; then
  GIT_DEFINE="--dart-define=GIT_SHA=$GIT_SHA"
fi

echo "🔧 Building for development with WASM..."
flutter build web --wasm $GIT_DEFINE --dart-define-from-file=firebase_config.env

echo "✅ Development build completed!"

echo ""
echo "🔍 Test locally:"
echo "cd build/web && python3 -m http.server 8080"
echo "Then open: http://localhost:8080"
