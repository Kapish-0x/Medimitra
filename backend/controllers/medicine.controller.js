// ─── Medicine Controller ───────────────────────────────────────────────────────
const Medicine = require('../models/Medicine.model');
const Order    = require('../models/Order.model');

exports.getMedicines = async (req, res, next) => {
  try {
    const { search, category, page = 1, limit = 20 } = req.query;
    const query = { isActive: true };

    if (category && category !== 'All') query.category = category;
    if (search) query.$text = { $search: search };

    const total = await Medicine.countDocuments(query);
    const medicines = await Medicine.find(query)
      .sort(search ? { score: { $meta: 'textScore' } } : { name: 1 })
      .skip((page - 1) * limit)
      .limit(parseInt(limit))
      .lean();

    res.json({
      success: true,
      count: medicines.length,
      total,
      pages: Math.ceil(total / limit),
      page: parseInt(page),
      medicines,
    });
  } catch (err) { next(err); }
};

exports.getMedicine = async (req, res, next) => {
  try {
    const med = await Medicine.findOne({ _id: req.params.id, isActive: true });
    if (!med) return res.status(404).json({ success: false, message: 'Medicine not found.' });
    res.json({ success: true, medicine: med });
  } catch (err) { next(err); }
};

exports.getCategories = async (req, res, next) => {
  try {
    const categories = await Medicine.distinct('category', { isActive: true });
    res.json({ success: true, categories: ['All', ...categories.sort()] });
  } catch (err) { next(err); }
};

// Admin only
exports.createMedicine = async (req, res, next) => {
  try {
    const med = await Medicine.create(req.body);
    res.status(201).json({ success: true, medicine: med });
  } catch (err) { next(err); }
};

exports.updateMedicine = async (req, res, next) => {
  try {
    const med = await Medicine.findByIdAndUpdate(req.params.id, req.body, { new: true, runValidators: true });
    if (!med) return res.status(404).json({ success: false, message: 'Not found.' });
    res.json({ success: true, medicine: med });
  } catch (err) { next(err); }
};

// ─── Order Controller ──────────────────────────────────────────────────────────
exports.createOrder = async (req, res, next) => {
  try {
    const { items, deliveryAddress, paymentMethod } = req.body;
    if (!items || !items.length) {
      return res.status(400).json({ success: false, message: 'Order must have at least one item.' });
    }

    let subtotal = 0;
    const resolvedItems = [];

    for (const item of items) {
      const med = await Medicine.findById(item.medicineId);
      if (!med || !med.isActive) {
        return res.status(404).json({ success: false, message: `Medicine not found: ${item.medicineId}` });
      }
      if (med.stock < item.quantity) {
        return res.status(400).json({ success: false, message: `Insufficient stock for ${med.name}` });
      }
      const itemTotal = med.price * item.quantity;
      subtotal += itemTotal;
      resolvedItems.push({ medicine: med._id, name: med.name, price: med.price, quantity: item.quantity, total: itemTotal });

      // Decrement stock
      await Medicine.findByIdAndUpdate(med._id, { $inc: { stock: -item.quantity } });
    }

    const order = await Order.create({
      user: req.user._id,
      items: resolvedItems,
      subtotal,
      deliveryFee: 0,
      total: subtotal,
      deliveryAddress,
      paymentMethod: paymentMethod || 'COD',
    });

    res.status(201).json({ success: true, order });
  } catch (err) { next(err); }
};

exports.getOrders = async (req, res, next) => {
  try {
    const query = req.user.role === 'admin' ? {} : { user: req.user._id };
    const orders = await Order.find(query)
      .populate('user', 'name email')
      .sort({ createdAt: -1 })
      .lean();
    res.json({ success: true, count: orders.length, orders });
  } catch (err) { next(err); }
};

exports.getOrder = async (req, res, next) => {
  try {
    const order = await Order.findById(req.params.id).populate('user', 'name email');
    if (!order) return res.status(404).json({ success: false, message: 'Order not found.' });
    if (order.user._id.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Access denied.' });
    }
    res.json({ success: true, order });
  } catch (err) { next(err); }
};
