const mongoose = require('mongoose');

const appointmentSchema = new mongoose.Schema({
  patient:  { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  doctor:   { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  date:     { type: Date, required: true },
  timeSlot: { type: String, required: true },   // e.g. "10:30 AM"
  type:     { type: String, enum: ['In-Person','Online'], default: 'In-Person' },
  status:   {
    type: String,
    enum: ['Pending','Confirmed','Completed','Cancelled'],
    default: 'Pending',
  },
  reason:       { type: String, trim: true },
  notes:        { type: String, trim: true },   // doctor's notes
  cancelReason: { type: String, trim: true },
}, { timestamps: true });

appointmentSchema.index({ patient: 1, date: -1 });
appointmentSchema.index({ doctor: 1, date: -1 });
appointmentSchema.index({ date: 1, status: 1 });

module.exports = mongoose.model('Appointment', appointmentSchema);
