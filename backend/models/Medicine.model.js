const mongoose = require('mongoose');

const medicineSchema = new mongoose.Schema({
  name:                { type: String, required: true, trim: true },
  brand:               { type: String, trim: true },
  genericName:         { type: String, trim: true },
  category: {
    type: String,
    enum: ['Vitamins','Antibiotics','Cardiac','Diabetes','Pain Relief','Other'],
    default: 'Other',
  },
  description:         String,
  price:               { type: Number, required: true, min: 0 },
  originalPrice:       { type: Number, min: 0 },
  unit:                { type: String, default: 'strip' },  // strip, bottle, tube
  quantityPerUnit:     { type: Number, default: 10 },
  stock:               { type: Number, default: 0, min: 0 },
  requiresPrescription:{ type: Boolean, default: false },
  manufacturer:        String,
  isActive:            { type: Boolean, default: true },
  imageUrl:            String,
}, { timestamps: true });

medicineSchema.index({ name: 'text', genericName: 'text', brand: 'text' });
medicineSchema.index({ category: 1 });
medicineSchema.index({ isActive: 1 });

module.exports = mongoose.model('Medicine', medicineSchema);
