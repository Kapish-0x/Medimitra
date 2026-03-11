const router = require('express').Router();
const ac = require('../controllers/appointment.controller');
const { protect } = require('../middleware/auth.middleware');
const { validate, appointmentRules } = require('../middleware/validation.middleware');

router.get('/',                protect, ac.getAppointments);
router.get('/:id',             protect, ac.getAppointment);
router.post('/',               protect, appointmentRules, validate, ac.createAppointment);
router.patch('/:id/status',    protect, ac.updateStatus);
router.delete('/:id',          protect, ac.deleteAppointment);

module.exports = router;
