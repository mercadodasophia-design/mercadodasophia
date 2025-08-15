#!/bin/bash

echo "🧪 Testando Mercado da Sophia Admin Web App..."

# Build Web Admin
echo "🌐 Building Web Admin..."
./scripts/build_admin_web.sh

if [ $? -ne 0 ]; then
    echo "❌ Build falhou. Abortando teste."
    exit 1
fi

# Verificar se Python está disponível
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
else
    echo "❌ Python não encontrado. Instale Python para testar localmente."
    exit 1
fi

# Navegar para o diretório build/web
cd build/web

echo "🚀 Iniciando servidor local..."
echo "🌐 Admin Web disponível em: http://localhost:8000"
echo "📱 Pressione Ctrl+C para parar o servidor"
echo ""

# Iniciar servidor HTTP
$PYTHON_CMD -m http.server 8000
