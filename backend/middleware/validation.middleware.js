const { body, validationResult } = require('express-validator');

// Run validation and return 400 on failure
const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      message: errors.array()[0].msg,
      errors: errors.array(),
    });
  }
  next();
};

const registerRules = [
  body('name').trim().notEmpty().withMessage('Name is required').isLength({ min: 2, max: 100 }),
  body('email').trim().isEmail().withMessage('Valid email is required').normalizeEmail(),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  body('role').optional().isIn(['patient','doctor']).withMessage('Role must be patient or doctor'),
  body('licenseNumber').if(body('role').equals('doctor')).notEmpty().withMessage('License number required for doctors'),
];

const loginRules = [
  body('email').trim().isEmail().withMessage('Valid email required').normalizeEmail(),
  body('password').notEmpty().withMessage('Password is required'),
];

const appointmentRules = [
  body('doctorId').notEmpty().withMessage('Doctor is required'),
  body('date').isISO8601().withMessage('Valid date is required'),
  body('timeSlot').notEmpty().withMessage('Time slot is required'),
  body('type').optional().isIn(['In-Person','Online']),
];

const reportRules = [
  body('title').trim().notEmpty().withMessage('Report title is required'),
  body('patientEmail').if(body('patientId').not().exists()).isEmail().withMessage('Patient email is required'),
  body('type').optional().isIn(['Lab Report','Imaging','Cardiology','Prescription','Discharge Summary','Other']),
  body('status').optional().isIn(['Normal','Review','Critical','Pending']),
];

module.exports = { validate, registerRules, loginRules, appointmentRules, reportRules };
