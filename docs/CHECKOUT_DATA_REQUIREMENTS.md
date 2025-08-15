# 📋 Dados Necessários para Checkout - Mercado da Sophia

## 🎯 Objetivo
Este documento lista todos os dados que devem ser coletados durante o processo de checkout para garantir uma experiência completa e conformidade legal.

---

## 📝 1. DADOS PESSOAIS

### Obrigatórios
- **Nome completo** (para emissão da fatura e envio)
- **CPF ou CNPJ** (obrigatório no Brasil para emissão de nota fiscal e despacho aduaneiro)
- **E-mail** (para enviar confirmação e rastreamento)
- **Telefone** (preferencialmente celular para contato rápido ou entrega)

### Validações
- CPF/CNPJ deve ser válido
- E-mail deve ter formato válido
- Telefone deve ter DDD + número

---

## 🏠 2. ENDEREÇO DE ENTREGA

### Obrigatórios
- **CEP** (para cálculo de frete)
- **Rua / Logradouro**
- **Número**
- **Bairro**
- **Cidade**
- **Estado**
- **País** (se for vendas internacionais)

### Opcionais
- **Complemento** (apartamento, bloco, etc.)

### Importante
💡 **Para dropshipping**: É essencial garantir que o endereço esteja completo e padronizado, pois o AliExpress usa esses dados para o envio direto.

---

## 🚚 3. FORMA DE ENVIO

### Dados a coletar
- **Tipo de frete escolhido** (ex: padrão, expresso)
- **Observações do cliente para entrega** (opcional)
- **Prazo estimado de entrega**
- **Valor do frete**

---

## 📦 4. DADOS DO PEDIDO

### Informações do produto
- **Lista de produtos** (nome, variação, quantidade)
- **Código/SKU de cada produto**
- **Preço unitário**
- **Valor do frete**
- **Valor total do pedido**
- **Número do pedido** (gerado pelo sistema)

### Dados técnicos
- **ID do produto no Firebase**
- **ID da variação selecionada**
- **Quantidade por item**
- **Subtotal por item**
- **Descontos aplicados**

---

## 💳 5. FORMA DE PAGAMENTO

### Métodos disponíveis
- **Pix** (instantâneo)
- **Cartão de crédito**
- **Cartão de débito**
- **Boleto bancário**
- **PayPal** (se aplicável)

### Dados do cartão (se aplicável)
- **Nome no cartão**
- **Número do cartão**
- **Data de validade**
- **CVV**
- **Parcelas** (se aplicável)

### Dados específicos por método
- **Pix**: confirmação do pagamento, QR Code
- **Boleto**: status e data de vencimento
- **Cartão**: tokenização para segurança

---

## ⚖️ 6. CONFIRMAÇÕES LEGAIS

### Aceites obrigatórios
- ✅ **Termos de Uso e Política de Privacidade**
- ✅ **Política de Trocas e Devoluções**
- ✅ **Concordância com prazo de entrega estimado**

### Informações adicionais
- **Data e hora do pedido**
- **IP do cliente** (para segurança)
- **User Agent** (navegador/dispositivo)

---

## 🎁 7. DADOS EXTRAS (Opcionais)

### Para melhor experiência
- **Cadastro de senha** (para criar conta e facilitar compras futuras)
- **Preferência de contato** (WhatsApp, e-mail, telefone)
- **Cupom de desconto ou código promocional**
- **Observações especiais do pedido**

### Marketing (opt-in)
- **Aceite para receber ofertas por e-mail**
- **Aceite para receber ofertas por WhatsApp**

---

## 🔄 8. FLUXO DE DADOS

### Etapas do checkout
1. **Carrinho** → Validação de produtos e estoque
2. **Dados pessoais** → Validação de CPF/CNPJ e e-mail
3. **Endereço** → Validação de CEP e cálculo de frete
4. **Pagamento** → Processamento seguro
5. **Confirmação** → Geração de pedido e envio de e-mail

### Validações em cada etapa
- **Etapa 1**: Produtos disponíveis, preços atualizados
- **Etapa 2**: CPF válido, e-mail válido, telefone válido
- **Etapa 3**: CEP válido, endereço completo
- **Etapa 4**: Dados de pagamento válidos
- **Etapa 5**: Aceite dos termos obrigatórios

---

## 📊 9. ARMAZENAMENTO

### Firebase Collections
- **orders**: Pedidos completos
- **customers**: Dados dos clientes
- **payments**: Informações de pagamento
- **shipping**: Dados de entrega

### Segurança
- **Dados sensíveis**: Criptografados
- **CPF/CNPJ**: Mascarado na interface
- **Cartão**: Apenas token armazenado
- **Logs**: Para auditoria

---

## 🚀 10. PRÓXIMOS PASSOS

### Desenvolvimento
- [ ] Criar modelo de dados (Order, Customer, Payment)
- [ ] Implementar validações de formulário
- [ ] Integrar com gateway de pagamento
- [ ] Criar sistema de cálculo de frete
- [ ] Implementar geração de pedidos
- [ ] Criar sistema de notificações

### Testes
- [ ] Testes de validação de dados
- [ ] Testes de pagamento
- [ ] Testes de cálculo de frete
- [ ] Testes de geração de pedidos

---

## 📞 11. CONTATO

**Responsável**: Equipe de Desenvolvimento  
**Data de criação**: 2024  
**Última atualização**: 2024  
**Versão**: 1.0

---

*Este documento deve ser atualizado conforme o desenvolvimento do sistema avança.*







