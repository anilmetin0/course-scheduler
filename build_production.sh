#!/bin/bash

echo "🚀 Course Scheduler - Build Script"
echo "================================="

# Environment variables yükle
source .env

GIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || true)
GIT_DEFINE=""
if [ -n "$GIT_SHA" ]; then
  GIT_DEFINE="--dart-define=GIT_SHA=$GIT_SHA"
fi

echo "� Generating code files (.g.dart)..."
flutter pub run build_runner build --delete-conflicting-outputs

echo "�📦 Building with WASM for production..."
flutter build web --wasm --release $GIT_DEFINE --dart-define-from-file=firebase_config.env

echo "✅ Build completed!"
echo "📊 Bundle size:"
du -h build/web/main.dart.wasm
du -h build/web/main.dart.mjs

echo ""
echo "🌐 Deploy to Firebase:"
echo "firebase deploy --project course-scheduler-25"

echo ""
echo "🔍 Test locally:"
echo "firebase serve"
