const express = require('express');
const Category = require('../models/Category');
const router = express.Router();

router.get('/', async (req, res) => {
  try {
    const items = await Category.findAll({ order: [['name', 'ASC']] });
    res.json({ success: true, data: items });
  } catch (e) {
    res.status(500).json({ success: false, error: 'Erro ao listar categorias' });
  }
});

module.exports = router;


