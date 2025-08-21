require('dotenv').config();
const { sequelize } = require('../config/database');
const Product = require('../models/Product');
const Category = require('../models/Category');
const User = require('../models/User');

async function runMigrations() {
  try {
    // Associações mínimas
    Product.belongsTo(Category, { as: 'category', foreignKey: 'category_id' });
    Category.hasMany(Product, { as: 'products', foreignKey: 'category_id' });

    await sequelize.authenticate();
    console.log('✅ Conectado ao banco com sucesso');

    await sequelize.sync({ alter: true });
    console.log('🗄️  Migrações aplicadas com sucesso (alter=true)');
    process.exit(0);
  } catch (err) {
    console.error('❌ Erro ao aplicar migrações:', err);
    process.exit(1);
  }
}

runMigrations();


