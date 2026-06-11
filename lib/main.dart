import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/router/app_router.dart';
import 'config/theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Show real error details instead of blank crash screen
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Container(
        color: const Color(0xFFFFF3F3),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              const Text('App Error — please share this with the developer:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Text(details.exceptionAsString(),
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
              const SizedBox(height: 8),
              Text(details.stack?.toString() ?? '',
                  style: const TextStyle(fontSize: 10, color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  };

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the router for navigation changes
    final goRouter = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'SBAC E-Loan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: goRouter,
      // Localization
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('bn'),
      ],
    );
  }
}

// Global theme provider
final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (ref) => ThemeNotifier(),
);

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system);

  void toggleTheme() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  void setTheme(ThemeMode mode) {
    state = mode;
  }
}
