const express = require('express');
const router = express.Router();

// Rotas administrativas mínimas (placeholder)
router.get('/ping', (req, res) => {
  res.json({ success: true, message: 'admin ok' });
});

module.exports = router;


