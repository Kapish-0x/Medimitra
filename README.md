🏥 MediMitra — Full-Stack Healthcare App
MediMitra is a comprehensive healthcare ecosystem designed to bridge the gap between patients and medical professionals. By integrating real-time appointment scheduling, secure medical report management, and an on-demand pharmacy, MediMitra provides a seamless digital health experience.

📱 Frontend Features (Flutter)
The user interface is built for performance and accessibility:

Role-Aware Dashboards: Personalized views for Patients, Doctors, and Admins.

Smart Appointment System: Live doctor discovery with real-time slot selection and status tracking.

Digital Health Locker: Secure, search-optimized access to personal medical reports.

Integrated Pharmacy: In-app medicine browsing with category filtering, real-time cart management, and checkout functionality.

Auth Flow: Smooth onboarding with JWT-based session persistence and secure auto-token refreshing.

⚙️ Backend Features (Node.js & MongoDB)
A high-performance RESTful API powering the entire ecosystem:

Identity & Access Management: RBAC (Role-Based Access Control) ensures that only authorized users access sensitive medical data.

Secure File Handling: Reports are served via encrypted streams, never directly exposed via file URLs.

Database Reliability: Mongoose ODM models ensure data integrity across users, appointments, and medicine inventory.

API Security: Built-in rate limiting, input validation, and protection against NoSQL injection.

🛠 Tech Stack
Category	Technology
Mobile	Flutter 3 (Dart), Provider (State Management), Dio (Networking)
Backend	Node.js, Express.js
Database	MongoDB, Mongoose
Security	JWT (Access/Refresh Tokens), bcrypt, Helmet.js
File Storage	Multer (local disk storage with access control)
🔐 Security Focus
Security is the backbone of MediMitra:

Token Strategy: Access tokens are short-lived, while refresh tokens allow for seamless UX without compromising security.

Data Sanitization: Middleware strips malicious inputs before they reach the database.

Role-Based Enforcement: Every sensitive endpoint is guarded by custom auth middleware that checks user roles (Patient, Doctor, or Admin) before processing requests.

🚀 Quick Start & Installation
Clone the repo: git clone https://github.com/Kapish-0x/Medimitra.git

Setup Backend: Navigate to /backend, run npm install, and configure your .env.

Setup Frontend: Navigate to /frontend, run flutter pub get, and point your app_config.dart to your server.

Seed Database: Run node seed.js to create your initial Admin, Doctor, and Patient accounts.

Developed with a focus on security, scalability, and user-centric design.
