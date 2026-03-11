require('dotenv').config();
const mongoose = require('mongoose');
const Medicine = require('./models/Medicine.model');
const User     = require('./models/User.model');

const medicines = [
  { name: 'Metformin 500mg',       brand: 'Glucophage',  genericName: 'Metformin HCl',        category: 'Diabetes',    price: 149, originalPrice: 200, unit: 'strip',  quantityPerUnit: 10, stock: 200, requiresPrescription: true,  manufacturer: 'Sun Pharma' },
  { name: 'Vitamin D3 2000IU',     brand: 'HealthVit',   genericName: 'Cholecalciferol',       category: 'Vitamins',    price: 299, originalPrice: 399, unit: 'bottle', quantityPerUnit: 60, stock: 150, requiresPrescription: false, manufacturer: 'HealthVit Labs' },
  { name: 'Atorvastatin 10mg',     brand: 'Lipitor',     genericName: 'Atorvastatin',          category: 'Cardiac',     price: 189, originalPrice: 250, unit: 'strip',  quantityPerUnit: 10, stock: 100, requiresPrescription: true,  manufacturer: 'Pfizer' },
  { name: 'Amoxicillin 500mg',     brand: 'Mox',         genericName: 'Amoxicillin',           category: 'Antibiotics', price: 89,  originalPrice: 120, unit: 'strip',  quantityPerUnit: 10, stock: 180, requiresPrescription: true,  manufacturer: 'Ranbaxy' },
  { name: 'Paracetamol 650mg',     brand: 'Crocin',      genericName: 'Paracetamol',           category: 'Pain Relief', price: 35,  originalPrice: 50,  unit: 'strip',  quantityPerUnit: 15, stock: 500, requiresPrescription: false, manufacturer: 'GSK' },
  { name: 'Omega-3 Fish Oil 1000mg',brand: 'NutriOmega', genericName: 'Omega-3 Fatty Acids',   category: 'Vitamins',    price: 449, originalPrice: 599, unit: 'bottle', quantityPerUnit: 90, stock: 80,  requiresPrescription: false, manufacturer: 'NutriVit' },
  { name: 'Amlodipine 5mg',        brand: 'Norvasc',     genericName: 'Amlodipine Besylate',   category: 'Cardiac',     price: 210, originalPrice: 280, unit: 'strip',  quantityPerUnit: 10, stock: 120, requiresPrescription: true,  manufacturer: 'Cipla' },
  { name: 'Ibuprofen 400mg',       brand: 'Brufen',      genericName: 'Ibuprofen',             category: 'Pain Relief', price: 55,  originalPrice: 80,  unit: 'strip',  quantityPerUnit: 10, stock: 300, requiresPrescription: false, manufacturer: 'Abbott' },
  { name: 'Cetirizine 10mg',       brand: 'Zyrtec',      genericName: 'Cetirizine HCl',        category: 'Other',       price: 65,  originalPrice: 90,  unit: 'strip',  quantityPerUnit: 10, stock: 200, requiresPrescription: false, manufacturer: 'UCB' },
  { name: 'Vitamin B Complex',     brand: 'Becosules',   genericName: 'B-Complex Vitamins',    category: 'Vitamins',    price: 180, originalPrice: 220, unit: 'bottle', quantityPerUnit: 30, stock: 120, requiresPrescription: false, manufacturer: 'Pfizer' },
];

const seed = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Connected');

    await Medicine.deleteMany({});
    await Medicine.insertMany(medicines);
    console.log(`✅ Seeded ${medicines.length} medicines`);

    const users = [
      { name: 'Admin',         email: 'admin@medimitra.com',  password: 'Admin@123',  role: 'admin',   isEmailVerified: true },
      { name: 'Dr. Priya Nair',email: 'doctor@medimitra.com', password: 'Doctor@123', role: 'doctor',  specialization: 'Cardiologist',   licenseNumber: 'KA-MED-12345', hospitalAffiliation: 'Apollo Hospitals', isVerifiedDoctor: true, isEmailVerified: true },
      { name: 'Dr. Kiran Mehta',email:'kiran@medimitra.com',  password: 'Doctor@123', role: 'doctor',  specialization: 'Dermatologist',  licenseNumber: 'KA-MED-67890', hospitalAffiliation: 'Fortis Hospital',  isVerifiedDoctor: true, isEmailVerified: true },
      { name: 'Arjun Sharma',  email: 'arjun@medimitra.com',  password: 'Patient@123',role: 'patient', isEmailVerified: true, healthProfile: { bloodGroup: 'A+', height: 178, weight: 72 } },
    ];

    for (const u of users) {
      const exists = await User.findOne({ email: u.email });
      if (!exists) { await User.create(u); console.log(`✅ Created: ${u.email}`); }
      else console.log(`⚠️  Exists: ${u.email}`);
    }

    console.log('\n🎉 Seed complete!');
    console.log('   admin@medimitra.com   / Admin@123');
    console.log('   doctor@medimitra.com  / Doctor@123');
    console.log('   arjun@medimitra.com   / Patient@123');
    process.exit(0);
  } catch (err) {
    console.error('❌', err);
    process.exit(1);
  }
};

seed();
