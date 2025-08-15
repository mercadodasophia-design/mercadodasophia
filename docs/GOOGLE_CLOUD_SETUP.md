# 🔧 Configuração OAuth 2.0 Client IDs - Google Cloud Console

## 🚀 Passo a Passo para Resolver o Google Sign-In

### 1. **Acessar Google Cloud Console**
1. Vá para: https://console.cloud.google.com/
2. Selecione o projeto: `mercadodasophia-bbd01`

### 2. **Navegar para Credentials**
1. No menu lateral, clique em **APIs & Services**
2. Clique em **Credentials**

### 3. **Criar OAuth 2.0 Client ID para App Cliente**

1. Clique em **+ CREATE CREDENTIALS**
2. Selecione **OAuth 2.0 Client IDs**
3. Configure:
   - **Application type**: Android
   - **Package name**: `com.mercadodasophia.client`
   - **SHA-1 certificate fingerprint**: `B7:46:62:DC:11:DD:5E:50:D5:BA:87:E2:D7:68:32:71:53:E5:98:FE`
4. Clique em **Create**

### 4. **Criar OAuth 2.0 Client ID para App Admin**

1. Clique em **+ CREATE CREDENTIALS**
2. Selecione **OAuth 2.0 Client IDs**
3. Configure:
   - **Application type**: Android
   - **Package name**: `com.mercadodasophia.admin`
   - **SHA-1 certificate fingerprint**: `B7:46:62:DC:11:DD:5E:50:D5:BA:87:E2:D7:68:32:71:53:E5:98:FE`
4. Clique em **Create**

### 5. **Baixar google-services.json Atualizado**

1. Vá para: https://console.firebase.google.com/
2. Selecione o projeto: `mercadodasophia-bbd01`
3. Clique na engrenagem (⚙️) ao lado de "Project Overview"
4. Selecione **Project settings**
5. Na aba **General**, role para baixo até **Your apps**
6. Clique em **Download google-services.json**
7. Substitua o arquivo em `android/app/google-services.json`

### 6. **Verificar Firebase Authentication**

1. No Firebase Console, vá para **Authentication**
2. Clique em **Sign-in method**
3. Verifique se **Google** está habilitado
4. Se não estiver, clique em **Google** e habilite

### 7. **Testar o App**

```bash
# Limpar cache
flutter clean
flutter pub get

# Executar app
flutter run --flavor client
```

## 📱 SHA-1 Fingerprints

### Release Keystore (Produção)
```
SHA1: B7:46:62:DC:11:DD:5E:50:D5:BA:87:E2:D7:68:32:71:53:E5:98:FE
```

### Debug Keystore (Desenvolvimento)
Para obter o SHA-1 do debug keystore:
```bash
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

## 🔍 Verificação

Após configurar, o `google-services.json` deve ter esta estrutura:

```json
{
  "oauth_client": [
    {
      "client_id": "984078143510-fde3jsncdjium6ksojom6rgikaor9alb.apps.googleusercontent.com",
      "client_type": 3
    },
    {
      "client_id": "984078143510-REAL_ANDROID_CLIENT_ID.apps.googleusercontent.com",
      "client_type": 1
    }
  ]
}
```

## ✅ Checklist

- [ ] OAuth 2.0 Client ID criado para `com.mercadodasophia.client`
- [ ] OAuth 2.0 Client ID criado para `com.mercadodasophia.admin`
- [ ] SHA-1 fingerprints configurados corretamente
- [ ] `google-services.json` baixado e substituído
- [ ] Google Sign-In habilitado no Firebase Authentication
- [ ] App testado e funcionando

## 🚨 Se ainda houver problemas:

1. **Verificar package names** no `build.gradle.kts`
2. **Verificar SHA-1** no Google Cloud Console
3. **Limpar cache** do app no dispositivo
4. **Reinstalar** o app

Após seguir estes passos, o Google Sign-In deve funcionar perfeitamente! 🎉




