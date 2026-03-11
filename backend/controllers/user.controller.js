const User = require('../models/User.model');
const bcrypt = require('bcryptjs');

// ── GET /users/profile ────────────────────────────────────────────────────────
exports.getProfile = (req, res) => {
  res.json({ success: true, user: req.user.toSafeObject() });
};

// ── PUT /users/profile ────────────────────────────────────────────────────────
exports.updateProfile = async (req, res, next) => {
  try {
    const allowed = ['name','phone','gender','dateOfBirth','healthProfile',
                     'specialization','hospitalAffiliation','yearsOfExperience'];
    const updates = {};
    allowed.forEach(f => { if (req.body[f] !== undefined) updates[f] = req.body[f]; });

    const user = await User.findByIdAndUpdate(req.user._id, updates, { new: true, runValidators: true });
    res.json({ success: true, user: user.toSafeObject() });
  } catch (err) { next(err); }
};

// ── POST /users/change-password ───────────────────────────────────────────────
exports.changePassword = async (req, res, next) => {
  try {
    const { currentPassword, newPassword } = req.body;
    if (!currentPassword || !newPassword) {
      return res.status(400).json({ success: false, message: 'Both passwords required.' });
    }
    if (newPassword.length < 6) {
      return res.status(400).json({ success: false, message: 'New password must be at least 6 characters.' });
    }

    const user = await User.findById(req.user._id).select('+password');
    const ok = await user.comparePassword(currentPassword);
    if (!ok) return res.status(401).json({ success: false, message: 'Current password is incorrect.' });

    user.password = newPassword;
    // Invalidate all sessions on password change
    user.refreshTokens = [];
    await user.save();

    res.json({ success: true, message: 'Password changed. Please sign in again.' });
  } catch (err) { next(err); }
};

// ── GET /doctors ──────────────────────────────────────────────────────────────
exports.getDoctors = async (req, res, next) => {
  try {
    const { specialization, search } = req.query;
    const query = { role: 'doctor', isActive: true };
    if (specialization && specialization !== 'All') query.specialization = specialization;
    if (search) query.$or = [
      { name: { $regex: search, $options: 'i' } },
      { specialization: { $regex: search, $options: 'i' } },
    ];

    const doctors = await User.find(query)
      .select('name email specialization hospitalAffiliation isVerifiedDoctor yearsOfExperience')
      .sort({ isVerifiedDoctor: -1, name: 1 })
      .lean();

    res.json({ success: true, count: doctors.length, doctors });
  } catch (err) { next(err); }
};

// ── GET /doctors/specializations ──────────────────────────────────────────────
exports.getSpecializations = async (req, res, next) => {
  try {
    const specs = await User.distinct('specialization', { role: 'doctor', isActive: true, specialization: { $ne: null } });
    res.json({ success: true, specializations: specs.filter(Boolean).sort() });
  } catch (err) { next(err); }
};

// ── GET /doctors/:id ──────────────────────────────────────────────────────────
exports.getDoctor = async (req, res, next) => {
  try {
    const doctor = await User.findOne({ _id: req.params.id, role: 'doctor' })
      .select('name email specialization hospitalAffiliation isVerifiedDoctor yearsOfExperience');
    if (!doctor) return res.status(404).json({ success: false, message: 'Doctor not found.' });
    res.json({ success: true, doctor });
  } catch (err) { next(err); }
};

// ── PATCH /doctors/:id/verify (admin only) ────────────────────────────────────
exports.verifyDoctor = async (req, res, next) => {
  try {
    const doctor = await User.findOneAndUpdate(
      { _id: req.params.id, role: 'doctor' },
      { isVerifiedDoctor: true },
      { new: true }
    );
    if (!doctor) return res.status(404).json({ success: false, message: 'Doctor not found.' });
    res.json({ success: true, message: `Dr. ${doctor.name} has been verified.`, doctor: doctor.toSafeObject() });
  } catch (err) { next(err); }
};
