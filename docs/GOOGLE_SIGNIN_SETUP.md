# Configuração do Google Sign-In

## Visão Geral
Este documento explica como configurar o Google Sign-In no aplicativo Mercado da Sophia.

## Dependências
O Google Sign-In já está configurado com as seguintes dependências:
- `google_sign_in: ^6.1.6`

## Configuração do Firebase
1. O arquivo `google-services.json` já está configurado no projeto
2. O plugin `com.google.gms.google-services` já está aplicado no `build.gradle.kts`

## Configuração do Google Cloud Console
Para que o Google Sign-In funcione corretamente, você precisa:

### 1. Configurar OAuth 2.0 no Google Cloud Console
1. Acesse [Google Cloud Console](https://console.cloud.google.com/)
2. Selecione seu projeto
3. Vá para "APIs & Services" > "Credentials"
4. Clique em "Create Credentials" > "OAuth 2.0 Client IDs"
5. Configure para Android com:
   - Package name: `com.mercadodasophia.client` (para app cliente)
   - Package name: `com.mercadodasophia.admin` (para app admin)
   - SHA-1 fingerprint: Obtenha executando:
     ```bash
     keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
     ```

### 2. Configurar SHA-1 para Release
Para builds de release, você também precisa adicionar o SHA-1 do keystore de release:
```bash
keytool -list -v -keystore <caminho-do-keystore> -alias <alias> -storepass <senha> -keypass <senha>
```

## Implementação no Código

### AuthService
O `AuthService` já está configurado com:
- Método `signInWithGoogle()` implementado
- Criação automática de usuário no Firestore
- Tratamento de erros

### Tela de Login
A `ClientLoginScreen` já inclui:
- Botão "Entrar com Google"
- Tratamento de loading
- Feedback de sucesso/erro

## Funcionalidades Implementadas

### Login com Google
- ✅ Autenticação via Google
- ✅ Criação automática de conta no Firestore
- ✅ Atualização de último login
- ✅ Tratamento de erros
- ✅ Feedback visual

### Cadastro Normal
- ✅ Campos: Nome, Email, Telefone (opcional), Senha, Confirmação
- ✅ Validação robusta de senha
- ✅ Indicador de força da senha
- ✅ Validação de telefone brasileiro
- ✅ Criação de conta no Firebase Auth e Firestore

## Testando
1. Execute o app: `flutter run`
2. Vá para a tela de login
3. Teste o botão "Entrar com Google"
4. Teste o cadastro com email/senha

## Troubleshooting

### Erro: "Sign in failed"
- Verifique se o SHA-1 está configurado corretamente no Google Cloud Console
- Verifique se o package name está correto

### Erro: "Network error"
- Verifique a conexão com a internet
- Verifique se o Firebase está configurado corretamente

### Erro: "Invalid client"
- Verifique se o `google-services.json` está atualizado
- Verifique se o projeto no Firebase está correto

## Próximos Passos
- [ ] Implementar recuperação de senha
- [ ] Adicionar verificação de email
- [ ] Implementar login com outros provedores (Facebook, Apple)
- [ ] Adicionar biometria (fingerprint/face ID)
