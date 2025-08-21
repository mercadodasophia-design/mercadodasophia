const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;
const { sequelize, testConnection } = require('./config/database');
const Product = require('./models/Product');
const Category = require('./models/Category');

// Middleware de segurança
app.use(helmet());
app.use(cors());
app.use(compression());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutos
  max: 100, // limite de 100 requests por IP
  message: 'Muitas requisições deste IP, tente novamente mais tarde.'
});
app.use('/api/', limiter);

// Logging
app.use(morgan('combined'));

// Parse JSON
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Associações Sequelize
// Produto pertence a Categoria; Categoria possui muitos Produtos
Product.belongsTo(Category, { as: 'category', foreignKey: 'category_id' });
Category.hasMany(Product, { as: 'products', foreignKey: 'category_id' });

// Rotas
app.use('/api/auth', require('./routes/auth'));
app.use('/api/products', require('./routes/products'));
app.use('/api/aliexpress', require('./routes/aliexpress'));
app.use('/api/admin', require('./routes/admin'));
app.use('/api/categories', require('./routes/categories'));

// Rota de health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    service: 'Mercado da Sophia API',
    version: '1.0.0'
  });
});

// Middleware de erro
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ 
    error: 'Erro interno do servidor',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Algo deu errado'
  });
});

// Rota 404
app.use('*', (req, res) => {
  res.status(404).json({ error: 'Rota não encontrada' });
});

app.listen(PORT, () => {
  console.log(`🚀 Servidor rodando na porta ${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
  console.log(`🔗 API Base URL: http://localhost:${PORT}/api`);
  // Inicializar conexão DB
  testConnection();
  // ATENÇÃO: alter=true ajusta schema automaticamente (bom para dev). Configure migrações para prod.
  sequelize.sync({ alter: true })
    .then(() => console.log('🗄️  Schema sincronizado (alter=true)'))
    .catch((err) => console.error('Erro ao sincronizar schema:', err));
});

module.exports = app; 