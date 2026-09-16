import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Backend configurations and Firebase initialization
import 'firebase_options.dart';
import 'backend/controllers/AuthController.dart';
import 'backend/controllers/NotificationController.dart';
import 'backend/controllers/OrderController.dart';
import 'backend/controllers/PackageController.dart';
import 'backend/controllers/ProfileController.dart';
import 'backend/controllers/ReviewController.dart';
import 'backend/controllers/AdminController.dart';

// Frontend configurations, theme, and UI controllers
import 'package:save_a_bite/features/customer/controllers/customer_controller.dart';
import 'package:save_a_bite/core/theme/theme_provider.dart';
import 'package:save_a_bite/features/auth/screens/login_screen.dart';

/// A proxy helper class enabling Provider to manage state for the AdminController mixin.
class AdminProvider extends ChangeNotifier with AdminController {}

/// Application entry point function.
///
/// Initializes Flutter bindings, loads environment configuration variables,
/// initializes Firebase services, and mounts the root MultiProvider tree.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load secure environment variables from .env file before app startup
  await dotenv.load(fileName: ".env");

  // Initialize Firebase services using platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        // Frontend UI state management providers
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CustomerController()),

        // Backend logic and repository state management providers
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => NotificationController()),
        ChangeNotifierProvider(create: (_) => OrderController()),
        ChangeNotifierProvider(create: (_) => PackageController()),
        ChangeNotifierProvider(create: (_) => ProfileController()),
        ChangeNotifierProvider(create: (_) => ReviewController()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: const SaveABiteApp(),
    ),
  );
}

/// Root application widget configuring global themes, RTL localization, and initial routing.
class SaveABiteApp extends StatelessWidget {
  const SaveABiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to theme mode changes dynamically
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Save A Bite',
      debugShowCheckedModeBanner: false,

      // Theme configuration settings
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(),

      // Localization and RTL layout support setup
      locale: const Locale('he', 'IL'),
      supportedLocales: const [
        Locale('he', 'IL'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Initial authentication entry point screen
      home: const LoginScreen(),
    );
  }
}
