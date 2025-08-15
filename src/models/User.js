const { DataTypes } = require('sequelize');
const bcrypt = require('bcryptjs');
const { sequelize } = require('../config/database');

const User = sequelize.define('User', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false,
    validate: {
      len: [2, 100]
    }
  },
  email: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true,
    validate: {
      isEmail: true
    }
  },
  password: {
    type: DataTypes.STRING,
    allowNull: false,
    validate: {
      len: [6, 255]
    }
  },
  role: {
    type: DataTypes.ENUM('admin', 'manager', 'editor', 'viewer'),
    allowNull: false,
    defaultValue: 'viewer'
  },
  avatar: {
    type: DataTypes.STRING,
    allowNull: true
  },
  phone: {
    type: DataTypes.STRING,
    allowNull: true
  },
  is_active: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: true
  },
  last_login: {
    type: DataTypes.DATE,
    allowNull: true
  },
  login_attempts: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0
  },
  locked_until: {
    type: DataTypes.DATE,
    allowNull: true
  },
  reset_token: {
    type: DataTypes.STRING,
    allowNull: true
  },
  reset_token_expires: {
    type: DataTypes.DATE,
    allowNull: true
  },
  preferences: {
    type: DataTypes.JSON,
    allowNull: true,
    defaultValue: {}
  }
}, {
  tableName: 'users',
  hooks: {
    beforeCreate: async (user) => {
      if (user.password) {
        user.password = await bcrypt.hash(user.password, 10);
      }
    },
    beforeUpdate: async (user) => {
      if (user.changed('password')) {
        user.password = await bcrypt.hash(user.password, 10);
      }
    }
  },
  indexes: [
    {
      fields: ['email']
    },
    {
      fields: ['role']
    },
    {
      fields: ['is_active']
    }
  ]
});

// Método para comparar senhas
User.prototype.comparePassword = async function(candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

// Método para verificar permissões
User.prototype.hasPermission = function(permission) {
  const permissions = {
    admin: ['all'],
    manager: ['read', 'write', 'approve'],
    editor: ['read', 'write'],
    viewer: ['read']
  };
  
  const userPermissions = permissions[this.role] || [];
  return userPermissions.includes('all') || userPermissions.includes(permission);
};

module.exports = User; 