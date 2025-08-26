# API de Cálculo de Frete - Correios

## Visão Geral

O sistema utiliza a API pública dos Correios para calcular o valor do frete baseado nas dimensões e peso dos produtos. O prazo de entrega é fixo da loja (12 a 28 dias úteis).

## Endpoint Utilizado

```
GET https://ws.correios.com.br/calculador/CalcPrecoPrazo.asmx/CalcPrecoPrazo
```

## Parâmetros da API

| Parâmetro | Descrição | Valor |
|-----------|-----------|-------|
| `nCdEmpresa` | Contrato (se não tiver, deixar vazio) | `""` |
| `sDsSenha` | Senha (se não tiver, deixar vazio) | `""` |
| `nCdServico` | Código do serviço | `04510` (PAC) |
| `sCepOrigem` | CEP de origem | `01001000` (São Paulo - Centro) |
| `sCepDestino` | CEP de destino | CEP do cliente |
| `nVlPeso` | Peso em kg | Peso total dos produtos |
| `nCdFormato` | Formato da embalagem | `1` (caixa/pacote) |
| `nVlComprimento` | Comprimento em cm | Maior comprimento |
| `nVlAltura` | Altura em cm | Maior altura |
| `nVlLargura` | Largura em cm | Maior largura |
| `nVlDiametro` | Diâmetro em cm | Maior diâmetro (ou 0) |
| `sCdMaoPropria` | Mão própria | `N` |
| `nVlValorDeclarado` | Valor declarado | `0` |
| `sCdAvisoRecebimento` | Aviso de recebimento | `N` |

## Códigos dos Serviços

- **PAC**: `04510` (mais barato, usado por padrão)
- **SEDEX**: `04014` (mais rápido, não usado atualmente)

## Exemplo de Requisição

```
https://ws.correios.com.br/calculador/CalcPrecoPrazo.asmx/CalcPrecoPrazo?
nCdEmpresa=&sDsSenha=&nCdServico=04510&sCepOrigem=01001000&sCepDestino=20040030&
nVlPeso=2&nCdFormato=1&nVlComprimento=40&nVlAltura=20&nVlLargura=30&nVlDiametro=0&
sCdMaoPropria=N&nVlValorDeclarado=0&sCdAvisoRecebimento=N
```

## Resposta da API

A API retorna um XML com os dados do frete:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Servicos>
  <cServico>
    <Codigo>04510</Codigo>
    <Valor>15,50</Valor>
    <PrazoEntrega>15</PrazoEntrega>
    <ValorSemAdicionais>15,50</ValorSemAdicionais>
    <ValorMaoPropria>0,00</ValorMaoPropria>
    <ValorAvisoRecebimento>0,00</ValorAvisoRecebimento>
    <ValorDeclarado>0,00</ValorDeclarado>
    <EntregaDomiciliar>S</EntregaDomiciliar>
    <EntregaSabado>S</EntregaSabado>
    <Erro>0</Erro>
    <MsgErro></MsgErro>
  </cServico>
</Servicos>
```

## Implementação no Sistema

### FreightService

O serviço `FreightService` encapsula toda a lógica de cálculo de frete:

```dart
class FreightService {
  // Calcula frete para um produto
  static Future<double> calculateFreight({
    required String destinationCep,
    required double weight,
    required double length,
    required double height,
    required double width,
    double? diameter,
    String? formato,
  }) async { ... }

  // Calcula frete para múltiplos produtos
  static Future<double> calculateMultipleProductsFreight({
    required String destinationCep,
    required List<Map<String, dynamic>> products,
  }) async { ... }
}
```

### Campos de Produto

Cada produto deve ter os seguintes campos para cálculo de frete:

- `weight`: Peso em kg
- `length`: Comprimento em cm
- `height`: Altura em cm
- `width`: Largura em cm
- `diameter`: Diâmetro em cm (opcional)
- `formato`: 'caixa' ou 'pacote'

### Fallback

Se o produto não tiver dados suficientes para cálculo de frete, o sistema usa:
- **Frete padrão**: R$ 20,00
- **Prazo fixo**: 12 a 28 dias úteis

## Fluxo de Cálculo

1. **Verificar dados**: Se produto tem peso e dimensões
2. **Calcular frete**: Usar API dos Correios
3. **Fallback**: Se erro, usar frete padrão
4. **Frete grátis**: Se produto marcado como "frete grátis"

## Tratamento de Erros

- **CEP inválido**: Usar frete padrão
- **Dados insuficientes**: Usar frete padrão
- **Erro na API**: Usar frete padrão
- **Timeout**: Usar frete padrão

## Configurações

- **CEP de origem**: 01001-000 (São Paulo - Centro)
- **Serviço padrão**: PAC (04510)
- **Frete padrão**: R$ 20,00
- **Prazo fixo**: 12 a 28 dias úteis
