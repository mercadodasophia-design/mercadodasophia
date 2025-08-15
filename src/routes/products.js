const express = require('express');
const { body, query } = require('express-validator');
const Product = require('../models/Product');
const router = express.Router();

// Endpoint de teste
router.get('/test', (req, res) => {
  res.json({ message: 'Products route working!' });
});

// Cálculo simples de frete próprio (origem: loja)
// Regras exemplo: base por faixa de CEP + peso/valor
router.post('/shipping/quote', [
  body('destination_cep').notEmpty(),
  body('items').isArray({ min: 1 }),
], async (req, res) => {
  try {
    const { destination_cep, items, options } = req.body;

    // Parâmetros configuráveis
    const originCep = process.env.STORE_ORIGIN_CEP || '01001-000';
    const handlingDays = parseInt(process.env.STORE_HANDLING_DAYS || '2', 10);
    const inboundDays = parseInt(process.env.INBOUND_LEAD_TIME_DAYS || '12', 10);

    // Simples estimativa de peso/valor
    const totalValue = items.reduce((s, it) => s + (it.price || 0) * (it.quantity || 1), 0);
    const totalWeight = items.reduce((s, it) => s + (it.weight || 0.5) * (it.quantity || 1), 0); // 0.5kg default

    // Tabela simplificada de frete próprio
    const services = [
      {
        code: 'OWN_ECONOMY',
        name: 'Entrega Padrão (Loja)',
        base: 19.9,
        perKg: 6.5,
        carrier: 'Correios/Parceiro',
        transitDays: 5,
      },
      {
        code: 'OWN_EXPRESS',
        name: 'Entrega Expressa (Loja)',
        base: 29.9,
        perKg: 9.9,
        carrier: 'Parceiro Expresso',
        transitDays: 2,
      },
    ];

    const quotes = services.map(s => {
      const price = s.base + Math.max(0, totalWeight - 1) * s.perKg;
      const etaDays = inboundDays + handlingDays + s.transitDays;
      const etaDate = new Date();
      etaDate.setDate(etaDate.getDate() + etaDays);
      return {
        service_code: s.code,
        service_name: s.name,
        carrier: s.carrier,
        price: Math.round(price * 100) / 100,
        currency: 'BRL',
        estimated_days: etaDays,
        estimated_delivery_date: etaDate.toISOString(),
        origin_cep: originCep,
        destination_cep,
        notes: 'Cálculo de frete próprio (envio a partir da loja).',
      };
    });

    res.json({ success: true, data: quotes });
  } catch (err) {
    console.error('Erro na cotação de frete:', err);
    res.status(500).json({ success: false, error: 'Erro ao calcular frete' });
  }
});

module.exports = router;


