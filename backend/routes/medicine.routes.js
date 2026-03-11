const mrouter = require('express').Router();
const orouter = require('express').Router();
const mc = require('../controllers/medicine.controller');
const { protect, authorize } = require('../middleware/auth.middleware');

// ── Medicine routes ────────────────────────────────────────────────────────────
mrouter.get('/',          protect, mc.getMedicines);
mrouter.get('/categories',protect, mc.getCategories);
mrouter.get('/:id',       protect, mc.getMedicine);
mrouter.post('/',         protect, authorize('admin'), mc.createMedicine);
mrouter.put('/:id',       protect, authorize('admin'), mc.updateMedicine);

// ── Order routes ──────────────────────────────────────────────────────────────
orouter.get('/',     protect, mc.getOrders);
orouter.get('/:id',  protect, mc.getOrder);
orouter.post('/',    protect, mc.createOrder);

module.exports = { medicineRouter: mrouter, orderRouter: orouter };
