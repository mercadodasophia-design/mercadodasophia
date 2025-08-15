#!/bin/bash

echo "⚙️ Building Mercado da Sophia Admin App..."

# Build APK
echo "📱 Building APK..."
flutter build apk --flavor admin --target lib/main_admin.dart --release

# Build Web
echo "🌐 Building Web..."
flutter build web --flavor admin --target lib/main_admin.dart --release

echo "✅ Admin app build completed!"
echo "📁 APK: build/app/outputs/flutter-apk/app-admin-release.apk"
echo "�� Web: build/web/" 