# 🏥 Medimitra — Full-Stack Healthcare App

> Flutter (frontend) + Node.js + MongoDB (backend)

---

## 📁 Project Structure

```
medimitra/
├── backend/                   ← Node.js + Express + MongoDB
│   ├── server.js              ← Entry point
│   ├── .env.example           ← Copy to .env and fill in values
│   ├── seed.js                ← Seed DB with sample data
│   ├── models/
│   │   ├── User.model.js      ← Patient, Doctor, Admin
│   │   ├── Report.model.js    ← Medical reports (access-controlled)
│   │   ├── Appointment.model.js
│   │   ├── Medicine.model.js
│   │   └── Order.model.js
│   ├── controllers/           ← Business logic
│   ├── routes/                ← Express routers
│   ├── middleware/
│   │   ├── auth.middleware.js ← JWT protect + role authorize
│   │   ├── error.middleware.js
│   │   └── validation.middleware.js
│   └── utils/
│       └── jwt.utils.js       ← Access + refresh token helpers
│
└── frontend/                  ← Flutter app
    ├── main.dart
    ├── pubspec.yaml
    ├── core/
    │   ├── config/app_config.dart   ← API base URL
    │   ├── network/api_client.dart  ← Dio + auto token refresh
    │   ├── providers/
    │   │   ├── auth_provider.dart   ← Auth state (ChangeNotifier)
    │   │   └── cart_provider.dart   ← Cart state
    │   └── theme/app_theme.dart
    └── screens/
        ├── splash_screen.dart
        ├── onboarding_screen.dart
        ├── auth/login_screen.dart
        ├── auth/register_screen.dart
        ├── home/home_screen.dart        ← Bottom nav shell
        ├── home/dashboard_tab.dart      ← Main dashboard
        ├── appointments/appointments_tab.dart
        ├── reports/reports_tab.dart
        ├── medicines/medicines_tab.dart
        ├── medicines/cart_screen.dart
        └── profile/profile_tab.dart
```

---

## 🚀 Quick Start

### Backend

```bash
cd medimitra/backend

# 1. Install dependencies
npm install

# 2. Set up environment variables
cp .env.example .env
# Edit .env — update MONGO_URI, JWT_SECRET, JWT_REFRESH_SECRET

# 3. Seed the database with sample data
node seed.js

# 4. Start the server
npm run dev        # development (nodemon)
npm start          # production
```

**Default seed accounts:**
| Role    | Email                  | Password     |
|---------|------------------------|--------------|
| Admin   | admin@medimitra.com    | Admin@123    |
| Doctor  | doctor@medimitra.com   | Doctor@123   |
| Patient | arjun@medimitra.com    | Patient@123  |

---

### Frontend (Flutter)

```bash
cd medimitra/frontend

# 1. Copy all .dart files into your Flutter project's lib/ folder
#    keeping the folder structure intact

# 2. Update API base URL in core/config/app_config.dart:
#    - Android emulator:  http://10.0.2.2:5000/api
#    - iOS simulator:     http://localhost:5000/api
#    - Real device:       http://<your-machine-ip>:5000/api

# 3. Install packages
flutter pub get

# 4. Run
flutter run
```

---

## 🔐 Security Features

### Authentication
- **JWT Access Tokens** (7-day expiry) + **Refresh Tokens** (30-day expiry)
- **Token rotation** — refresh token is replaced on every use
- **Multi-device support** — up to 5 refresh tokens stored per user
- **Account lockout** — locked for 15 min after 5 failed login attempts
- **Password hashing** — bcrypt with 12 rounds

### Medical Report Access Control
Reports are the most sensitive data. Access is strictly enforced:

| Role    | Can View                                       | Can Upload |
|---------|------------------------------------------------|------------|
| Patient | Only their own reports                         | ❌         |
| Doctor  | Reports they uploaded + reports shared with them | ✅        |
| Admin   | All reports                                    | ✅         |

- Direct file URLs are **blocked** — files are served only via authenticated `/reports/:id/download`
- Doctors can explicitly share reports with other doctors via `/reports/:id/share`
- Soft-delete (isDeleted flag) — reports are never permanently lost

### API Security
- **Helmet.js** — secure HTTP headers
- **express-mongo-sanitize** — prevents NoSQL injection attacks
- **Rate limiting** — 200 req/15min globally, 20 req/15min on auth endpoints
- **Input validation** — express-validator on all write endpoints
- **CORS** — configurable origin whitelist
- **Role-based authorization** — `authorize('doctor','admin')` middleware on sensitive routes

---

## 📡 API Endpoints

### Auth (`/api/auth`)
```
POST /register              Register patient or doctor
POST /login                 Login → { accessToken, refreshToken, user }
POST /refresh               Rotate refresh token
POST /logout                Invalidate refresh token (single device)
POST /logout-all            Invalidate all refresh tokens
GET  /me                    Get current user (requires Bearer token)
```

### Users (`/api/users`)
```
GET  /profile               Get own profile
PUT  /profile               Update name, phone, healthProfile, etc.
POST /change-password       Change password (invalidates all sessions)
```

### Doctors (`/api/doctors`)
```
GET  /                      List doctors (filterable by specialization)
GET  /specializations       Get all specializations
GET  /:id                   Doctor detail
PATCH/:id/verify            Verify doctor license (admin only)
```

### Appointments (`/api/appointments`)
```
GET  /                      List (patient sees own, doctor sees theirs)
GET  /:id                   Detail (patient or doctor of that appt only)
POST /                      Book appointment (patient only)
PATCH/:id/status            Update status (cancel: patient/doctor; confirm: doctor)
DELETE /:id                 Remove (patient/admin)
```

### Reports (`/api/reports`) 🔐
```
GET  /                      Filtered list based on role
GET  /:id                   Detail (access-controlled)
GET  /:id/download          Download file (access-controlled, authenticated)
POST /                      Upload report (doctor/admin only)
PATCH/:id                   Update report (uploader/admin)
DELETE/:id                  Soft delete (uploader/admin)
POST /:id/share             Share with additional doctor
```

### Medicines (`/api/medicines`)
```
GET  /                      List with search & category filter + pagination
GET  /categories            All categories
GET  /:id                   Medicine detail
POST /                      Create (admin only)
PUT  /:id                   Update (admin only)
```

### Orders (`/api/orders`)
```
GET  /                      User's orders (admin sees all)
GET  /:id                   Order detail (owner/admin)
POST /                      Place order (validates stock)
```

---

## 📱 Frontend Features

| Screen | Features |
|--------|----------|
| **Splash** | Animated logo + fade transition |
| **Onboarding** | 3-slide carousel, skip button |
| **Login** | Email/password, error banner, token auto-refresh interceptor |
| **Register** | Patient/Doctor role selector, doctor license fields |
| **Dashboard** | Greeting, health vitals, quick actions, upcoming appointment, recent reports |
| **Appointments** | Tabbed (Upcoming/Past/Cancelled), live doctor list, date+time picker, cancel/confirm |
| **Reports** | Role-aware (doctor sees upload button), search filter, summary stats, download |
| **Medicines** | Live search with debounce, category chips, grid with cart controls (qty +/-), cart badge |
| **Cart** | Item list with qty controls, subtotal, payment method selector, checkout |
| **Profile** | Health stats, doctor verification badge, edit sheet, logout |

---

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3, Provider, Dio, flutter_secure_storage |
| Backend | Node.js, Express.js |
| Database | MongoDB, Mongoose ODM |
| Auth | JWT (access + refresh tokens), bcrypt |
| File upload | Multer (disk storage) |
| Security | Helmet, express-mongo-sanitize, rate-limit, express-validator |
