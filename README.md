# 🛒 Mercado da Sophia - API Backend

API backend para o sistema de e-commerce Mercado da Sophia, com funcionalidades de importação do AliExpress e gestão de produtos.

## 🚀 Funcionalidades

### **Importação AliExpress**
- 🔍 **Busca de produtos** no AliExpress
- 📦 **Importação individual** de produtos
- 📋 **Importação em lote** (múltiplos produtos)
- 🖼️ **Download automático** de imagens
- 💰 **Conversão de preços** (USD → BRL)
- 📊 **Estatísticas** de importação

### **Gestão de Produtos**
- ✅ **CRUD completo** de produtos
- 🏷️ **Categorização** automática
- 📈 **Controle de estoque**
- 🏷️ **Sistema de tags**
- 📸 **Upload de imagens**
- 📝 **SEO e metadados**
- 🎨 **Sistema de Variações (SKUs)**: Cores, tamanhos e preços individuais

### **Autenticação e Segurança**
- 🔐 **JWT Authentication**
- 👥 **Sistema de roles** (admin, manager, editor, viewer)
- 🛡️ **Rate limiting**
- 🔒 **Validação de dados**
- 📝 **Logs de auditoria**

## 🛠️ Tecnologias

- **Node.js** + **Express**
- **PostgreSQL** + **Sequelize**
- **Puppeteer** (web scraping)
- **JWT** (autenticação)
- **Multer** (upload de arquivos)
- **Sharp** (processamento de imagens)

## 📦 Instalação

### **Pré-requisitos**
- Node.js 16+
- PostgreSQL 12+
- Git

### **1. Clone o repositório**
```bash
git clone https://github.com/mercadodasophia/api.git
cd mercadodasophia-api
```

### **2. Instale as dependências**
```bash
npm install
```

### **3. Configure o banco de dados**
```bash
# Crie o banco PostgreSQL
createdb mercadodasophia

# Execute as migrações
npm run migrate

# Execute os seeds (dados iniciais)
npm run seed
```

### **4. Configure as variáveis de ambiente**
Crie um arquivo `.env` na raiz do projeto:

```env
# Configurações do Servidor
NODE_ENV=development
PORT=3000

# Configurações do Banco de Dados
DB_HOST=localhost
DB_PORT=5432
DB_NAME=mercadodasophia
DB_USER=postgres
DB_PASSWORD=sua_senha

# Configurações de Segurança
JWT_SECRET=sua_chave_secreta_super_segura
JWT_EXPIRES_IN=24h

# Configurações do AliExpress
ALIEXPRESS_BASE_URL=https://www.aliexpress.com
ALIEXPRESS_SEARCH_DELAY=2000
ALIEXPRESS_MAX_RETRIES=3
```

### **5. Execute a aplicação**
```bash
# Desenvolvimento
npm run dev

# Produção
npm start
```

## 📚 Endpoints da API

### **Autenticação**
```
POST /api/auth/login          # Login
POST /api/auth/register       # Registro
GET  /api/auth/verify         # Verificar token
POST /api/auth/logout         # Logout
PUT  /api/auth/change-password # Alterar senha
```

### **AliExpress**
```
GET  /api/aliexpress/search           # Buscar produtos
GET  /api/aliexpress/product/:id      # Detalhes do produto
POST /api/aliexpress/import           # Importar produto
POST /api/aliexpress/import-bulk      # Importar em lote
GET  /api/aliexpress/imported         # Listar importados
GET  /api/aliexpress/stats            # Estatísticas
```

### **Produtos**
```
GET    /api/products          # Listar produtos
GET    /api/products/:id      # Obter produto
POST   /api/products          # Criar produto
PUT    /api/products/:id      # Atualizar produto
DELETE /api/products/:id      # Deletar produto
```

### **Categorias**
```
GET    /api/categories        # Listar categorias
GET    /api/categories/:id    # Obter categoria
POST   /api/categories        # Criar categoria
PUT    /api/categories/:id    # Atualizar categoria
DELETE /api/categories/:id    # Deletar categoria
```

### **Admin**
```
GET /api/admin/dashboard      # Dashboard
GET /api/admin/stats          # Estatísticas gerais
GET /api/admin/users          # Listar usuários
```

## 🔍 Exemplos de Uso

### **Buscar produtos no AliExpress**
```bash
curl -X GET "http://localhost:3000/api/aliexpress/search?q=smartphone&limit=10" \
  -H "Authorization: Bearer seu_token_jwt"
```

### **Importar produto**
```bash
curl -X POST "http://localhost:3000/api/aliexpress/import" \
  -H "Authorization: Bearer seu_token_jwt" \
  -H "Content-Type: application/json" \
  -d '{
    "aliexpress_url": "https://www.aliexpress.com/item/123456.html",
    "category_id": "uuid-da-categoria",
    "price_override": 99.90,
    "stock_quantity": 50
  }'
```

### **Login**
```bash
curl -X POST "http://localhost:3000/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@mercadodasophia.com",
    "password": "senha123"
  }'
```

## 📊 Estrutura do Banco de Dados

### **Tabelas Principais**

#### **users**
- `id` (UUID, PK)
- `name` (VARCHAR)
- `email` (VARCHAR, UNIQUE)
- `password` (VARCHAR, HASHED)
- `role` (ENUM: admin, manager, editor, viewer)
- `is_active` (BOOLEAN)
- `created_at`, `updated_at`

#### **categories**
- `id` (UUID, PK)
- `name` (VARCHAR)
- `slug` (VARCHAR, UNIQUE)
- `description` (TEXT)
- `parent_id` (UUID, FK)
- `is_active` (BOOLEAN)
- `created_at`, `updated_at`

#### **products**
- `id` (UUID, PK)
- `name` (VARCHAR)
- `description` (TEXT)
- `price` (DECIMAL)
- `stock_quantity` (INTEGER)
- `category_id` (UUID, FK)
- `aliexpress_id` (VARCHAR, UNIQUE)
- `aliexpress_url` (TEXT)
- `status` (ENUM: draft, pending, active, inactive, deleted)
- `created_by` (UUID, FK)
- `approved_by` (UUID, FK)
- `created_at`, `updated_at`

#### **product_variations** (Sistema de SKUs)
- `id` (UUID, PK)
- `product_id` (UUID, FK)
- `color` (VARCHAR, NULLABLE)
- `size` (VARCHAR, NULLABLE)
- `price` (DECIMAL)
- `stock` (INTEGER)
- `image_url` (TEXT, NULLABLE)
- `sku` (VARCHAR, UNIQUE)
- `is_available` (BOOLEAN)
- `created_at`, `updated_at`

## 🎨 Sistema de Variações de Produtos (SKUs)

O sistema implementa um modelo completo de **Stock Keeping Units (SKUs)** que permite:

### **Tipos de Variações Suportadas**
- **Apenas Cores**: Produtos com diferentes cores (ex: capas de celular)
- **Apenas Tamanhos**: Produtos com diferentes tamanhos (ex: calçados)
- **Cores + Tamanhos**: Produtos com combinações (ex: roupas)
- **Sem Variações**: Produtos simples (ex: livros)

### **Funcionalidades**
- ✅ **Preços individuais** por variação
- ✅ **Controle de estoque** por SKU
- ✅ **Imagens específicas** por variação
- ✅ **SKUs únicos** para rastreamento
- ✅ **Interface intuitiva** para seleção
- ✅ **Validação de disponibilidade**

### **Exemplo de Uso**

```dart
// Produto com variações
final tshirt = Product(
  id: 'tshirt_001',
  name: 'Camiseta Básica',
  price: 49.90, // Preço base
  variations: [
    ProductVariation(
      color: 'Preto',
      size: 'P',
      price: 49.90,
      stock: 15,
      sku: 'TSHIRT-BLK-P',
    ),
    ProductVariation(
      color: 'Azul',
      size: 'M',
      price: 54.90, // Preço diferente
      stock: 20,
      sku: 'TSHIRT-BLU-M',
    ),
  ],
);

// Acesso às propriedades
print('Cores: ${tshirt.availableColors}'); // ['Preto', 'Azul']
print('Tamanhos: ${tshirt.availableSizes}'); // ['P', 'M']
print('Preço mínimo: R\$ ${tshirt.minPrice}'); // 49.90
print('Preço máximo: R\$ ${tshirt.maxPrice}'); // 54.90
```

### **Interface do Usuário**
- **Seleção visual** de cores com círculos coloridos
- **Seleção de tamanhos** com botões interativos
- **Indicadores de estoque** (disponível/indisponível)
- **Preços dinâmicos** baseados na seleção
- **Informações detalhadas** da variação selecionada

## 🔧 Configurações Avançadas

### **Rate Limiting**
```javascript
// 100 requests por 15 minutos por IP
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100
});
```

### **CORS**
```javascript
app.use(cors({
  origin: ['http://localhost:3000', 'https://mercadodasophia.com'],
  credentials: true
}));
```

### **Upload de Imagens**
```javascript
const upload = multer({
  dest: 'uploads/',
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Apenas imagens são permitidas'));
    }
  }
});
```

## 🚀 Deploy

### **Heroku**
```bash
# Configure as variáveis de ambiente
heroku config:set NODE_ENV=production
heroku config:set DB_HOST=seu_host
heroku config:set JWT_SECRET=sua_chave_secreta

# Deploy
git push heroku main
```

### **Docker**
```bash
# Build da imagem
docker build -t mercadodasophia-api .

# Executar container
docker run -p 3000:3000 mercadodasophia-api
```

## 📝 Logs

A API gera logs detalhados para:
- **Requisições HTTP** (Morgan)
- **Erros de aplicação**
- **Importações do AliExpress**
- **Operações de banco de dados**

### **Exemplo de Log**
```
2024-01-08 15:30:45 - INFO: 🔍 Buscando produtos no AliExpress: "smartphone"
2024-01-08 15:31:02 - INFO: ✅ Produto importado com sucesso: 123e4567-e89b-12d3-a456-426614174000
2024-01-08 15:31:05 - ERROR: ❌ Erro ao conectar com banco de dados: connection refused
```

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 📞 Suporte

- **Email**: contato@mercadodasophia.com
- **Telefone**: (11) 99999-9999
- **Documentação**: [docs.mercadodasophia.com](https://docs.mercadodasophia.com)

---

**Desenvolvido com ❤️ pela equipe do Mercado da Sophia**
"# mercadodasophia" 
