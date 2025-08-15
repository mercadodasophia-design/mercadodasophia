#!/bin/bash

echo "🌐 Building Mercado da Sophia Admin Web App..."

# Verificar se Flutter está instalado
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter não encontrado. Instale o Flutter primeiro."
    exit 1
fi

# Limpar builds anteriores
echo "🧹 Limpando builds anteriores..."
flutter clean

# Get dependencies
echo "📦 Obtendo dependências..."
flutter pub get

# Build Web Admin
echo "🌐 Building Web Admin..."
flutter build web \
    --flavor admin \
    --target lib/main_admin.dart \
    --release \
    --web-renderer html \
    --dart-define=FLUTTER_WEB_USE_SKIA=false

# Verificar se o build foi bem-sucedido
if [ $? -eq 0 ]; then
    echo "✅ Build Web Admin concluído com sucesso!"
    echo "📁 Arquivos gerados em: build/web/"
    echo ""
    echo "🚀 Para testar localmente:"
    echo "   cd build/web"
    echo "   python -m http.server 8000"
    echo "   Abra: http://localhost:8000"
    echo ""
    echo "📊 Tamanho do build:"
    du -sh build/web/
    echo ""
    echo "📋 Arquivos principais:"
    ls -la build/web/
else
    echo "❌ Erro no build Web Admin"
    exit 1
fi
