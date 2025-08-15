# 🛒 Mercado da Sophia - Sistema Completo

## 📋 Visão Geral

Sistema completo de e-commerce com **Firebase** e **painel administrativo** integrado ao app Flutter.

### **🏗️ Arquitetura**
```
📱 App Flutter (Cliente + Admin)
├── 🔥 Firebase (Backend)
│   ├── Authentication
│   ├── Firestore Database
│   ├── Storage
│   └── Analytics
└── 🌐 Web Admin (Flutter Web)
```

## 🚀 Funcionalidades

### **📱 App Cliente**
- ✅ **Autenticação** com Firebase
- ✅ **Catálogo de produtos** em tempo real
- ✅ **Filtros por categoria**
- ✅ **Carrinho de compras**
- ✅ **Favoritos**
- ✅ **Histórico de pedidos**
- ✅ **Perfil do usuário**

### **⚙️ Painel Admin**
- ✅ **Dashboard** com estatísticas
- ✅ **Importação AliExpress** (web scraping)
- ✅ **Gestão de produtos** (CRUD)
- ✅ **Aprovação/rejeição** de produtos
- ✅ **Gestão de categorias**
- ✅ **Gestão de usuários**
- ✅ **Upload de imagens**

### **🔥 Firebase Integration**
- ✅ **Authentication** (login/registro)
- ✅ **Firestore** (banco de dados)
- ✅ **Storage** (imagens)
- ✅ **Real-time** updates
- ✅ **Security Rules**

## 📁 Estrutura do Projeto

```
📁 mercadodasophia/
├── lib/
│   ├── screens/
│   │   ├── client/           # Telas do cliente
│   │   │   ├── products_screen.dart
│   │   │   ├── auth_screen_v2.dart
│   │   │   ├── cart_screen.dart
│   │   │   └── ...
│   │   └── admin/            # Telas do admin
│   │       ├── admin_dashboard_screen.dart
│   │       ├── admin_import_screen.dart
│   │       ├── admin_products_screen.dart
│   │       ├── admin_categories_screen.dart
│   │       └── admin_users_screen.dart
│   ├── services/
│   │   ├── firebase_auth_service.dart
│   │   └── firebase_product_service.dart
│   ├── models/
│   │   └── product.dart
│   ├── widgets/
│   │   └── product_card_v2.dart
│   ├── theme/
│   │   └── app_theme.dart
│   ├── firebase_options.dart
│   └── main.dart
├── pubspec.yaml
└── README_COMPLETO.md
```

## 🔥 Configuração Firebase

### **1. Criar Projeto Firebase**
1. Acesse [Firebase Console](https://console.firebase.google.com/)
2. Clique em **"Adicionar projeto"**
3. Nome: `mercadodasophia`
4. Ative Google Analytics (opcional)

### **2. Configurar Serviços**

#### **Authentication**
1. Vá para **Authentication**
2. Ative **Email/Password**
3. Configure **Google Sign-in** (opcional)

#### **Firestore Database**
1. Vá para **Firestore Database**
2. Clique em **"Criar banco de dados"**
3. Escolha **"Iniciar no modo de teste"**
4. Localização: **us-central1**

#### **Storage**
1. Vá para **Storage**
2. Clique em **"Começar"**
3. Escolha **"Iniciar no modo de teste"**

### **3. Adicionar App Flutter**
1. No console Firebase, clique no ícone **"</>"** (Web)
2. Nome: `mercadodasophia`
3. Copie as configurações

### **4. Atualizar firebase_options.dart**
Substitua as configurações em `lib/firebase_options.dart`:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'SUA_API_KEY',
  appId: 'SEU_APP_ID',
  messagingSenderId: 'SEU_SENDER_ID',
  projectId: 'mercadodasophia',
  authDomain: 'mercadodasophia.firebaseapp.com',
  storageBucket: 'mercadodasophia.appspot.com',
);
```

## 🛠️ Instalação e Execução

### **1. Instalar Dependências**
```bash
flutter pub get
```

### **2. Configurar Firebase**
- Siga o guia de configuração acima
- Atualize `firebase_options.dart`

### **3. Executar o App**
```bash
# Desenvolvimento
flutter run

# Web
flutter run -d chrome

# Build para produção
flutter build apk
flutter build web
```

## 📊 Estrutura do Firestore

### **Coleção: users**
```javascript
{
  "uid": "string",
  "name": "string",
  "email": "string",
  "phone": "string?",
  "role": "customer|admin|manager|editor",
  "isActive": "boolean",
  "createdAt": "timestamp",
  "lastLogin": "timestamp",
  "preferences": {
    "notifications": "boolean",
    "marketing": "boolean"
  }
}
```

### **Coleção: products**
```javascript
{
  "id": "string",
  "name": "string",
  "description": "string",
  "price": "number",
  "originalPrice": "number?",
  "stockQuantity": "number",
  "categoryId": "string",
  "images": ["string"],
  "mainImage": "string",
  "isActive": "boolean",
  "isFeatured": "boolean",
  "isOnSale": "boolean",
  "searchKeywords": ["string"],
  "specifications": "object",
  "aliexpressId": "string?",
  "aliexpressUrl": "string?",
  "importedFrom": "aliexpress|manual",
  "status": "draft|pending|active|inactive|rejected",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### **Coleção: categories**
```javascript
{
  "id": "string",
  "name": "string",
  "slug": "string",
  "description": "string?",
  "image": "string?",
  "icon": "string?",
  "color": "string",
  "parentId": "string?",
  "level": "number",
  "sortOrder": "number",
  "isActive": "boolean",
  "isFeatured": "boolean",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

## 🔐 Regras de Segurança

### **Firestore Rules**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Usuários podem ler seus próprios dados
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Produtos: leitura pública, escrita apenas para admins
    match /products/{productId} {
      allow read: if true;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'manager'];
    }
    
    // Categorias: leitura pública, escrita apenas para admins
    match /categories/{categoryId} {
      allow read: if true;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'manager'];
    }
  }
}
```

### **Storage Rules**
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Imagens de produtos: leitura pública, upload apenas para admins
    match /products/{productId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null && 
        firestore.get(/databases/(default)/documents/users/$(request.auth.uid)).data.role in ['admin', 'manager'];
    }
  }
}
```

## 🎯 Fluxo de Importação AliExpress

### **1. Busca de Produtos**
```
App Admin → Firebase → AliExpress API → Resultados
```

### **2. Importação**
```
AliExpress → Processamento → Firebase → Aprovação → Loja
```

### **3. Aprovação**
```
Produto Pendente → Admin Review → Ativo/Rejeitado
```

## 📱 Telas do Sistema

### **Cliente**
- **Login/Registro**: Autenticação Firebase
- **Produtos**: Catálogo em tempo real
- **Carrinho**: Gestão de compras
- **Favoritos**: Produtos salvos
- **Pedidos**: Histórico de compras
- **Perfil**: Dados do usuário

### **Admin**
- **Dashboard**: Estatísticas gerais
- **Importação**: Busca AliExpress
- **Produtos**: CRUD completo
- **Categorias**: Gestão de categorias
- **Usuários**: Gestão de usuários

## 🔧 Funcionalidades Avançadas

### **Real-time Updates**
- Produtos atualizados em tempo real
- Notificações de novos produtos
- Status de pedidos em tempo real

### **Search & Filter**
- Busca por texto
- Filtros por categoria
- Ordenação por preço/popularidade

### **Image Management**
- Upload automático de imagens
- Redimensionamento automático
- CDN para performance

### **Analytics**
- Firebase Analytics integrado
- Métricas de vendas
- Comportamento do usuário

## 🚀 Deploy

### **App Flutter**
```bash
# Android
flutter build apk --release

# Web
flutter build web --release

# iOS
flutter build ios --release
```

### **Firebase Hosting (Web)**
```bash
# Instalar Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Inicializar
firebase init hosting

# Deploy
firebase deploy
```

## 📊 Monitoramento

### **Firebase Analytics**
- Eventos de usuário
- Conversões
- Performance

### **Firebase Performance**
- Tempo de carregamento
- Gargalos identificados

### **Firebase Crashlytics**
- Relatórios de crash
- Alertas automáticos

## 🔐 Segurança

### **Boas Práticas**
- ✅ Validação de dados no cliente
- ✅ Regras do Firestore para segurança
- ✅ Rate limiting
- ✅ Monitoramento de uso
- ✅ Backup regular

### **Roles de Usuário**
- **customer**: Cliente final (leitura apenas)
- **editor**: Pode editar produtos
- **manager**: Pode aprovar/rejeitar produtos
- **admin**: Acesso total ao sistema

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## 📞 Suporte

- **Email**: contato@mercadodasophia.com
- **Telefone**: (11) 99999-9999
- **Documentação**: [docs.mercadodasophia.com](https://docs.mercadodasophia.com)

## 📄 Licença

Este projeto está sob a licença MIT.

---

**🎯 Sistema completo e funcional! Pronto para produção!** 🚀 