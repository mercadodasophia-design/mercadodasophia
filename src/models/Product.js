const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Product = sequelize.define('Product', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false,
    validate: {
      len: [1, 255]
    }
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  description_html: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  price: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
    validate: {
      min: 0
    }
  },
  original_price: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: true
  },
  cost_price: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: true
  },
  stock_quantity: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
    validate: {
      min: 0
    }
  },
  sku: {
    type: DataTypes.STRING,
    allowNull: true,
    unique: true
  },
  barcode: {
    type: DataTypes.STRING,
    allowNull: true
  },
  weight: {
    type: DataTypes.DECIMAL(8, 3),
    allowNull: true
  },
  dimensions: {
    type: DataTypes.JSON,
    allowNull: true
  },
  images: {
    type: DataTypes.JSON,
    allowNull: true,
    defaultValue: []
  },
  main_image: {
    type: DataTypes.STRING,
    allowNull: true
  },
  category_id: {
    type: DataTypes.UUID,
    allowNull: true,
    references: {
      model: 'categories',
      key: 'id'
    }
  },
  brand: {
    type: DataTypes.STRING,
    allowNull: true
  },
  tags: {
    type: DataTypes.JSON,
    allowNull: true,
    defaultValue: []
  },
  specifications: {
    type: DataTypes.JSON,
    allowNull: true
  },
  // Campos específicos do AliExpress
  aliexpress_id: {
    type: DataTypes.STRING,
    allowNull: true,
    unique: true
  },
  aliexpress_url: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  aliexpress_rating: {
    type: DataTypes.DECIMAL(3, 2),
    allowNull: true
  },
  aliexpress_reviews_count: {
    type: DataTypes.INTEGER,
    allowNull: true
  },
  aliexpress_sales_count: {
    type: DataTypes.INTEGER,
    allowNull: true
  },
  // Status do produto
  status: {
    type: DataTypes.ENUM('draft', 'pending', 'active', 'inactive', 'deleted'),
    allowNull: false,
    defaultValue: 'draft'
  },
  is_featured: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false
  },
  is_on_sale: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false
  },
  sale_percentage: {
    type: DataTypes.INTEGER,
    allowNull: true,
    validate: {
      min: 0,
      max: 100
    }
  },
  // Metadados
  meta_title: {
    type: DataTypes.STRING,
    allowNull: true
  },
  meta_description: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  meta_keywords: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  // Campos de auditoria
  created_by: {
    type: DataTypes.UUID,
    allowNull: true,
    references: {
      model: 'users',
      key: 'id'
    }
  },
  approved_by: {
    type: DataTypes.UUID,
    allowNull: true,
    references: {
      model: 'users',
      key: 'id'
    }
  },
  approved_at: {
    type: DataTypes.DATE,
    allowNull: true
  }
}, {
  tableName: 'products',
  indexes: [
    {
      fields: ['name']
    },
    {
      fields: ['category_id']
    },
    {
      fields: ['status']
    },
    {
      fields: ['aliexpress_id']
    },
    {
      fields: ['sku']
    }
  ]
});

module.exports = Product; 