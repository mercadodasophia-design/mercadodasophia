# Sistema de Tema - Mercado da Sophia

Este documento descreve o sistema de tema completo do app "Mercado da Sophia", baseado nas cores da logo.

## 🎨 Paleta de Cores

### Cores Principais
- **Primária**: `#E91E63` (Rosa vibrante da logo)
- **Secundária**: `#F48FB1` (Rosa claro)
- **Acento**: `#C2185B` (Rosa escuro)

### Cores de Fundo
- **Background**: `#FFFFFF` (Branco)
- **Surface**: `#F8F9FA` (Cinza muito claro)

### Cores de Texto
- **Primário**: `#212121` (Preto suave)
- **Secundário**: `#757575` (Cinza médio)
- **Claro**: `#BDBDBD` (Cinza claro)

### Cores Semânticas
- **Sucesso**: `#4CAF50` (Verde)
- **Aviso**: `#FF9800` (Laranja)
- **Erro**: `#F44336` (Vermelho)

## 🌈 Gradientes

### Gradiente Primário
```dart
LinearGradient(
  colors: [primaryColor, secondaryColor],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)
```

### Gradiente Secundário
```dart
LinearGradient(
  colors: [secondaryColor, Color(0xFFFCE4EC)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)
```

## 📝 Tipografia

### Família de Fonte
- **Família**: Roboto
- **Pesos**: Normal, Medium, SemiBold, Bold

### Hierarquia de Texto
- **Display Large**: 32px, Bold
- **Display Medium**: 28px, Bold
- **Display Small**: 24px, Bold
- **Headline Large**: 22px, Bold
- **Headline Medium**: 20px, SemiBold
- **Headline Small**: 18px, SemiBold
- **Title Large**: 16px, SemiBold
- **Title Medium**: 14px, Medium
- **Title Small**: 12px, Medium
- **Body Large**: 16px, Normal
- **Body Medium**: 14px, Normal
- **Body Small**: 12px, Normal

## 🎯 Componentes Tematizados

### AppBar
- **Background**: Cor primária
- **Texto**: Branco
- **Elevation**: 0
- **Center Title**: true

### Botões
- **Elevated Button**: Fundo primário, texto branco
- **Outlined Button**: Borda primária, texto primário
- **Text Button**: Texto primário

### Cards
- **Elevation**: 4
- **Border Radius**: 12px
- **Shadow**: Cor primária com opacidade 0.1

### Chips
- **Background**: Cor de superfície
- **Selected**: Cor primária
- **Border Radius**: 20px

### Inputs
- **Filled**: true
- **Background**: Cor de superfície
- **Border Radius**: 8px
- **Focused Border**: Cor primária, 2px

## 🚀 Como Usar

### 1. Importar o Tema
```dart
import 'package:mercadodasophia/theme/app_theme.dart';
```

### 2. Aplicar no MaterialApp
```dart
MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  // ...
)
```

### 3. Usar Cores
```dart
// Cores diretas
Container(
  color: AppTheme.primaryColor,
)

// Cores do tema
Container(
  color: Theme.of(context).colorScheme.primary,
)
```

### 4. Usar Tipografia
```dart
Text(
  'Título',
  style: Theme.of(context).textTheme.headlineMedium,
)
```

### 5. Usar Gradientes
```dart
Container(
  decoration: const BoxDecoration(
    gradient: AppTheme.primaryGradient,
  ),
)
```

## 📱 Exemplos de Uso

### Card de Produto
```dart
Card(
  child: Column(
    children: [
      Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: // conteúdo
      ),
      Text(
        product.name,
        style: theme.textTheme.titleLarge,
      ),
      Text(
        'R\$ ${product.price}',
        style: theme.textTheme.headlineSmall?.copyWith(
          color: AppTheme.primaryColor,
        ),
      ),
    ],
  ),
)
```

### Botão de Ação
```dart
ElevatedButton(
  onPressed: () {},
  child: const Text('Adicionar ao Carrinho'),
)
```

### Chip de Categoria
```dart
FilterChip(
  label: const Text('Laticínios'),
  selected: isSelected,
  onSelected: (value) {},
)
```

## 🎨 Personalização

### Adicionar Nova Cor
```dart
// No AppTheme
static const Color novaCor = Color(0xFF123456);
```

### Adicionar Novo Gradiente
```dart
// No AppTheme
static const LinearGradient novoGradiente = LinearGradient(
  colors: [primaryColor, novaCor],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
```

### Modificar Estilo de Componente
```dart
// No AppTheme.lightTheme
elevatedButtonTheme: ElevatedButtonThemeData(
  style: ElevatedButton.styleFrom(
    backgroundColor: novaCor,
    // outras propriedades
  ),
),
```

## 🔄 Tema Escuro

O tema escuro está preparado para implementação futura:

```dart
static ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: primaryColor,
    secondary: secondaryColor,
    // outras cores
  ),
);
```

## 📋 Checklist de Implementação

- [x] Cores principais definidas
- [x] Gradientes criados
- [x] Tipografia configurada
- [x] Componentes tematizados
- [x] AppBar personalizada
- [x] Botões estilizados
- [x] Cards configurados
- [x] Chips tematizados
- [x] Inputs estilizados
- [x] Tema escuro preparado
- [x] Documentação criada

## 🎯 Boas Práticas

1. **Sempre use o tema**: Evite cores hardcoded
2. **Use as cores semânticas**: success, warning, error
3. **Mantenha consistência**: Use sempre a mesma tipografia
4. **Teste em diferentes tamanhos**: Garanta legibilidade
5. **Documente mudanças**: Atualize este README

## 📞 Suporte

Para dúvidas sobre o tema, consulte:
- Este arquivo README
- Widget de demonstração (`ThemeDemoWidget`)
- Arquivo principal do tema (`app_theme.dart`) 