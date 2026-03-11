class AppConfig {
  static const String baseUrl = 'http://192.168.137.139:5000/api'; // Android emulator
  // For iOS simulator use: 'http://localhost:5000/api'
  // For real device use your machine's IP: 'http://192.168.x.x:5000/api'

  static const String appName = 'Medimitra';
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;
}

class ApiEndpoints {
  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String logoutAll = '/auth/logout-all';
  static const String refreshToken = '/auth/refresh';
  static const String me = '/auth/me';

  // Users
  static const String profile = '/users/profile';
  static const String changePassword = '/users/change-password';

  // Appointments
  static const String appointments = '/appointments';

  // Reports
  static const String reports = '/reports';

  // Medicines
  static const String medicines = '/medicines';
  static const String medicineCategories = '/medicines/categories';

  // Orders
  static const String orders = '/orders';

  // Doctors
  static const String doctors = '/doctors';
  static const String specializations = '/doctors/specializations';
}
