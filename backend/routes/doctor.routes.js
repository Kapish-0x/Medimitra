const router = require('express').Router();
const uc = require('../controllers/user.controller');
const { protect, authorize } = require('../middleware/auth.middleware');

router.get('/',                   protect, uc.getDoctors);
router.get('/specializations',    protect, uc.getSpecializations);
router.get('/:id',                protect, uc.getDoctor);
router.patch('/:id/verify',       protect, authorize('admin'), uc.verifyDoctor);

module.exports = router;
