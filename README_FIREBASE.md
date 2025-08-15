# 🔥 Firebase Setup - Mercado da Sophia

## 📋 Configuração do Firebase

### **1. Criar Projeto Firebase**

1. Acesse [Firebase Console](https://console.firebase.google.com/)
2. Clique em **"Adicionar projeto"**
3. Nome: `mercadodasophia`
4. Ative o Google Analytics (opcional)
5. Clique em **"Criar projeto"**

### **2. Configurar Autenticação**

1. No console Firebase, vá para **Authentication**
2. Clique em **"Começar"**
3. Em **"Sign-in method"**, ative:
   - ✅ **Email/Password**
   - ✅ **Google** (opcional)
4. Clique em **"Salvar"**

### **3. Configurar Firestore Database**

1. Vá para **Firestore Database**
2. Clique em **"Criar banco de dados"**
3. Escolha **"Iniciar no modo de teste"**
4. Localização: **us-central1** (ou mais próxima)
5. Clique em **"Próximo"**

### **4. Configurar Storage**

1. Vá para **Storage**
2. Clique em **"Começar"**
3. Escolha **"Iniciar no modo de teste"**
4. Localização: **us-central1**
5. Clique em **"Próximo"**

### **5. Adicionar App Flutter**

1. No console Firebase, clique no ícone **"</>"** (Web)
2. Nome do app: `mercadodasophia`
3. Clique em **"Registrar app"**
4. Copie as configurações

### **6. Atualizar firebase_options.dart**

Substitua as configurações no arquivo `lib/firebase_options.dart`:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'SUA_API_KEY_AQUI',
  appId: 'SEU_APP_ID_AQUI',
  messagingSenderId: 'SEU_SENDER_ID',
  projectId: 'mercadodasophia',
  authDomain: 'mercadodasophia.firebaseapp.com',
  storageBucket: 'mercadodasophia.appspot.com',
  measurementId: 'SEU_MEASUREMENT_ID',
);
```

### **7. Regras do Firestore**

No console Firebase, vá para **Firestore Database > Regras** e configure:

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

### **8. Regras do Storage**

No console Firebase, vá para **Storage > Regras** e configure:

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

## 🚀 Estrutura do Firestore

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

## 📱 Testando a Configuração

### **1. Instalar dependências**
```bash
flutter pub get
```

### **2. Executar o app**
```bash
flutter run
```

### **3. Verificar logs**
- Se não houver erros de Firebase, a configuração está correta
- Verifique se a autenticação funciona
- Teste a criação de produtos

## 🔧 Troubleshooting

### **Erro: "Firebase not initialized"**
- Verifique se `firebase_options.dart` está correto
- Certifique-se de que `Firebase.initializeApp()` está sendo chamado

### **Erro: "Permission denied"**
- Verifique as regras do Firestore
- Confirme se o usuário tem as permissões corretas

### **Erro: "Storage permission denied"**
- Verifique as regras do Storage
- Confirme se o usuário tem role de admin/manager

## 📊 Monitoramento

### **Firebase Analytics**
- Vá para **Analytics** no console
- Monitore eventos de usuário
- Acompanhe conversões

### **Firebase Performance**
- Monitore performance do app
- Identifique gargalos

### **Firebase Crashlytics**
- Monitore crashes
- Receba alertas automáticos

## 🔐 Segurança

### **Boas Práticas**
- ✅ Sempre valide dados no cliente
- ✅ Use regras do Firestore para segurança
- ✅ Implemente rate limiting
- ✅ Monitore uso da API
- ✅ Faça backup regular dos dados

### **Roles de Usuário**
- **customer**: Cliente final (leitura apenas)
- **editor**: Pode editar produtos
- **manager**: Pode aprovar/rejeitar produtos
- **admin**: Acesso total ao sistema

---

**🎯 Próximo passo: Configurar o painel admin web!** 