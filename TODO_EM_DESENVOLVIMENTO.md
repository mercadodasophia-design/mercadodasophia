# 📋 TODO - FUNCIONALIDADES EM DESENVOLVIMENTO
## 🎯 Mercado da Sophia - Plano de Implementação

---

## 🚀 **0. FEED DIRETO ALIEXPRESS - LOJA PRINCIPAL**

### **Status**: 🔄 Em Desenvolvimento
### **Prioridade**: 🔴 CRÍTICA
### **Estimativa**: 2-3 dias

### **Objetivo**
Implementar feed direto do AliExpress na loja principal para exibir produtos sempre atualizados e relevantes.

### **Tarefas**

#### **0.1 Backend (Python API)**
- [ ] **Criar endpoint `/api/aliexpress/feeds/list`**
  - [ ] Implementar função `get_available_feeds()`
  - [ ] Integrar com API `aliexpress.ds.feed.name.list.get`
  - [ ] Cache de feeds disponíveis (24h)

- [ ] **Criar endpoint `/api/aliexpress/feeds/{feed_name}/products`**
  - [ ] Implementar função `get_feed_products(feed_name, page=1, page_size=20)`
  - [ ] Integrar com API `aliexpress.ds.feed.items.get`
  - [ ] Paginação automática
  - [ ] Cache de produtos (1h)

- [ ] **Estrutura de resposta - Lista de Feeds**
  ```json
  {
    "success": true,
    "feeds": [
      {
        "feed_name": "top_selling_products",
        "feed_id": "12345",
        "display_name": "Mais Vendidos",
        "description": "Produtos mais populares",
        "product_count": 1000
      },
      {
        "feed_name": "new_arrivals",
        "feed_id": "12346", 
        "display_name": "Novidades",
        "description": "Produtos recém-chegados",
        "product_count": 500
      }
    ]
  }
  ```

- [ ] **Estrutura de resposta - Produtos do Feed**
  ```json
  {
    "success": true,
    "feed_name": "top_selling_products",
    "products": [
      {
        "item_id": "1005001234567890",
        "product_title": "Nome do Produto",
        "product_main_image_url": "https://...",
        "product_price": "99.90",
        "product_rating": "4.5",
        "product_review_count": 150,
        "product_sales": 500
      }
    ],
    "pagination": {
      "page_no": 1,
      "page_size": 20,
      "total_count": 1000,
      "has_next": true
    }
  }
  ```

#### **0.2 Frontend (Flutter)**
- [ ] **Atualizar `aliexpress_service.dart`**
  - [ ] Adicionar método `getAvailableFeeds()`
  - [ ] Adicionar método `getFeedProducts(String feedName, {int page = 1})`
  - [ ] Tratamento de loading e erros
  - [ ] Cache local de feeds

- [ ] **Atualizar `products_screen.dart`**
  - [ ] Carregar feeds disponíveis ao iniciar
  - [ ] Exibir produtos do feed principal
  - [ ] Implementar pull-to-refresh
  - [ ] Paginação infinita

- [ ] **Criar widgets especializados**
  - [ ] `FeedSelectorWidget` - Seleção de feeds
  - [ ] `FeedProductsGrid` - Grid de produtos do feed
  - [ ] `FeedBannerWidget` - Banner do feed atual

### **Dependências**
- ✅ API AliExpress configurada
- ✅ Autenticação AliExpress funcionando
- ✅ Estrutura de produtos existente

### **Testes**
- [ ] Teste de listagem de feeds
- [ ] Teste de carregamento de produtos
- [ ] Teste de paginação
- [ ] Teste de cache

---

## 🔄 **1. DETALHES COMPLETOS - API aliexpress.ds.product.get**

### **Status**: 🔄 Em Desenvolvimento
### **Prioridade**: 🔴 ALTA
### **Estimativa**: 3-5 dias

### **Objetivo**
Implementar a API `aliexpress.ds.product.get` para obter informações completas de produtos individuais do AliExpress.

### **Tarefas**

#### **1.1 Backend (Python API)**
- [ ] **Criar endpoint `/api/aliexpress/product/{itemId}`**
  - [ ] Implementar função `get_product_details(itemId)`
  - [ ] Configurar autenticação AliExpress
  - [ ] Tratamento de erros e timeouts
  - [ ] Cache de resultados (Redis/Memory)

- [ ] **Estrutura de resposta**
  ```json
  {
    "success": true,
    "product": {
      "itemId": "1005001234567890",
      "title": "Nome do Produto",
      "description": "Descrição HTML completa",
      "images": ["url1", "url2", "url3"],
      "variations": [
        {
          "skuId": "sku123",
          "color": "Vermelho",
          "size": "M",
          "price": 99.90,
          "stock": 15,
          "image": "url_variation"
        }
      ],
      "specifications": {...},
      "attributes": {...},
      "videos": ["url_video1"],
      "reviews": {...}
    }
  }
  ```

#### **1.2 Frontend (Flutter)**
- [ ] **Atualizar `aliexpress_service.dart`**
  - [ ] Adicionar método `getProductDetails(String itemId)`
  - [ ] Integrar com novo endpoint
  - [ ] Tratamento de loading e erros

- [ ] **Atualizar `product_detail_page.dart`**
  - [ ] Carregar detalhes completos do AliExpress
  - [ ] Exibir galeria de imagens
  - [ ] Mostrar variações disponíveis
  - [ ] Exibir especificações técnicas

- [ ] **Criar widgets especializados**
  - [ ] `ProductGalleryWidget` - Galeria de imagens
  - [ ] `ProductVariationsWidget` - Seleção de variações
  - [ ] `ProductSpecificationsWidget` - Especificações
  - [ ] `ProductReviewsWidget` - Avaliações

### **Dependências**
- ✅ API AliExpress configurada
- ✅ Autenticação AliExpress funcionando
- ✅ Estrutura de produtos existente

### **Testes**
- [ ] Teste unitário da API
- [ ] Teste de integração
- [ ] Teste de performance
- [ ] Teste de fallback (quando API falha)

---

## 🚚 **2. CÁLCULO DE FRETE - API aliexpress.logistics.buyer.freight.calculate**

### **Status**: 🔄 Em Desenvolvimento
### **Prioridade**: 🔴 ALTA
### **Estimativa**: 4-6 dias

### **Objetivo**
Implementar cálculo preciso de frete para produtos do AliExpress com base na localização do usuário.

### **Tarefas**

#### **2.1 Backend (Python API)**
- [ ] **Criar endpoint `/api/aliexpress/freight/calculate`**
  - [ ] Implementar função `calculate_freight(itemId, destination)`
  - [ ] Integrar com API `aliexpress.logistics.buyer.freight.calculate`
  - [ ] Suporte a múltiplos métodos de envio
  - [ ] Cache de cálculos de frete

- [ ] **Estrutura de resposta**
  ```json
  {
    "success": true,
    "freight_options": [
      {
        "method": "AliExpress Standard Shipping",
        "cost": 15.90,
        "currency": "USD",
        "estimated_days": "15-25",
        "tracking": true,
        "insurance": true
      },
      {
        "method": "DHL Express",
        "cost": 45.90,
        "currency": "USD", 
        "estimated_days": "3-7",
        "tracking": true,
        "insurance": true
      }
    ]
  }
  ```

#### **2.2 Frontend (Flutter)**
- [ ] **Atualizar `shipping_service.dart`**
  - [ ] Adicionar método `calculateAliExpressFreight()`
  - [ ] Integrar com novo endpoint
  - [ ] Conversão de moedas (USD → BRL)

- [ ] **Atualizar `checkout_screen.dart`**
  - [ ] Exibir opções de frete do AliExpress
  - [ ] Seleção de método de envio
  - [ ] Cálculo de total com frete
  - [ ] Estimativa de entrega

- [ ] **Criar widgets**
  - [ ] `FreightOptionsWidget` - Lista de opções
  - [ ] `FreightCalculatorWidget` - Calculadora
  - [ ] `DeliveryEstimateWidget` - Estimativa

### **Dependências**
- ✅ API AliExpress configurada
- ✅ Localização do usuário implementada
- ✅ Conversão de moedas

### **Testes**
- [ ] Teste com diferentes localizações
- [ ] Teste de conversão de moedas
- [ ] Teste de cache de frete
- [ ] Teste de fallback

---

## 📦 **3. SINCRONIZAÇÃO - ESTOQUE EM TEMPO REAL**

### **Status**: 🔄 Em Desenvolvimento
### **Prioridade**: 🟡 MÉDIA
### **Estimativa**: 5-7 dias

### **Objetivo**
Implementar sincronização automática de estoque entre AliExpress e sistema local.

### **Tarefas**

#### **3.1 Backend (Python API)**
- [ ] **Criar serviço de sincronização**
  - [ ] `sync_service.py` - Serviço principal
  - [ ] `stock_sync.py` - Sincronização de estoque
  - [ ] `price_sync.py` - Sincronização de preços

- [ ] **Endpoints de sincronização**
  - [ ] `POST /api/sync/stock/{productId}` - Sincronizar estoque
  - [ ] `POST /api/sync/price/{productId}` - Sincronizar preços
  - [ ] `GET /api/sync/status` - Status da sincronização
  - [ ] `POST /api/sync/bulk` - Sincronização em lote

- [ ] **Sistema de agendamento**
  - [ ] Cron jobs para sincronização automática
  - [ ] Configuração de frequência
  - [ ] Logs de sincronização

#### **3.2 Frontend (Flutter)**
- [ ] **Atualizar `sync_service.dart`**
  - [ ] Método `syncProductStock(String productId)`
  - [ ] Método `syncProductPrice(String productId)`
  - [ ] Método `getSyncStatus()`
  - [ ] Notificações de sincronização

- [ ] **Atualizar `admin_dashboard_screen.dart`**
  - [ ] Widget de status de sincronização
  - [ ] Botões de sincronização manual
  - [ ] Logs de sincronização
  - [ ] Configurações de frequência

- [ ] **Criar widgets**
  - [ ] `SyncStatusWidget` - Status da sincronização
  - [ ] `SyncLogsWidget` - Logs de sincronização
  - [ ] `SyncSettingsWidget` - Configurações

### **Dependências**
- ✅ API AliExpress funcionando
- ✅ Sistema de produtos implementado
- ✅ Firebase configurado

### **Testes**
- [ ] Teste de sincronização individual
- [ ] Teste de sincronização em lote
- [ ] Teste de agendamento
- [ ] Teste de performance

---

## 💳 **4. PAGAMENTOS - INTEGRAÇÃO MERCADO PAGO COMPLETA**

### **Status**: 🔄 Em Desenvolvimento
### **Prioridade**: 🔴 ALTA
### **Estimativa**: 4-6 dias

### **Objetivo**
Completar a integração com Mercado Pago para processamento de pagamentos.

### **Tarefas**

#### **4.1 Backend (Node.js API)**
- [ ] **Completar endpoints de pagamento**
  - [ ] `POST /api/payment/process` - Processar pagamento
  - [ ] `POST /api/payment/webhook` - Webhook do Mercado Pago
  - [ ] `GET /api/payment/status/{paymentId}` - Status do pagamento
  - [ ] `POST /api/payment/refund` - Reembolso

- [ ] **Implementar webhooks**
  - [ ] Processamento de notificações
  - [ ] Atualização de status de pedidos
  - [ ] Logs de transações
  - [ ] Tratamento de erros

- [ ] **Sistema de reembolso**
  - [ ] Reembolso parcial
  - [ ] Reembolso total
  - [ ] Logs de reembolso

#### **4.2 Frontend (Flutter)**
- [ ] **Atualizar `payment_service.dart`**
  - [ ] Método `processPayment(Order order)`
  - [ ] Método `getPaymentStatus(String paymentId)`
  - [ ] Método `requestRefund(String paymentId)`
  - [ ] Tratamento de webhooks

- [ ] **Atualizar `checkout_screen.dart`**
  - [ ] Integração completa com Mercado Pago
  - [ ] Seleção de método de pagamento
  - [ ] Processamento de pagamento
  - [ ] Confirmação de pagamento

- [ ] **Criar widgets**
  - [ ] `PaymentMethodsWidget` - Métodos de pagamento
  - [ ] `PaymentStatusWidget` - Status do pagamento
  - [ ] `RefundRequestWidget` - Solicitar reembolso

### **Dependências**
- ✅ Mercado Pago configurado
- ✅ Access token funcionando
- ✅ Sistema de pedidos implementado

### **Testes**
- [ ] Teste de pagamento em sandbox
- [ ] Teste de webhooks
- [ ] Teste de reembolso
- [ ] Teste de diferentes métodos de pagamento

---

## 🔔 **5. WEBHOOKS - NOTIFICAÇÕES DE MUDANÇAS**

### **Status**: 🔄 Em Desenvolvimento
### **Prioridade**: 🟡 MÉDIA
### **Estimativa**: 3-4 dias

### **Objetivo**
Implementar sistema de webhooks para notificações em tempo real de mudanças.

### **Tarefas**

#### **5.1 Backend (Node.js API)**
- [ ] **Sistema de webhooks**
  - [ ] `webhook_service.js` - Serviço principal
  - [ ] `notification_service.js` - Notificações
  - [ ] `event_logger.js` - Logs de eventos

- [ ] **Endpoints de webhooks**
  - [ ] `POST /api/webhooks/stock` - Mudanças de estoque
  - [ ] `POST /api/webhooks/price` - Mudanças de preço
  - [ ] `POST /api/webhooks/order` - Status de pedidos
  - [ ] `POST /api/webhooks/payment` - Status de pagamentos

- [ ] **Sistema de notificações**
  - [ ] Notificações push (Firebase)
  - [ ] Notificações por email
  - [ ] Notificações in-app
  - [ ] Configuração de preferências

#### **5.2 Frontend (Flutter)**
- [ ] **Atualizar `notification_service.dart`**
  - [ ] Receber notificações push
  - [ ] Processar notificações in-app
  - [ ] Configurar preferências
  - [ ] Histórico de notificações

- [ ] **Atualizar telas administrativas**
  - [ ] `admin_dashboard_screen.dart` - Notificações em tempo real
  - [ ] `admin_orders_screen.dart` - Atualizações de pedidos
  - [ ] `admin_products_screen.dart` - Mudanças de produtos

- [ ] **Criar widgets**
  - [ ] `NotificationCenterWidget` - Centro de notificações
  - [ ] `NotificationSettingsWidget` - Configurações
  - [ ] `NotificationHistoryWidget` - Histórico

### **Dependências**
- ✅ Firebase configurado
- ✅ Sistema de usuários implementado
- ✅ Sistema de pedidos funcionando

### **Testes**
- [ ] Teste de notificações push
- [ ] Teste de webhooks
- [ ] Teste de notificações in-app
- [ ] Teste de configurações

---

## 📊 **6. OTIMIZAÇÕES E MELHORIAS**

### **Status**: 🔄 Planejado
### **Prioridade**: 🟢 BAIXA
### **Estimativa**: 7-10 dias

### **Tarefas**

#### **6.1 Performance**
- [ ] **Cache de dados**
  - [ ] Cache de produtos
  - [ ] Cache de imagens
  - [ ] Cache de frete
  - [ ] Cache de categorias

- [ ] **Otimização de consultas**
  - [ ] Índices no Firestore
  - [ ] Paginação de resultados
  - [ ] Lazy loading
  - [ ] Compressão de dados

#### **6.2 UX/UI**
- [ ] **Animações**
  - [ ] Transições suaves
  - [ ] Loading states
  - [ ] Feedback visual
  - [ ] Micro-interações

- [ ] **Acessibilidade**
  - [ ] Suporte a screen readers
  - [ ] Contraste adequado
  - [ ] Navegação por teclado
  - [ ] Tamanhos de fonte ajustáveis

#### **6.3 Segurança**
- [ ] **Validação de dados**
  - [ ] Validação no frontend
  - [ ] Validação no backend
  - [ ] Sanitização de inputs
  - [ ] Proteção contra XSS

- [ ] **Autenticação**
  - [ ] Refresh tokens
  - [ ] Sessões seguras
  - [ ] Rate limiting
  - [ ] Logs de segurança

---

## 🧪 **7. TESTES E QUALIDADE**

### **Status**: 🔄 Planejado
### **Prioridade**: 🟡 MÉDIA
### **Estimativa**: 5-7 dias

### **Tarefas**

#### **7.1 Testes Unitários**
- [ ] **Services**
  - [ ] `auth_service_test.dart`
  - [ ] `product_service_test.dart`
  - [ ] `payment_service_test.dart`
  - [ ] `shipping_service_test.dart`

- [ ] **Models**
  - [ ] `product_test.dart`
  - [ ] `order_test.dart`
  - [ ] `user_test.dart`

#### **7.2 Testes de Integração**
- [ ] **APIs**
  - [ ] Testes de endpoints
  - [ ] Testes de autenticação
  - [ ] Testes de validação
  - [ ] Testes de performance

- [ ] **Firebase**
  - [ ] Testes de Firestore
  - [ ] Testes de Storage
  - [ ] Testes de Auth

#### **7.3 Testes E2E**
- [ ] **Fluxos principais**
  - [ ] Cadastro e login
  - [ ] Busca e compra de produtos
  - [ ] Processamento de pagamento
  - [ ] Gestão administrativa

---

## 🚀 **8. DEPLOY E PRODUÇÃO**

### **Status**: 🔄 Planejado
### **Prioridade**: 🔴 ALTA
### **Estimativa**: 3-5 dias

### **Tarefas**

#### **8.1 Configuração de Produção**
- [ ] **Variáveis de ambiente**
  - [ ] Configuração de produção
  - [ ] Secrets management
  - [ ] Configuração de domínios
  - [ ] SSL certificates

- [ ] **Monitoramento**
  - [ ] Logs estruturados
  - [ ] Métricas de performance
  - [ ] Alertas automáticos
  - [ ] Health checks

#### **8.2 CI/CD**
- [ ] **Pipeline de deploy**
  - [ ] Build automatizado
  - [ ] Testes automatizados
  - [ ] Deploy automatizado
  - [ ] Rollback automático

- [ ] **Ambientes**
  - [ ] Desenvolvimento
  - [ ] Staging
  - [ ] Produção

---

## 📅 **CRONOGRAMA SUGERIDO**

### **Semana 1**
- [ ] Implementar API `aliexpress.ds.product.get`
- [ ] Implementar cálculo de frete
- [ ] Testes básicos

### **Semana 2**
- [ ] Completar integração Mercado Pago
- [ ] Implementar sincronização de estoque
- [ ] Testes de integração

### **Semana 3**
- [ ] Implementar webhooks
- [ ] Otimizações de performance
- [ ] Testes E2E

### **Semana 4**
- [ ] Configuração de produção
- [ ] Deploy e monitoramento
- [ ] Documentação final

---

## 🎯 **CRITÉRIOS DE ACEITAÇÃO**

### **Funcionalidades Críticas**
- [ ] API de detalhes do produto funcionando
- [ ] Cálculo de frete preciso
- [ ] Pagamentos processando corretamente
- [ ] Sincronização de estoque automática

### **Qualidade**
- [ ] Cobertura de testes > 80%
- [ ] Performance otimizada
- [ ] Segurança validada
- [ ] Documentação completa

### **Produção**
- [ ] Deploy automatizado
- [ ] Monitoramento ativo
- [ ] Backup automático
- [ ] Suporte 24/7

---

## 📞 **CONTATOS E SUPORTE**

### **Desenvolvimento**
- **Tech Lead**: [Nome do Tech Lead]
- **Backend**: [Nome do Backend Dev]
- **Frontend**: [Nome do Frontend Dev]
- **QA**: [Nome do QA]

### **Documentação**
- **API Docs**: [Link para documentação]
- **Figma**: [Link para designs]
- **Jira**: [Link para tickets]
- **GitHub**: [Link para repositório]

---

**Última atualização**: [Data]
**Próxima revisão**: [Data + 1 semana]
**Status geral**: 🔄 Em desenvolvimento (80% completo)
