# Chaves de Release - Mercado da Sophia

## 📋 Informações das Chaves

### Keystore de Release
- **Arquivo**: `mercadodasophia-release-key.jks`
- **Alias**: `mercadodasophia`
- **Senha**: `mercadodasophia2025`
- **Validade**: 10.000 dias (até 2052)

### SHA-1 Fingerprints

#### Release Keystore
```
SHA1: B7:46:62:DC:11:DD:5E:50:D5:BA:87:E2:D7:68:32:71:53:E5:98:FE
SHA256: B8:39:E6:86:F9:B9:68:9D:D0:BC:3E:49:F0:71:C3:C8:A3:66:8F:64:B1:7F:68:45:58:53:BB:C3:E5:80:7C:51
```

## 🔧 Configuração

### 1. Arquivo key.properties
Localizado em: `android/key.properties`
```properties
storePassword=mercadodasophia2025
keyPassword=mercadodasophia2025
keyAlias=mercadodasophia
storeFile=../mercadodasophia-release-key.jks
```

### 2. Build.gradle.kts
O arquivo `android/app/build.gradle.kts` já está configurado para usar o keystore de release.

## 📱 Configuração do Google Sign-In

### Google Cloud Console
Use o SHA-1 da release keystore para configurar o Google Sign-In:

1. Acesse [Google Cloud Console](https://console.cloud.google.com/)
2. Vá para "APIs & Services" > "Credentials"
3. Configure OAuth 2.0 Client IDs com:
   - **Package name**: `com.mercadodasophia.client` (app cliente)
   - **Package name**: `com.mercadodasophia.admin` (app admin)
   - **SHA-1**: `B7:46:62:DC:11:DD:5E:50:D5:BA:87:E2:D7:68:32:71:53:E5:98:FE`

## 🚀 Build de Release

### Comando para build de release:
```bash
# App Cliente
flutter build apk --release --flavor client

# App Admin
flutter build apk --release --flavor admin

# Bundle para Play Store
flutter build appbundle --release --flavor client
flutter build appbundle --release --flavor admin
```

## 🔒 Segurança

### Arquivos Protegidos
Os seguintes arquivos estão no `.gitignore`:
- `*.jks` - Arquivos keystore
- `*.keystore` - Arquivos keystore alternativos
- `android/key.properties` - Configurações das chaves

### Backup das Chaves
⚠️ **IMPORTANTE**: Faça backup seguro das chaves:
- `mercadodasophia-release-key.jks`
- `android/key.properties`

**Perder essas chaves significa não conseguir atualizar o app na Play Store!**

## 📝 Informações do Certificado

### Detalhes do Certificado
- **Proprietário**: CN=Francisco Adonay, OU=Mercado da Sophia, O=Native Computers, L=Eusebio, ST=ceara, C=Br
- **Emissor**: CN=Francisco Adonay, OU=Mercado da Sophia, O=Native Computers, L=Eusebio, ST=ceara, C=Br
- **Número de série**: 9735ed4d3400f940
- **Válido de**: 12 de agosto de 2025 até 28 de dezembro de 2052
- **Algoritmo**: SHA384withRSA
- **Tamanho da chave**: 2048 bits

## 🔄 Comandos Úteis

### Gerar SHA-1 da Release Keystore
```bash
keytool -list -v -keystore "mercadodasophia-release-key.jks" -alias mercadodasophia
```

### Verificar Assinatura do APK
```bash
jarsigner -verify -verbose -certs app-release.apk
```

### Listar Conteúdo do Keystore
```bash
keytool -list -keystore "mercadodasophia-release-key.jks"
```
