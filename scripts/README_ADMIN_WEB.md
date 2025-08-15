# 🌐 Mercado da Sophia - Admin Web

## 📋 **Visão Geral**

O **Admin Web** é a versão web do painel administrativo do Mercado da Sophia, permitindo gerenciar produtos, pedidos e configurações através do navegador.

## 🚀 **Funcionalidades**

### ✅ **Implementadas**
- 🔐 **Autenticação** com Google Sign-In
- 👨‍💼 **Controle de acesso** (apenas administradores)
- 📦 **Gestão de produtos** (importar, editar, remover)
- 🔍 **Busca de produtos** no AliExpress
- 📊 **Dashboard** com estatísticas
- 🎨 **Interface responsiva** para desktop e mobile

### 🚧 **Em Desenvolvimento**
- 💳 **Gestão de pedidos** e rastreamento
- 📈 **Relatórios** de vendas e analytics
- ⚙️ **Configurações** da loja
- 👥 **Gestão de usuários**

## 🛠️ **Scripts Disponíveis**

### **Build e Deploy**
```bash
# Build do admin web
./scripts/build_admin_web.sh

# Deploy para Firebase Hosting
./scripts/deploy_admin_web.sh

# Teste local
./scripts/test_admin_web.sh
```

### **Desenvolvimento**
```bash
# Build para desenvolvimento
flutter build web --flavor admin --target lib/main_admin.dart --debug

# Servidor de desenvolvimento
flutter run -d chrome --flavor admin --target lib/main_admin.dart
```

## 🌐 **URLs**

### **Produção**
- **Admin Web**: https://mercadodasophia-bbd01.web.app
- **API Python**: https://service-api-aliexpress.mercadodasophia.com.br

### **Desenvolvimento**
- **Local**: http://localhost:8000 (após build)
- **Dev Server**: http://localhost:3000 (flutter run)

## 🔧 **Configuração**

### **Pré-requisitos**
- ✅ Flutter SDK (versão 3.0+)
- ✅ Firebase CLI (`npm install -g firebase-tools`)
- ✅ Conta Google (para autenticação)
- ✅ Acesso de administrador no Firebase

### **Variáveis de Ambiente**
```bash
# Firebase
FIREBASE_API_KEY=AIzaSyC_XU_s5EfydVgwzbY9yY3_Q6k0RtiEQFM
FIREBASE_PROJECT_ID=mercadodasophia-bbd01

# Google Sign-In
GOOGLE_CLIENT_ID=984078143510-fde3jsncdjium6ksojom6rgikaor9alb.apps.googleusercontent.com

# API Python
API_BASE_URL=https://service-api-aliexpress.mercadodasophia.com.br
```

## 📱 **Compatibilidade**

### **Navegadores Suportados**
- ✅ Chrome 90+
- ✅ Firefox 88+
- ✅ Safari 14+
- ✅ Edge 90+

### **Dispositivos**
- ✅ Desktop (Windows, macOS, Linux)
- ✅ Tablet (iPad, Android)
- ✅ Mobile (iPhone, Android) - Responsivo

## 🔒 **Segurança**

### **Autenticação**
- 🔐 Google Sign-In OAuth2
- 👨‍💼 Verificação de role de administrador
- 🚫 Acesso negado para usuários não-admin
- 🔄 Sessão persistente com Firebase Auth

### **Autorização**
- 📋 Lista de administradores no Firestore
- 🔍 Verificação em tempo real
- 🚪 Logout automático se perde acesso

## 📊 **Performance**

### **Otimizações**
- ⚡ Build otimizado para produção
- 🗜️ Compressão de assets
- 📦 Lazy loading de componentes
- 🎯 Cache de dados do Firebase

### **Métricas**
- 📈 Tamanho do bundle: ~2-3MB
- ⚡ Tempo de carregamento: <3s
- 🔄 Tempo de resposta: <500ms

## 🐛 **Debug e Logs**

### **Console do Navegador**
```javascript
// Habilitar logs detalhados
localStorage.setItem('debug', 'true');

// Verificar autenticação
console.log('User:', firebase.auth().currentUser);
```

### **Firebase Console**
- 📊 Analytics em tempo real
- 🔥 Logs de autenticação
- 📝 Logs de Firestore
- 🚨 Alertas de erro

## 🚀 **Deploy**

### **Firebase Hosting**
```bash
# Login no Firebase
firebase login

# Deploy automático
./scripts/deploy_admin_web.sh
```

### **Configuração Manual**
```bash
# Build
flutter build web --flavor admin --target lib/main_admin.dart --release

# Deploy
firebase deploy --only hosting
```

## 📞 **Suporte**

### **Problemas Comuns**
1. **Erro de autenticação**: Verificar Google Client ID
2. **Acesso negado**: Verificar role de admin no Firestore
3. **Build falha**: Verificar dependências do Flutter
4. **Deploy falha**: Verificar Firebase CLI e login

### **Contato**
- 📧 Email: suporte@mercadodasophia.com
- 📱 WhatsApp: (85) 99764-0050
- 🐛 Issues: GitHub do projeto

---

**Status**: ✅ **PRONTO PARA PRODUÇÃO**
**Versão**: 1.0.0
**Última atualização**: Dezembro 2024
