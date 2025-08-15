# 📚 Documentação das APIs do AliExpress

## 🎯 **Objetivo**
Combinar múltiplas APIs para mostrar o máximo de informações dos produtos:
- Busca básica (text search)
- Detalhes completos do produto
- Informações de frete
- Cálculo de envio

## 📋 **APIs Disponíveis**

### 1️⃣ **aliexpress.ds.text.search** ✅ (Implementado)
**Função**: Buscar produtos por palavra-chave
**Retorna**: Lista básica de produtos
- itemId, title, preços, avaliações, imagem principal
- **Limitação**: Só informações básicas

### 2️⃣ **aliexpress.ds.product.get** 🔄 (A implementar)
**Função**: Buscar detalhes completos de UM produto específico
**Entrada**: itemId (do resultado da busca)
**Retorna**: Informações completas
- Múltiplas imagens
- Variações (cores, tamanhos)
- Descrição detalhada
- Especificações técnicas
- Atributos do produto

### 3️⃣ **aliexpress.freight.redefining.listfreighttemplate** 🔄 (A implementar)
**Função**: Calcular custos de frete
**Entrada**: itemId + país de destino
**Retorna**: 
- Custos de envio
- Tempo de entrega
- Métodos de envio disponíveis

### 4️⃣ **aliexpress.logistics.buyer.freight.calculate** 🔄 (A implementar)
**Função**: Calcular frete detalhado
**Entrada**: produto + localização
**Retorna**:
- Frete preciso
- Tempo estimado
- Opções de envio

## 🔄 **Fluxo Proposto**

```
1. Usuário busca "smartphone" 
   ↓
2. aliexpress.ds.text.search → Lista de produtos básicos
   ↓
3. Usuário clica em um produto
   ↓
4. aliexpress.ds.product.get(itemId) → Detalhes completos
   ↓
5. aliexpress.freight.calculate(itemId, "BR") → Custos de frete
   ↓
6. Exibir TUDO na tela de detalhes
```

## 📊 **Informações que Teremos**

### Da Busca (text.search):
- ✅ itemId, title, preços básicos, avaliação, imagem principal

### Dos Detalhes (product.get):
- 🔄 Galeria completa de imagens
- 🔄 Variações (cores, tamanhos, modelos)
- 🔄 Descrição HTML completa
- 🔄 Especificações técnicas
- 🔄 Atributos detalhados
- 🔄 Vídeos do produto

### Do Frete (freight.calculate):
- 🔄 Custo de envio para Brasil
- 🔄 Tempo de entrega estimado
- 🔄 Métodos de envio disponíveis
- 🔄 Rastreamento disponível

## 🛠️ **Implementação**

### Passo 1: Implementar aliexpress.ds.product.get
### Passo 2: Implementar cálculo de frete
### Passo 3: Combinar todos os dados na tela de detalhes
### Passo 4: Interface rica com todas as informações

---

**Status**: 📝 Documentando e estudando
**Próximo**: Implementar product.get para detalhes completos