const express      = require('express');
const mongoose     = require('mongoose');
const cors         = require('cors');
const helmet       = require('helmet');
const morgan       = require('morgan');
const rateLimit    = require('express-rate-limit');
const mongoSanitize= require('express-mongo-sanitize');
require('dotenv').config();

const authRoutes        = require('./routes/auth.routes');
const userRoutes        = require('./routes/user.routes');
const appointmentRoutes = require('./routes/appointment.routes');
const reportRoutes      = require('./routes/report.routes');
const doctorRoutes      = require('./routes/doctor.routes');
const { medicineRouter, orderRouter } = require('./routes/medicine.routes');
const errorHandler      = require('./middleware/error.middleware');

const app = express();

// ── Security ──────────────────────────────────────────────────────────────────
app.use(helmet());
app.use(mongoSanitize());   // Prevent NoSQL injection

// Global rate limiter
app.use(rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
  max:      parseInt(process.env.RATE_LIMIT_MAX) || 200,
  message:  { success: false, message: 'Too many requests. Try again later.' },
  standardHeaders: true, legacyHeaders: false,
}));

// Strict limiter for auth endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  message: { success: false, message: 'Too many auth attempts. Try again in 15 minutes.' },
});

// ── CORS ──────────────────────────────────────────────────────────────────────
app.use(cors({
  origin:  process.env.CLIENT_URL || '*',
  methods: ['GET','POST','PUT','PATCH','DELETE','OPTIONS'],
  allowedHeaders: ['Content-Type','Authorization'],
  credentials: true,
}));

// ── Body parsing ──────────────────────────────────────────────────────────────
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// ── Logging ───────────────────────────────────────────────────────────────────
if (process.env.NODE_ENV !== 'test') app.use(morgan('dev'));

// BLOCK direct file access — files are served via authenticated /reports/:id/download only
app.use('/uploads', (req, res) =>
  res.status(403).json({ success: false, message: 'Direct file access is forbidden.' })
);

// ── Health check ──────────────────────────────────────────────────────────────
app.get('/api/health', (req, res) => res.json({
  success: true, message: 'Medimitra API running',
  env: process.env.NODE_ENV, ts: new Date().toISOString(),
}));

// ── Routes ────────────────────────────────────────────────────────────────────
app.use('/api/auth',          authLimiter, authRoutes);
app.use('/api/users',         userRoutes);
app.use('/api/appointments',  appointmentRoutes);
app.use('/api/reports',       reportRoutes);
app.use('/api/doctors',       doctorRoutes);
app.use('/api/medicines',     medicineRouter);
app.use('/api/orders',        orderRouter);

// ── 404 ───────────────────────────────────────────────────────────────────────
app.use('*', (req, res) =>
  res.status(404).json({ success: false, message: `Route ${req.originalUrl} not found.` })
);

// ── Global error handler ──────────────────────────────────────────────────────
app.use(errorHandler);

// ── DB + Start ─────────────────────────────────────────────────────────────────
const connectDB = async () => {
  const conn = await mongoose.connect(process.env.MONGO_URI);
  console.log(`✅  MongoDB: ${conn.connection.host}`);
};

const PORT = process.env.PORT || 5000;
connectDB()
  .then(() => app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀  Medimitra API → http://localhost:${PORT}  [${process.env.NODE_ENV}]`);
    console.log(`📱  Phone access  → http://192.168.0.5:${PORT}`);
  }))
  .catch(err => { console.error('❌  DB connect failed:', err.message); process.exit(1); });

module.exports = app;
