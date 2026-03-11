const router  = require('express').Router();
const rc      = require('../controllers/report.controller');
const { protect, authorize } = require('../middleware/auth.middleware');
const multer  = require('multer');
const path    = require('path');
const crypto  = require('crypto');
const fs      = require('fs');

// ── Multer config ─────────────────────────────────────────────────────────────
const UPLOAD_DIR = process.env.UPLOAD_PATH || './uploads/reports';
if (!fs.existsSync(UPLOAD_DIR)) fs.mkdirSync(UPLOAD_DIR, { recursive: true });

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, UPLOAD_DIR),
  filename:    (req, file, cb) => {
    const ext  = path.extname(file.originalname);
    const name = crypto.randomBytes(16).toString('hex');
    cb(null, `${name}${ext}`);
  },
});

const fileFilter = (req, file, cb) => {
  const allowed = ['application/pdf','image/jpeg','image/png','image/jpg'];
  if (allowed.includes(file.mimetype)) cb(null, true);
  else cb(new Error('Only PDF and image files are allowed'), false);
};

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: parseInt(process.env.MAX_FILE_SIZE) || 10 * 1024 * 1024 },
});

// ── Routes ────────────────────────────────────────────────────────────────────
router.get('/',                protect,                          rc.getReports);
router.get('/:id',             protect,                          rc.getReport);
router.get('/:id/download',    protect,                          rc.downloadReport);
router.post('/',               protect, authorize('doctor','admin'), upload.single('file'), rc.createReport);
router.patch('/:id',           protect,                          rc.updateReport);
router.delete('/:id',          protect,                          rc.deleteReport);
router.post('/:id/share',      protect,                          rc.shareReport);

module.exports = router;
