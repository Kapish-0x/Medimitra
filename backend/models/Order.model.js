const mongoose = require('mongoose');

const orderItemSchema = new mongoose.Schema({
  medicine:  { type: mongoose.Schema.Types.ObjectId, ref: 'Medicine', required: true },
  name:      String,
  price:     Number,
  quantity:  { type: Number, required: true, min: 1 },
  total:     Number,
}, { _id: false });

const addressSchema = new mongoose.Schema({
  line1:   String,
  line2:   String,
  city:    String,
  state:   String,
  pincode: String,
}, { _id: false });

const orderSchema = new mongoose.Schema({
  user:            { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  items:           [orderItemSchema],
  subtotal:        Number,
  deliveryFee:     { type: Number, default: 0 },
  total:           Number,
  deliveryAddress: addressSchema,
  paymentMethod:   { type: String, enum: ['COD','UPI','Card'], default: 'COD' },
  paymentStatus:   { type: String, enum: ['Pending','Paid','Failed','Refunded'], default: 'Pending' },
  status: {
    type: String,
    enum: ['Placed','Confirmed','Shipped','Delivered','Cancelled'],
    default: 'Placed',
  },
  trackingId:      String,
  notes:           String,
}, { timestamps: true });

orderSchema.index({ user: 1, createdAt: -1 });

module.exports = mongoose.model('Order', orderSchema);
