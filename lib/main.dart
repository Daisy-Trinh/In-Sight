import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/api/api_client.dart';
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

  // Init store (generates anonUserId on first run)
  final store = AppStore();
  await store.init();

  // App key — set at build time via --dart-define=IN_SIGHT_APP_KEY=<key>
  // Must match the APP_KEY secret set in Cloudflare Worker.
  // Defaults to dev key so local `wrangler dev` works out of the box.
  const appKey = String.fromEnvironment(
    'IN_SIGHT_APP_KEY',
    defaultValue: 'dev-insightapp-2024-local',
  );

  // isProduction = true only when compiled in release/profile mode
  final apiClient = ApiClient(
    appKey: appKey,
    anonUserId: store.anonUserId,
    isProduction: const bool.fromEnvironment('dart.vm.product'),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: store),
        Provider<ApiClient>.value(value: apiClient),
      ],
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
