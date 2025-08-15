#!/bin/bash

echo "🏪 Building Mercado da Sophia Client App..."

# Build APK
echo "📱 Building APK..."
flutter build apk --flavor client --target lib/main_client.dart --release

# Build Web
echo "🌐 Building Web..."
flutter build web --flavor client --target lib/main_client.dart --release

echo "✅ Client app build completed!"
echo "📁 APK: build/app/outputs/flutter-apk/app-client-release.apk"
echo "�� Web: build/web/" 