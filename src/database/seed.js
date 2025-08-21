require('dotenv').config();
const { sequelize } = require('../config/database');
const Category = require('../models/Category');
const User = require('../models/User');

async function runSeed() {
  try {
    await sequelize.authenticate();
    console.log('✅ Conectado ao banco');

    // Categorias básicas
    const defaultCategories = [
      { name: 'Geral', slug: 'geral' },
      { name: 'Eletrônicos', slug: 'eletronicos' },
      { name: 'Casa e Jardim', slug: 'casa-jardim' },
    ];

    for (const cat of defaultCategories) {
      await Category.findOrCreate({ where: { slug: cat.slug }, defaults: cat });
    }
    console.log('📂 Categorias básicas criadas/atualizadas');

    // Usuário admin padrão (dev)
    const adminEmail = process.env.ADMIN_EMAIL || 'admin@mercadodasophia.com';
    const adminPassword = process.env.ADMIN_PASSWORD || 'senha123';
    await User.findOrCreate({
      where: { email: adminEmail },
      defaults: {
        name: 'Administrador',
        email: adminEmail,
        password: adminPassword,
        role: 'admin',
      },
    });
    console.log('👤 Usuário admin pronto');

    process.exit(0);
  } catch (err) {
    console.error('❌ Erro no seed:', err);
    process.exit(1);
  }
}

runSeed();


