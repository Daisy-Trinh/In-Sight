import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/store/app_store.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait (mobile)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Init store
  final store = AppStore();
  await store.init();

  runApp(
    ChangeNotifierProvider.value(
      value: store,
      child: const InSightApp(),
    ),
  );
}

class InSightApp extends StatelessWidget {
  const InSightApp({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();

    // Router depends on store state (onboarded flag)
    final router = AppRouter.router(store);

    return MaterialApp.router(
      title: 'In-Sight',
      debugShowCheckedModeBanner: false,

      // Theme — switch based on store.isDarkMode
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: store.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // Routing
      routerConfig: router,
    );
  }
}
