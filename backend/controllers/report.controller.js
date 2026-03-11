const Report = require('../models/Report.model');
const User   = require('../models/User.model');
const path   = require('path');
const fs     = require('fs');

// ── GET /reports ──────────────────────────────────────────────────────────────
// Patient: only their own reports
// Doctor: reports they uploaded OR they are in allowedDoctors
// Admin: all reports
exports.getReports = async (req, res, next) => {
  try {
    const { user } = req;
    let query = { isDeleted: false };

    if (user.role === 'patient') {
      query.patient = user._id;
    } else if (user.role === 'doctor') {
      query.$or = [
        { uploadedBy: user._id },
        { allowedDoctors: user._id },
        { patient: user._id },  // (edge: doctor who is also a patient)
      ];
    }
    // admin: no filter beyond isDeleted:false

    const reports = await Report.find(query)
      .populate('patient',    'name email')
      .populate('uploadedBy', 'name role specialization')
      .sort({ createdAt: -1 })
      .lean();

    res.json({ success: true, count: reports.length, reports });
  } catch (err) {
    next(err);
  }
};

// ── GET /reports/:id ──────────────────────────────────────────────────────────
exports.getReport = async (req, res, next) => {
  try {
    const report = await Report.findOne({ _id: req.params.id, isDeleted: false })
      .populate('patient',    'name email')
      .populate('uploadedBy', 'name role specialization');

    if (!report) {
      return res.status(404).json({ success: false, message: 'Report not found.' });
    }

    if (!report.canAccess(req.user._id, req.user.role)) {
      return res.status(403).json({ success: false, message: 'You are not authorized to view this report.' });
    }

    // Don't leak file paths in response
    const safeReport = report.toObject();
    delete safeReport.file?.diskPath;

    res.json({ success: true, report: safeReport });
  } catch (err) {
    next(err);
  }
};

// ── POST /reports ─────────────────────────────────────────────────────────────
// Only doctors (and admins) can upload reports; they must specify a patient
exports.createReport = async (req, res, next) => {
  try {
    if (req.user.role !== 'doctor' && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Only doctors can upload reports.' });
    }

    const { title, type, status, notes, patientEmail, patientId } = req.body;

    // Resolve patient
    let patient;
    if (patientId) {
      patient = await User.findById(patientId);
    } else if (patientEmail) {
      patient = await User.findOne({ email: patientEmail, role: 'patient' });
    }

    if (!patient) {
      return res.status(404).json({ success: false, message: 'Patient not found.' });
    }

    const fileData = req.file
      ? { originalName: req.file.originalname, mimeType: req.file.mimetype, size: req.file.size, diskPath: req.file.path }
      : undefined;

    const report = await Report.create({
      title, type, status: status || 'Normal', notes,
      patient: patient._id,
      uploadedBy: req.user._id,
      file: fileData,
    });

    const populated = await report.populate([
      { path: 'patient', select: 'name email' },
      { path: 'uploadedBy', select: 'name role specialization' },
    ]);

    res.status(201).json({ success: true, report: populated });
  } catch (err) {
    next(err);
  }
};

// ── PATCH /reports/:id ────────────────────────────────────────────────────────
exports.updateReport = async (req, res, next) => {
  try {
    const report = await Report.findOne({ _id: req.params.id, isDeleted: false });
    if (!report) return res.status(404).json({ success: false, message: 'Report not found.' });

    // Only uploader or admin can update
    if (report.uploadedBy.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Not authorized to modify this report.' });
    }

    const allowed = ['title','type','status','notes','allowedDoctors'];
    allowed.forEach(f => { if (req.body[f] !== undefined) report[f] = req.body[f]; });
    await report.save();

    res.json({ success: true, report });
  } catch (err) {
    next(err);
  }
};

// ── DELETE /reports/:id ───────────────────────────────────────────────────────
exports.deleteReport = async (req, res, next) => {
  try {
    const report = await Report.findOne({ _id: req.params.id, isDeleted: false });
    if (!report) return res.status(404).json({ success: false, message: 'Report not found.' });

    if (report.uploadedBy.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Not authorized to delete this report.' });
    }

    report.isDeleted = true;
    await report.save();

    res.json({ success: true, message: 'Report deleted.' });
  } catch (err) {
    next(err);
  }
};

// ── GET /reports/:id/download ─────────────────────────────────────────────────
exports.downloadReport = async (req, res, next) => {
  try {
    const report = await Report.findOne({ _id: req.params.id, isDeleted: false });
    if (!report) return res.status(404).json({ success: false, message: 'Report not found.' });

    if (!report.canAccess(req.user._id, req.user.role)) {
      return res.status(403).json({ success: false, message: 'Access denied.' });
    }

    if (!report.file?.diskPath || !fs.existsSync(report.file.diskPath)) {
      return res.status(404).json({ success: false, message: 'File not found.' });
    }

    res.download(report.file.diskPath, report.file.originalName);
  } catch (err) {
    next(err);
  }
};

// ── POST /reports/:id/share ───────────────────────────────────────────────────
// Uploader can explicitly share with additional doctors
exports.shareReport = async (req, res, next) => {
  try {
    const { doctorId } = req.body;
    const report = await Report.findOne({ _id: req.params.id, isDeleted: false });
    if (!report) return res.status(404).json({ success: false, message: 'Report not found.' });

    // Only patient who owns the report OR uploader can share
    const isOwner = report.patient.toString() === req.user._id.toString();
    const isUploader = report.uploadedBy.toString() === req.user._id.toString();
    if (!isOwner && !isUploader && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Not authorized to share this report.' });
    }

    const doctor = await User.findOne({ _id: doctorId, role: 'doctor' });
    if (!doctor) return res.status(404).json({ success: false, message: 'Doctor not found.' });

    if (!report.allowedDoctors.includes(doctorId)) {
      report.allowedDoctors.push(doctorId);
      await report.save();
    }

    res.json({ success: true, message: `Report shared with Dr. ${doctor.name}` });
  } catch (err) {
    next(err);
  }
};
