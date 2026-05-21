import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/home/home_page.dart';
import '../../features/chat/chat_page.dart';
import '../../features/journey/journey_page.dart';
import '../../features/settings/settings_page.dart';
import '../../shared/models/persona.dart';
import '../store/app_store.dart';

/// App router — GoRouter với named routes
class AppRouter {
  static const splash = '/';
  static const personaSelect = '/persona';
  static const chat = '/chat';
  static const journey = '/journey';
  static const settings = '/settings';

  static GoRouter router(AppStore store) => GoRouter(
        initialLocation: splash,
        redirect: (context, state) {
          // Nếu chưa onboard → luôn về splash
          if (!store.hasOnboarded &&
              state.matchedLocation != splash &&
              state.matchedLocation != personaSelect) {
            return splash;
          }
          return null;
        },
        routes: [
          GoRoute(
            path: splash,
            builder: (context, state) => const SplashPage(),
          ),
          GoRoute(
            path: personaSelect,
            builder: (context, state) => const PersonaSelectPage(),
          ),
          ShellRoute(
            builder: (context, state, child) => AppShell(child: child),
            routes: [
              GoRoute(
                path: chat,
                builder: (context, state) {
                  final persona = state.extra as Persona?;
                  return ChatPage(initialPersona: persona);
                },
              ),
              GoRoute(
                path: journey,
                builder: (context, state) => const JourneyPage(),
              ),
              GoRoute(
                path: settings,
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      );
}

/// Shell — bottom nav bar + persistent layout
class AppShell extends StatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const _routes = [
    AppRouter.chat,
    AppRouter.journey,
    AppRouter.settings,
  ];

  void _onDestinationSelected(int index) {
    setState(() => _selectedIndex = index);
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories_rounded),
            label: 'Hành trình',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}
