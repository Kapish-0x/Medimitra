const router = require('express').Router();
const { register, login, refreshToken, logout, logoutAll, getMe } = require('../controllers/auth.controller');
const { protect } = require('../middleware/auth.middleware');
const { validate, registerRules, loginRules } = require('../middleware/validation.middleware');

router.post('/register',  registerRules, validate, register);
router.post('/login',     loginRules,    validate, login);
router.post('/refresh',   refreshToken);
router.post('/logout',    protect,       logout);
router.post('/logout-all',protect,       logoutAll);
router.get('/me',         protect,       getMe);

module.exports = router;
