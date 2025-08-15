# 🔧 Correção do Google Sign-In - Mercado da Sophia

## 🚨 Problema Identificado

O erro `Unknown calling package name 'com.google.android.gms'` indica que o Google Sign-In não está configurado corretamente. O problema principal é que o `google-services.json` não possui os OAuth 2.0 Client IDs corretos para Android.

## 📋 Diagnóstico

### Erros nos Logs:
```
E/GoogleApiManager: Failed to get service from broker. 
E/GoogleApiManager: java.lang.SecurityException: Unknown calling package name 'com.google.android.gms'
```

### Problema no google-services.json:
- ✅ Tem `client_type: 3` (Web client)
- ❌ **Falta** `client_type: 1` (Android client) com SHA-1

## 🔧 Solução

### 1. **Configurar OAuth 2.0 Client IDs no Google Cloud Console**

1. Acesse [Google Cloud Console](https://console.cloud.google.com/)
2. Selecione o projeto `mercadodasophia-bbd01`
3. Vá para **APIs & Services** > **Credentials**
4. Clique em **+ CREATE CREDENTIALS** > **OAuth 2.0 Client IDs**

### 2. **Criar OAuth 2.0 Client ID para Android**

#### Para App Cliente:
- **Application type**: Android
- **Package name**: `com.mercadodasophia.client`
- **SHA-1 certificate fingerprint**: `B7:46:62:DC:11:DD:5E:50:D5:BA:87:E2:D7:68:32:71:53:E5:98:FE`

#### Para App Admin:
- **Application type**: Android
- **Package name**: `com.mercadodasophia.admin`
- **SHA-1 certificate fingerprint**: `B7:46:62:DC:11:DD:5E:50:D5:BA:87:E2:D7:68:32:71:53:E5:98:FE`

### 3. **Baixar google-services.json Atualizado**

Após criar os OAuth 2.0 Client IDs:

1. Vá para **Project Settings** no Firebase Console
2. Na seção **Your apps**, clique em **Download google-services.json**
3. Substitua o arquivo atual em `android/app/google-services.json`

### 4. **Estrutura Correta do google-services.json**

O arquivo deve ter esta estrutura:

```json
{
  "project_info": {
    "project_number": "984078143510",
    "project_id": "mercadodasophia-bbd01",
    "storage_bucket": "mercadodasophia-bbd01.firebasestorage.app"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:984078143510:android:80b49c822f8f2d77bfa537",
        "android_client_info": {
          "package_name": "com.mercadodasophia.client"
        }
      },
      "oauth_client": [
        {
          "client_id": "984078143510-fde3jsncdjium6ksojom6rgikaor9alb.apps.googleusercontent.com",
          "client_type": 3
        },
        {
          "client_id": "984078143510-ANDROID_CLIENT_ID_HERE.apps.googleusercontent.com",
          "client_type": 1
        }
      ],
      "api_key": [
        {
          "current_key": "AIzaSyDFs8K2gQGhKNSHUNZeCZII1YJbzwlncvQ"
        }
      ],
      "services": {
        "appinvite_service": {
          "other_platform_oauth_client": [
            {
              "client_id": "984078143510-fde3jsncdjium6ksojom6rgikaor9alb.apps.googleusercontent.com",
              "client_type": 3
            }
          ]
        }
      }
    },
    {
      "client_info": {
        "mobilesdk_app_id": "1:984078143510:android:80b49c822f8f2d77bfa537",
        "android_client_info": {
          "package_name": "com.mercadodasophia.admin"
        }
      },
      "oauth_client": [
        {
          "client_id": "984078143510-fde3jsncdjium6ksojom6rgikaor9alb.apps.googleusercontent.com",
          "client_type": 3
        },
        {
          "client_id": "984078143510-ANDROID_CLIENT_ID_HERE.apps.googleusercontent.com",
          "client_type": 1
        }
      ],
      "api_key": [
        {
          "current_key": "AIzaSyDFs8K2gQGhKNSHUNZeCZII1YJbzwlncvQ"
        }
      ],
      "services": {
        "appinvite_service": {
          "other_platform_oauth_client": [
            {
              "client_id": "984078143510-fde3jsncdjium6ksojom6rgikaor9alb.apps.googleusercontent.com",
              "client_type": 3
            }
          ]
        }
      }
    }
  ],
  "configuration_version": "1"
}
```

## 🔍 Verificação

### 1. **Verificar SHA-1 Fingerprint**
```bash
# Para debug keystore
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

# Para release keystore
keytool -list -v -keystore "mercadodasophia-release-key.jks" -alias mercadodasophia
```

### 2. **Verificar se o Google Sign-In está habilitado**
1. Firebase Console > **Authentication** > **Sign-in method**
2. Verificar se **Google** está habilitado
3. Verificar se o **Project support email** está configurado

### 3. **Testar o Login**
1. Executar o app: `flutter run --flavor client`
2. Ir para tela de login
3. Clicar em "Continuar com Google"
4. Verificar se não há mais erros

## 🚀 Comandos para Testar

```bash
# Limpar cache e rebuild
flutter clean
flutter pub get

# Executar app cliente
flutter run --flavor client

# Executar app admin
flutter run --flavor admin
```

## 📱 Troubleshooting

### Se ainda houver problemas:

1. **Verificar Google Play Services**
   - Certifique-se de que o Google Play Services está atualizado no dispositivo
   - Teste em um emulador com Google Play Services

2. **Verificar Package Name**
   - Confirme que o `applicationId` no `build.gradle.kts` corresponde ao configurado no Google Cloud Console

3. **Verificar SHA-1**
   - Use o SHA-1 correto (debug para desenvolvimento, release para produção)
   - Certifique-se de que o fingerprint está correto no Google Cloud Console

4. **Verificar Firebase Project**
   - Confirme que está usando o projeto correto
   - Verifique se o `google-services.json` é do projeto certo

## ✅ Checklist de Configuração

- [ ] OAuth 2.0 Client IDs criados no Google Cloud Console
- [ ] SHA-1 fingerprints configurados corretamente
- [ ] `google-services.json` atualizado com client_type: 1
- [ ] Google Sign-In habilitado no Firebase Authentication
- [ ] Package names corretos no build.gradle.kts
- [ ] Google Play Services atualizado no dispositivo

Após seguir estes passos, o Google Sign-In deve funcionar corretamente! 🎉
