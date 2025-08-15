#!/bin/bash

echo "🚀 Deploying Mercado da Sophia Admin Web App..."

# Verificar se Firebase CLI está instalado
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI não encontrado. Instale com: npm install -g firebase-tools"
    exit 1
fi

# Verificar se está logado no Firebase
if ! firebase projects:list &> /dev/null; then
    echo "❌ Não está logado no Firebase. Execute: firebase login"
    exit 1
fi

# Build Web Admin primeiro
echo "🌐 Building Web Admin..."
./scripts/build_admin_web.sh

if [ $? -ne 0 ]; then
    echo "❌ Build falhou. Abortando deploy."
    exit 1
fi

# Criar firebase.json se não existir
if [ ! -f "firebase.json" ]; then
    echo "📝 Criando firebase.json..."
    cat > firebase.json << EOF
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "**/*.@(js|css)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age=31536000"
          }
        ]
      }
    ]
  }
}
EOF
fi

# Deploy para Firebase Hosting
echo "🚀 Fazendo deploy para Firebase Hosting..."
firebase deploy --only hosting

if [ $? -eq 0 ]; then
    echo "✅ Deploy concluído com sucesso!"
    echo "🌐 Admin Web disponível em: https://mercadodasophia-bbd01.web.app"
    echo ""
    echo "📊 Informações do deploy:"
    firebase hosting:sites:list
else
    echo "❌ Erro no deploy"
    exit 1
fi
