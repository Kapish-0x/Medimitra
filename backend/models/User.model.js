const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const healthProfileSchema = new mongoose.Schema({
  bloodGroup: { type: String, enum: ['A+','A-','B+','B-','AB+','AB-','O+','O-',''], default: '' },
  height: Number,
  weight: Number,
  allergies: [String],
  chronicConditions: [String],
  emergencyContact: { name: String, phone: String, relation: String },
}, { _id: false });

const userSchema = new mongoose.Schema({
  name:             { type: String, required: true, trim: true, minlength: 2, maxlength: 100 },
  email:            { type: String, required: true, unique: true, lowercase: true, trim: true },
  password:         { type: String, required: true, minlength: 6, select: false },
  role:             { type: String, enum: ['patient','doctor','admin'], default: 'patient' },
  phone:            String,
  specialization:   String,
  licenseNumber:    String,
  hospitalAffiliation: String,
  isVerifiedDoctor: { type: Boolean, default: false },
  yearsOfExperience: Number,
  healthProfile:    { type: healthProfileSchema, default: () => ({}) },
  dateOfBirth:      Date,
  gender:           { type: String, enum: ['male','female','other',''], default: '' },
  isEmailVerified:  { type: Boolean, default: false },
  isActive:         { type: Boolean, default: true },
  refreshTokens:    [String],
  lastLogin:        Date,
  loginAttempts:    { type: Number, default: 0 },
  lockUntil:        Date,
  passwordResetToken: String,
  passwordResetExpires: Date,
}, { timestamps: true });

userSchema.index({ email: 1 });
userSchema.index({ role: 1 });

userSchema.virtual('isLocked').get(function () {
  return !!(this.lockUntil && this.lockUntil > Date.now());
});

userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, parseInt(process.env.BCRYPT_ROUNDS) || 12);
  next();
});

userSchema.methods.comparePassword = function (pw) {
  return bcrypt.compare(pw, this.password);
};

userSchema.methods.incLoginAttempts = async function () {
  if (this.lockUntil && this.lockUntil < Date.now()) {
    await this.updateOne({ $set: { loginAttempts: 1 }, $unset: { lockUntil: 1 } });
    return;
  }
  const updates = { $inc: { loginAttempts: 1 } };
  if (this.loginAttempts + 1 >= 5) {
    updates.$set = { lockUntil: new Date(Date.now() + 15 * 60 * 1000) };
  }
  await this.updateOne(updates);
};

userSchema.methods.toSafeObject = function () {
  const o = this.toObject({ virtuals: true });
  delete o.password; delete o.refreshTokens; delete o.loginAttempts;
  delete o.lockUntil; delete o.passwordResetToken; delete o.passwordResetExpires;
  return o;
};

module.exports = mongoose.model('User', userSchema);
