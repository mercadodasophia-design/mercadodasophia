const express = require('express');
const { body, query, validationResult } = require('express-validator');
const aliExpressService = require('../services/aliexpressService');
const Product = require('../models/Product');
const Category = require('../models/Category');
const router = express.Router();

// Middleware de autenticação (simplificado)
const authenticateToken = (req, res, next) => {
  const token = req.headers.authorization?.replace('Bearer ', '');
  
  if (!token) {
    return res.status(401).json({ error: 'Token não fornecido' });
  }
  
  // Aqui você pode adicionar verificação JWT completa
  // Por enquanto, vamos apenas verificar se o token existe
  next();
};

// Buscar produtos no AliExpress
router.get('/search', [
  query('q').notEmpty().withMessage('Query de busca é obrigatória'),
  query('limit').optional().isInt({ min: 1, max: 50 }).withMessage('Limit deve ser entre 1 e 50')
], authenticateToken, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        error: 'Parâmetros inválidos',
        details: errors.array() 
      });
    }

    const { q: query, limit = 20 } = req.query;

    console.log(`🔍 Buscando produtos no AliExpress: "${query}"`);

    const products = await aliExpressService.searchProducts(query, parseInt(limit));

    res.json({
      success: true,
      data: products,
      count: products.length,
      query
    });

  } catch (error) {
    console.error('Erro na busca:', error);
    res.status(500).json({ 
      error: 'Erro ao buscar produtos no AliExpress',
      message: error.message 
    });
  }
});

// Obter detalhes de um produto específico
router.get('/product/:productId', [
  query('url').notEmpty().withMessage('URL do produto é obrigatória')
], authenticateToken, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        error: 'Parâmetros inválidos',
        details: errors.array() 
      });
    }

    const { url } = req.query;

    console.log(`📦 Obtendo detalhes do produto: ${url}`);

    const productDetails = await aliExpressService.getProductDetails(url);

    res.json({
      success: true,
      data: productDetails
    });

  } catch (error) {
    console.error('Erro ao obter detalhes:', error);
    res.status(500).json({ 
      error: 'Erro ao obter detalhes do produto',
      message: error.message 
    });
  }
});

// Importar produto do AliExpress
router.post('/import', [
  body('aliexpress_url').notEmpty().withMessage('URL do AliExpress é obrigatória'),
  body('category_id').optional().isUUID().withMessage('ID da categoria inválido'),
  body('price_override').optional().isFloat({ min: 0 }).withMessage('Preço deve ser um número positivo'),
  body('stock_quantity').optional().isInt({ min: 0 }).withMessage('Quantidade em estoque deve ser um número inteiro positivo')
], authenticateToken, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        error: 'Dados inválidos',
        details: errors.array() 
      });
    }

    const { 
      aliexpress_url, 
      category_id, 
      price_override, 
      stock_quantity = 0 
    } = req.body;

    console.log(`📥 Importando produto: ${aliexpress_url}`);

    // Obter detalhes do produto
    const aliexpressData = await aliExpressService.getProductDetails(aliexpress_url);
    
    // Processar dados para importação
    const processedData = await aliExpressService.processProductForImport(aliexpressData);

    // Aplicar overrides se fornecidos
    if (price_override) {
      processedData.price = parseFloat(price_override);
    }
    
    if (stock_quantity !== undefined) {
      processedData.stock_quantity = parseInt(stock_quantity);
    }

    if (category_id) {
      processedData.category_id = category_id;
    }

    // Verificar se produto já existe
    const existingProduct = await Product.findOne({
      where: { aliexpress_id: processedData.aliexpress_id }
    });

    if (existingProduct) {
      return res.status(400).json({ 
        error: 'Produto já foi importado',
        product_id: existingProduct.id 
      });
    }

    // Criar produto no banco
    const product = await Product.create({
      ...processedData,
      description_html: processedData.description_html || null,
      created_by: req.user?.id || null
    });

    console.log(`✅ Produto importado com sucesso: ${product.id}`);

    res.status(201).json({
      success: true,
      message: 'Produto importado com sucesso',
      data: {
        id: product.id,
        name: product.name,
        price: product.price,
        status: product.status,
        aliexpress_id: product.aliexpress_id
      }
    });

  } catch (error) {
    console.error('Erro na importação:', error);
    res.status(500).json({ 
      error: 'Erro ao importar produto',
      message: error.message 
    });
  }
});

// Importar múltiplos produtos
router.post('/import-bulk', [
  body('products').isArray({ min: 1, max: 10 }).withMessage('Deve fornecer entre 1 e 10 produtos'),
  body('products.*.aliexpress_url').notEmpty().withMessage('URL do AliExpress é obrigatória'),
  body('products.*.category_id').optional().isUUID().withMessage('ID da categoria inválido'),
  body('products.*.price_override').optional().isFloat({ min: 0 }).withMessage('Preço deve ser um número positivo'),
  body('products.*.stock_quantity').optional().isInt({ min: 0 }).withMessage('Quantidade em estoque deve ser um número inteiro positivo')
], authenticateToken, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        error: 'Dados inválidos',
        details: errors.array() 
      });
    }

    const { products } = req.body;
    const results = {
      success: [],
      errors: []
    };

    console.log(`📦 Importando ${products.length} produtos em lote`);

    for (const productData of products) {
      try {
        const { 
          aliexpress_url, 
          category_id, 
          price_override, 
          stock_quantity = 0 
        } = productData;

        // Obter detalhes do produto
        const aliexpressData = await aliExpressService.getProductDetails(aliexpress_url);
        
        // Processar dados
        const processedData = await aliExpressService.processProductForImport(aliexpressData);

        // Aplicar overrides
        if (price_override) {
          processedData.price = parseFloat(price_override);
        }
        
        if (stock_quantity !== undefined) {
          processedData.stock_quantity = parseInt(stock_quantity);
        }

        if (category_id) {
          processedData.category_id = category_id;
        }

        // Verificar se já existe
        const existingProduct = await Product.findOne({
          where: { aliexpress_id: processedData.aliexpress_id }
        });

        if (existingProduct) {
          results.errors.push({
            url: aliexpress_url,
            error: 'Produto já foi importado',
            product_id: existingProduct.id
          });
          continue;
        }

        // Criar produto
        const product = await Product.create({
          ...processedData,
          created_by: req.user?.id || null
        });

        results.success.push({
          id: product.id,
          name: product.name,
          price: product.price,
          aliexpress_id: product.aliexpress_id
        });

      } catch (error) {
        results.errors.push({
          url: productData.aliexpress_url,
          error: error.message
        });
      }
    }

    res.json({
      success: true,
      message: `Importação concluída: ${results.success.length} sucessos, ${results.errors.length} erros`,
      data: results
    });

  } catch (error) {
    console.error('Erro na importação em lote:', error);
    res.status(500).json({ 
      error: 'Erro ao importar produtos em lote',
      message: error.message 
    });
  }
});

// Listar produtos importados
router.get('/imported', [
  query('page').optional().isInt({ min: 1 }).withMessage('Página deve ser um número positivo'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit deve ser entre 1 e 100'),
  query('status').optional().isIn(['draft', 'pending', 'active', 'inactive', 'deleted']).withMessage('Status inválido')
], authenticateToken, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        error: 'Parâmetros inválidos',
        details: errors.array() 
      });
    }

    const { 
      page = 1, 
      limit = 20, 
      status 
    } = req.query;

    const where = {
      aliexpress_id: { [require('sequelize').Op.ne]: null }
    };

    if (status) {
      where.status = status;
    }

    const { count, rows: products } = await Product.findAndCountAll({
      where,
      include: [
        {
          model: Category,
          as: 'category',
          attributes: ['id', 'name', 'slug']
        }
      ],
      order: [['created_at', 'DESC']],
      limit: parseInt(limit),
      offset: (parseInt(page) - 1) * parseInt(limit)
    });

    res.json({
      success: true,
      data: products,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: count,
        pages: Math.ceil(count / parseInt(limit))
      }
    });

  } catch (error) {
    console.error('Erro ao listar produtos importados:', error);
    res.status(500).json({ 
      error: 'Erro ao listar produtos importados',
      message: error.message 
    });
  }
});

// Estatísticas de importação
router.get('/stats', authenticateToken, async (req, res) => {
  try {
    const totalImported = await Product.count({
      where: { aliexpress_id: { [require('sequelize').Op.ne]: null } }
    });

    const byStatus = await Product.findAll({
      where: { aliexpress_id: { [require('sequelize').Op.ne]: null } },
      attributes: [
        'status',
        [require('sequelize').fn('COUNT', require('sequelize').col('id')), 'count']
      ],
      group: ['status']
    });

    const recentImports = await Product.findAll({
      where: { 
        aliexpress_id: { [require('sequelize').Op.ne]: null },
        created_at: {
          [require('sequelize').Op.gte]: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) // Últimos 7 dias
        }
      },
      attributes: ['id', 'name', 'status', 'created_at'],
      order: [['created_at', 'DESC']],
      limit: 10
    });

    res.json({
      success: true,
      data: {
        total_imported: totalImported,
        by_status: byStatus,
        recent_imports: recentImports
      }
    });

  } catch (error) {
    console.error('Erro ao obter estatísticas:', error);
    res.status(500).json({ 
      error: 'Erro ao obter estatísticas',
      message: error.message 
    });
  }
});

module.exports = router; 