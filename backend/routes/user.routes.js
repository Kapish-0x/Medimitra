// user.routes.js
const urouter = require('express').Router();
const uc = require('../controllers/user.controller');
const { protect } = require('../middleware/auth.middleware');

urouter.get('/profile',          protect, uc.getProfile);
urouter.put('/profile',          protect, uc.updateProfile);
urouter.post('/change-password', protect, uc.changePassword);

module.exports = urouter;
