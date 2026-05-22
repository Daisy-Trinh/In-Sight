import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
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

/// InSightApp MUST be a StatefulWidget so that the GoRouter is created
/// exactly once in initState().
///
/// If it were a StatelessWidget, every store.notifyListeners() call (e.g.
/// consumeToken) would trigger build(), which would call AppRouter.router()
/// again, producing a brand-new GoRouter with initialLocation: '/' — causing
/// the app to navigate back to Splash on every token consume. (DEFECT-WEB-01)
class InSightApp extends StatefulWidget {
  const InSightApp({super.key});

  @override
  State<InSightApp> createState() => _InSightAppState();
}

class _InSightAppState extends State<InSightApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Read store once — the redirect closure holds a reference, so it always
    // sees the current store state even though the router is never recreated.
    final store = context.read<AppStore>();
    _router = AppRouter.router(store);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // watch() only for fields that legitimately need reactive updates.
    // It no longer recreates the router.
    final store = context.watch<AppStore>();

    return MaterialApp.router(
      title: 'In-Sight',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: store.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: _router,
    );
  }
}
