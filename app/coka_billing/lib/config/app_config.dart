class AppConfig {
  static const String appName = 'COKA Billing';
  static const String appVersion = '1.0.0';
  static const String companyName = 'COKA - Coimbatore Original Kaalan Adda';
  static const String appTagline = 'Coimbatore Original Kaalan Adda';
  
  // Demo credentials (for offline/local mode)
  static const String demoAdminEmail = 'admin@coka.com';
  static const String demoAdminPassword = 'password123';
  static const String demoStaffEmail = 'staff@coka.com';
  static const String demoStaffPassword = 'password123';
  
  // Tax rate
  static const double taxRate = 0.05; // 5% GST

  // Default printer settings (58mm / 48mm print width)
  static const int printerDpi = 203;
  static const double paperWidthMM = 58.0;
}
