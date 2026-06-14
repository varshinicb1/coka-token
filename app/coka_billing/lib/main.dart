import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/app_provider.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'config/firebase_config.dart';

final _log = Logger('main');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint(
      '[${record.level.name}] ${record.loggerName}: ${record.message}',
    );
    if (record.error != null) {
      debugPrint('  ERROR: ${record.error}');
      if (record.stackTrace != null) {
        debugPrint('  STACK: ${record.stackTrace}');
      }
    }
  });

  PlatformDispatcher.instance.onError = (error, stack) {
    _log.severe('Unhandled error', error, stack);
    return true;
  };

  try {
    if (FirebaseConfig.isConfigured) {
      await Firebase.initializeApp();
      _log.info('Firebase initialized');
    }
  } catch (e, st) {
    _log.warning('Firebase init failed (offline mode)', e, st);
  }

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
            builder: (context, child) => GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.noScaling,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: child!,
                ),
              ),
            ),
            home: Consumer<AppProvider>(
              builder: (context, prov, _) {
                if (!prov.isInitialized) return const SplashScreen();
                return prov.currentScreen == 'LOGIN'
                    ? const LoginScreen()
                    : DashboardScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
