# Funcionalidades de Localização - Mercado da Sophia

## 📍 Visão Geral
O app agora possui funcionalidades completas de localização para melhorar a experiência do usuário.

## 🔧 Dependências Implementadas

### Pacotes de Localização
- `geolocator: ^10.1.0` - Obter posição GPS
- `geocoding: ^2.1.1` - Converter coordenadas em endereços
- `permission_handler: ^11.0.1` - Gerenciar permissões

## 📱 Funcionalidades Implementadas

### 1. **Obtenção Automática de Localização**
- ✅ Solicita permissão de localização ao abrir o app
- ✅ Obtém posição GPS com alta precisão
- ✅ Converte coordenadas em endereço legível
- ✅ Exibe localização no header da tela principal

### 2. **Interface de Localização**
- ✅ **Header da tela principal**: Mostra endereço atual
- ✅ **Indicador de loading**: Durante obtenção da localização
- ✅ **Botão de atualizar**: Para obter nova localização
- ✅ **Drawer**: Seção dedicada à localização

### 3. **Gerenciamento de Estado**
- ✅ **LocationProvider**: Gerencia estado da localização
- ✅ **UserLocation Model**: Estrutura de dados da localização
- ✅ **LocationService**: Serviço para operações de localização

## 🎯 Como Funciona

### **Inicialização**
1. App abre na tela de produtos
2. Após 500ms, inicia obtenção de localização
3. Solicita permissão se necessário
4. Obtém posição GPS
5. Converte para endereço
6. Exibe na interface

### **Permissões**
- `ACCESS_FINE_LOCATION` - Localização precisa
- `ACCESS_COARSE_LOCATION` - Localização aproximada
- `ACCESS_BACKGROUND_LOCATION` - Localização em background
- `INTERNET` - Para geocoding
- `ACCESS_NETWORK_STATE` - Verificar conectividade

## 📊 Dados Coletados

### **Informações de Localização**
```dart
{
  'latitude': double,
  'longitude': double,
  'accuracy': double,
  'altitude': double,
  'speed': double,
  'heading': double,
  'timestamp': DateTime,
  'address': String,
  'city': String,
  'state': String,
  'country': String,
  'postalCode': String,
}
```

## 🔄 Métodos Disponíveis

### **LocationService**
- `requestLocationPermission()` - Solicitar permissões
- `getCurrentLocation()` - Obter localização atual
- `getApproximateLocation()` - Localização rápida
- `getAddressFromCoordinates()` - Converter coordenadas
- `getFullLocation()` - Localização completa
- `calculateDistance()` - Calcular distâncias
- `isWithinRadius()` - Verificar área
- `getLocationStream()` - Monitorar mudanças

### **LocationProvider**
- `initializeLocation()` - Inicializar localização
- `getCurrentLocation()` - Obter localização
- `getApproximateLocation()` - Localização rápida
- `getFormattedAddress()` - Endereço formatado
- `getCurrentCity()` - Cidade atual
- `getCurrentState()` - Estado atual
- `isInCity()` - Verificar cidade
- `isInState()` - Verificar estado
- `calculateDistanceTo()` - Calcular distância
- `isWithinRadius()` - Verificar área

## 🎨 Interface do Usuário

### **Header da Tela Principal**
- Ícone de localização
- Endereço atual ou status
- Indicador de loading
- Botão de atualizar (quando disponível)

### **Drawer**
- Seção "Localização"
- Endereço atual
- Clique para ver detalhes ou atualizar

## 🚀 Casos de Uso

### **1. Entrega Local**
- Verificar se cliente está na área de entrega
- Calcular distância para frete
- Mostrar tempo estimado de entrega

### **2. Produtos por Região**
- Filtrar produtos disponíveis na região
- Mostrar ofertas locais
- Sugerir produtos populares da área

### **3. Lojas Próximas**
- Encontrar lojas físicas próximas
- Mostrar horários de funcionamento
- Calcular rota até a loja

### **4. Promoções Geográficas**
- Ofertas específicas por região
- Cupons de desconto locais
- Eventos próximos

## 🔒 Privacidade e Segurança

### **Dados Coletados**
- Apenas localização atual (não histórico)
- Endereço aproximado (não endereço exato)
- Dados não são compartilhados com terceiros

### **Permissões**
- Solicita permissão de forma transparente
- Explica por que a localização é necessária
- Permite negar sem afetar funcionalidade básica

## 🛠️ Configuração

### **Android Manifest**
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### **Provider Setup**
```dart
ChangeNotifierProvider<LocationProvider>(
  create: (_) => LocationProvider(),
),
```

## 📈 Próximos Passos

### **Funcionalidades Futuras**
- [ ] Histórico de localizações
- [ ] Configuração de endereços favoritos
- [ ] Notificações baseadas em localização
- [ ] Integração com mapas
- [ ] Roteamento para entrega
- [ ] Análise de padrões de localização

### **Melhorias**
- [ ] Cache de localização
- [ ] Modo offline
- [ ] Precisão configurável
- [ ] Economia de bateria
- [ ] Backup de endereços

## 🧪 Testando

### **Comandos de Teste**
```bash
# Testar localização
flutter run

# Verificar permissões
adb shell dumpsys location

# Simular localização (Android)
adb shell geo fix -23.5505 -46.6333
```

### **Cenários de Teste**
1. **Primeira execução**: Solicita permissão
2. **Permissão negada**: Mostra mensagem de erro
3. **GPS desabilitado**: Solicita ativar
4. **Sem internet**: Funciona com coordenadas
5. **Mudança de localização**: Atualiza automaticamente

A funcionalidade de localização está completamente implementada e pronta para uso! 🎉
