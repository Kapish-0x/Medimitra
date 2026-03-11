const Appointment = require('../models/Appointment.model');
const User = require('../models/User.model');

// ── GET /appointments ─────────────────────────────────────────────────────────
exports.getAppointments = async (req, res, next) => {
  try {
    const { user } = req;
    let query = {};

    if (user.role === 'patient') query.patient = user._id;
    else if (user.role === 'doctor') query.doctor = user._id;
    // admin: all

    const { upcoming, status } = req.query;
    if (upcoming === 'true') {
      query.date = { $gte: new Date() };
      if (!status) query.status = { $ne: 'Cancelled' };
    }
    if (status) query.status = status;

    const appointments = await Appointment.find(query)
      .populate('patient', 'name email phone')
      .populate('doctor',  'name email specialization hospitalAffiliation')
      .sort({ date: 1 })
      .lean();

    res.json({ success: true, count: appointments.length, appointments });
  } catch (err) {
    next(err);
  }
};

// ── GET /appointments/:id ─────────────────────────────────────────────────────
exports.getAppointment = async (req, res, next) => {
  try {
    const appt = await Appointment.findById(req.params.id)
      .populate('patient', 'name email phone healthProfile')
      .populate('doctor',  'name email specialization');

    if (!appt) return res.status(404).json({ success: false, message: 'Appointment not found.' });

    const { user } = req;
    const isPatient = appt.patient._id.toString() === user._id.toString();
    const isDoctor  = appt.doctor._id.toString()  === user._id.toString();
    if (!isPatient && !isDoctor && user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Access denied.' });
    }

    res.json({ success: true, appointment: appt });
  } catch (err) {
    next(err);
  }
};

// ── POST /appointments ────────────────────────────────────────────────────────
exports.createAppointment = async (req, res, next) => {
  try {
    if (req.user.role !== 'patient') {
      return res.status(403).json({ success: false, message: 'Only patients can book appointments.' });
    }

    const { doctorId, date, timeSlot, type, reason } = req.body;

    const doctor = await User.findOne({ _id: doctorId, role: 'doctor' });
    if (!doctor) return res.status(404).json({ success: false, message: 'Doctor not found.' });

    // Prevent double booking same slot
    const conflict = await Appointment.findOne({
      doctor: doctorId, date: new Date(date).setHours(0,0,0,0),
      timeSlot, status: { $nin: ['Cancelled'] },
    });
    if (conflict) {
      return res.status(409).json({ success: false, message: 'This time slot is already booked.' });
    }

    const appt = await Appointment.create({
      patient: req.user._id,
      doctor: doctorId,
      date: new Date(date),
      timeSlot, type, reason,
    });

    const populated = await appt.populate([
      { path: 'patient', select: 'name email' },
      { path: 'doctor',  select: 'name specialization' },
    ]);

    res.status(201).json({ success: true, appointment: populated });
  } catch (err) {
    next(err);
  }
};

// ── PATCH /appointments/:id/status ────────────────────────────────────────────
exports.updateStatus = async (req, res, next) => {
  try {
    const appt = await Appointment.findById(req.params.id);
    if (!appt) return res.status(404).json({ success: false, message: 'Appointment not found.' });

    const { user } = req;
    const isPatient = appt.patient.toString() === user._id.toString();
    const isDoctor  = appt.doctor.toString()  === user._id.toString();

    const { status, notes, cancelReason } = req.body;

    // Permission rules
    if (status === 'Cancelled' && !isPatient && !isDoctor && user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Not authorized.' });
    }
    if (['Confirmed','Completed'].includes(status) && !isDoctor && user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Only the doctor can confirm/complete.' });
    }

    appt.status = status;
    if (notes) appt.notes = notes;
    if (cancelReason) appt.cancelReason = cancelReason;
    await appt.save();

    res.json({ success: true, appointment: appt });
  } catch (err) {
    next(err);
  }
};

// ── DELETE /appointments/:id ──────────────────────────────────────────────────
exports.deleteAppointment = async (req, res, next) => {
  try {
    const appt = await Appointment.findById(req.params.id);
    if (!appt) return res.status(404).json({ success: false, message: 'Not found.' });
    if (appt.patient.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Not authorized.' });
    }
    await appt.deleteOne();
    res.json({ success: true, message: 'Appointment removed.' });
  } catch (err) {
    next(err);
  }
};
