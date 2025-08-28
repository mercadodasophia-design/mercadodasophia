# 📋 TO-DO: Implementação Feeds no Painel Admin

## ✅ **CONCLUÍDO - Backend API**
- [x] Criar endpoint `/api/admin/feeds/list` - Lista feeds com chips
- [x] Criar endpoint `/api/admin/feeds/{feed_name}/products` - Produtos paginados
- [x] Formatar dados para o painel admin (JSON estruturado)
- [x] Implementar paginação (20 produtos por página)
- [x] Testar endpoints funcionando ✅

## 🚀 **PRÓXIMOS PASSOS - Frontend Painel Admin**

### **1. Tela de Feeds (Feed Management)**
- [x] Criar nova tela `FeedsScreen` no painel admin
- [x] Adicionar item "Feeds" no menu drawer do admin
- [x] Implementar chips para seleção de feeds
- [x] Mostrar contador de produtos por feed
- [ ] Adicionar filtros (categoria, país, etc.)

### **2. Lista de Produtos do Feed**
- [x] Implementar grid de produtos (20 por página)
- [x] Card de produto com:
  - [x] Imagem principal
  - [x] Título do produto
  - [x] Preço (R$)
  - [x] Avaliação (estrelas)
  - [x] Número de vendas
  - [x] Botão "Importar"
- [x] Paginação com "Carregar Mais"
- [x] Loading states e error handling

### **3. Funcionalidade de Importação**
- [ ] Botão "Importar" em cada produto
- [ ] Modal de confirmação de importação
- [ ] Salvar produto no Firestore (coleção `products`)
- [ ] Aplicar margem de lucro configurada
- [ ] Atualizar status `is_imported: true`
- [ ] Feedback visual (toast/snackbar)

### **4. Melhorias de UX**
- [ ] Busca/filtro de produtos
- [ ] Ordenação (preço, vendas, avaliação)
- [ ] Seleção múltipla de produtos
- [ ] Importação em lote
- [ ] Progress bar para importações grandes

### **5. Integração com Sistema Existente**
- [ ] Conectar com `ProfitMarginProvider`
- [ ] Aplicar margens de lucro nos preços
- [ ] Integrar com categorias existentes
- [ ] Verificar duplicatas antes de importar
- [ ] Logs de importação

### **6. Melhorias de Performance**
- [x] Aumentar timeout para 90 segundos
- [x] Reduzir pageSize para 10 produtos
- [x] Implementar retry automático
- [x] Melhorar loading states
- [ ] Implementar cache local
- [ ] Otimizar requisições em lote

## 📊 **Estrutura de Dados**

### **Feed Object:**
```json
{
  "id": "91",
  "name": "DS_Brazil_topsellers",
  "display_name": "Mais Vendidos Brasil",
  "description": "Produtos mais vendidos no Brasil",
  "product_count": 13060,
  "category": "aliexpress",
  "is_active": true
}
```

### **Product Object:**
```json
{
  "id": "1005007307865747",
  "title": "Pastilha de freio a disco...",
  "main_image": "https://...",
  "images": ["https://...", "https://..."],
  "price": 25.50,
  "currency": "BRL",
  "original_price": 30.00,
  "discount": 15.0,
  "rating": 4.5,
  "orders": 1250,
  "store_name": "Loja XYZ",
  "feed_name": "DS_Brazil_topsellers",
  "is_imported": false
}
```

## 🔧 **Endpoints Disponíveis**

### **Listar Feeds:**
```
GET /api/admin/feeds/list
```

### **Produtos de um Feed:**
```
GET /api/admin/feeds/{feed_name}/products?page=1&page_size=20
```

## 📝 **Notas Importantes**

- ✅ Backend API funcionando perfeitamente
- ✅ Paginação implementada (10 produtos por página para melhor performance)
- ✅ Dados formatados para o painel admin
- ✅ 138 feeds disponíveis para teste
- ✅ Timeout aumentado para 90 segundos
- ✅ Retry automático em caso de timeout
- ✅ Loading states melhorados
- 🔄 Próximo: Implementar funcionalidade de importação

## 🎯 **Prioridade**

1. **ALTA**: Criar tela de feeds com chips
2. **ALTA**: Implementar lista de produtos com paginação
3. **MÉDIA**: Funcionalidade de importação individual
4. **MÉDIA**: Melhorias de UX (busca, filtros)
5. **BAIXA**: Importação em lote e logs

---
**Status**: Backend ✅ | Frontend 🚧 | Testado: ✅
**Última atualização**: 27/08/2025
