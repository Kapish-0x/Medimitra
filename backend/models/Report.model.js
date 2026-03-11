const mongoose = require('mongoose');

const reportSchema = new mongoose.Schema({
  title:      { type: String, required: true, trim: true },
  type:       {
    type: String,
    enum: ['Lab Report','Imaging','Cardiology','Prescription','Discharge Summary','Other'],
    default: 'Lab Report',
  },
  status:     { type: String, enum: ['Normal','Review','Critical','Pending'], default: 'Normal' },
  notes:      { type: String, trim: true },

  // The patient this report belongs to — REQUIRED for access control
  patient:    { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },

  // Who uploaded — typically a doctor or admin
  uploadedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },

  // Doctors who are explicitly allowed to view this report (besides uploader & patient)
  allowedDoctors: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],

  // File metadata (stored in GridFS / disk — path is server-side only, never sent raw)
  file: {
    originalName: String,
    mimeType:     String,
    size:         Number,          // bytes
    gridfsId:     mongoose.Schema.Types.ObjectId,  // GridFS file id
    diskPath:     String,          // local path (dev only)
  },

  isDeleted: { type: Boolean, default: false },
}, { timestamps: true });

// Index for fast patient-based queries
reportSchema.index({ patient: 1, createdAt: -1 });
reportSchema.index({ uploadedBy: 1 });

// ── Access control helper ────────────────────────────────────────────────────
// Returns true if the requesting user is allowed to view this report
reportSchema.methods.canAccess = function (userId, userRole) {
  const uid = userId.toString();
  // Admin can always access
  if (userRole === 'admin') return true;
  // Patient can only access their own reports
  if (this.patient.toString() === uid) return true;
  // Uploader doctor can access
  if (this.uploadedBy.toString() === uid) return true;
  // Explicitly allowed doctors
  if (this.allowedDoctors.some(d => d.toString() === uid)) return true;
  return false;
};

module.exports = mongoose.model('Report', reportSchema);
