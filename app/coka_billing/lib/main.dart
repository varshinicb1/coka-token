import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/app_provider.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'config/firebase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (FirebaseConfig.isConfigured) {
      await Firebase.initializeApp();
    }
  } catch (_) {}

  final provider = AppProvider();
  runApp(CokaBillingApp(provider: provider));
}

class CokaBillingApp extends StatelessWidget {
  final AppProvider provider;

  const CokaBillingApp({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: provider,
      child: Consumer<AppProvider>(
        builder: (context, appProv, _) {
          return MaterialApp(
            title: 'COKA Billing',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appProv.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: Consumer<AppProvider>(
              builder: (context, prov, _) {
                if (!prov.isInitialized) return const SplashScreen();
                return prov.currentScreen == 'LOGIN'
                    ? const LoginScreen()
                    : const DashboardScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
