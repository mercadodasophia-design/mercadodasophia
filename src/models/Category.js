const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Category = sequelize.define('Category', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false,
    validate: {
      len: [1, 100]
    }
  },
  slug: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true,
    validate: {
      len: [1, 100]
    }
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  image: {
    type: DataTypes.STRING,
    allowNull: true
  },
  icon: {
    type: DataTypes.STRING,
    allowNull: true
  },
  color: {
    type: DataTypes.STRING,
    allowNull: true,
    defaultValue: '#007bff'
  },
  parent_id: {
    type: DataTypes.UUID,
    allowNull: true,
    references: {
      model: 'categories',
      key: 'id'
    }
  },
  level: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
    validate: {
      min: 0,
      max: 5
    }
  },
  sort_order: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0
  },
  is_active: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: true
  },
  is_featured: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false
  },
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
  }
}, {
  tableName: 'categories',
  indexes: [
    {
      fields: ['name']
    },
    {
      fields: ['slug']
    },
    {
      fields: ['parent_id']
    },
    {
      fields: ['is_active']
    }
  ]
});

module.exports = Category; 