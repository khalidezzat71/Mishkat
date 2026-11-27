import 'package:flutter/material.dart';
import 'package:mishkat/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/athkar/presentation/athkar_screen.dart';
import '../features/memorization/presentation/memorization_screen.dart';
import '../features/memorization/presentation/recitation_screen.dart';
import '../features/prayer/presentation/prayer_screen.dart';
import '../features/quran/presentation/quran_screen.dart';
import '../features/quran/presentation/reciters_screen.dart';
import '../features/settings/presentation/advanced_settings_screen.dart';
import '../features/settings/presentation/backup_screen.dart';
import '../features/settings/presentation/diagnostics_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/settings/presentation/sources_screen.dart';
import '../features/settings/presentation/stats_screen.dart';
import '../core/theme_layouts/layout_registry.dart';
import 'providers.dart';

final appRouter = GoRouter(
  initialLocation: '/prayer',
  routes: [
    ShellRoute(
      builder: (context, state, child) => NavigationShell(child: child),
      routes: [
        GoRoute(
          path: '/prayer',
          builder: (context, state) => const PrayerScreen(),
        ),
        GoRoute(
          path: '/quran',
          builder: (context, state) => const QuranScreen(),
        ),
        GoRoute(
          path: '/memorization',
          builder: (context, state) => const MemorizationScreen(),
        ),
        GoRoute(
          path: '/recitation',
          builder: (context, state) => const RecitationScreen(),
        ),
        GoRoute(
          path: '/athkar',
          builder: (context, state) => const AthkarScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/sources',
          builder: (context, state) => const SourcesScreen(),
        ),
        GoRoute(
          path: '/diagnostics',
          builder: (context, state) => const DiagnosticsScreen(),
        ),
        GoRoute(
          path: '/advanced',
          builder: (context, state) => const AdvancedSettingsScreen(),
        ),
        GoRoute(
          path: '/reciters',
          builder: (context, state) => const RecitersScreen(),
        ),
        GoRoute(
          path: '/stats',
          builder: (context, state) => const StatsScreen(),
        ),
        GoRoute(
          path: '/backup',
          builder: (context, state) => const BackupScreen(),
        ),
      ],
    ),
  ],
);

class NavigationShell extends ConsumerWidget {
  const NavigationShell({required this.child, super.key});

  final Widget child;

  int _indexFor(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/quran') || location.startsWith('/reciters')) {
      return 1;
    }
    if (location.startsWith('/memorization') ||
        location.startsWith('/recitation')) {
      return 2;
    }
    if (location.startsWith('/athkar')) return 3;
    if (location.startsWith('/settings') ||
        location.startsWith('/advanced') ||
        location.startsWith('/sources') ||
        location.startsWith('/diagnostics') ||
        location.startsWith('/stats') ||
        location.startsWith('/backup')) {
      return 4;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final layoutId = ref.watch(layoutIdProvider);
    final layout = kLayouts.firstWhere(
      (item) => item.id == layoutId,
      orElse: () => kLayouts.first,
    );
    final scale = switch (layout.density) {
      2 => 1.2,
      1 => 0.95,
      _ => 1.0,
    };
    final body = MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: child,
    );

    Widget? navigation;
    if (layout.navigationStyle != NavigationStyle.none) {
      navigation = NavigationBar(
        selectedIndex: _indexFor(context),
        onDestinationSelected: (index) => switch (index) {
          0 => context.go('/prayer'),
          1 => context.go('/quran'),
          2 => context.go('/memorization'),
          3 => context.go('/athkar'),
          _ => context.go('/settings'),
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.access_time_outlined),
            label: l10n.navPrayer,
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            label: l10n.navQuran,
          ),
          NavigationDestination(
            icon: const Icon(Icons.school_outlined),
            label: l10n.navMemorization,
          ),
          NavigationDestination(
            icon: const Icon(Icons.spa_outlined),
            label: l10n.navAthkar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            label: l10n.navSettings,
          ),
        ],
      );
    }

    if (layout.navigationStyle == NavigationStyle.topTabs) {
      return Scaffold(
        body: Column(
          children: [
            navigation!,
            Expanded(child: body),
          ],
        ),
      );
    }
    if (layout.navigationStyle == NavigationStyle.floatingDock) {
      return Scaffold(
        body: body,
        floatingActionButton: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: navigation,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      );
    }
    if (layout.navigationStyle == NavigationStyle.none) {
      return Scaffold(
        body: body,
        drawer: Drawer(
          child: ListView(
            children: [
              for (final route in [
                ('/prayer', l10n.navPrayer),
                ('/quran', l10n.navQuran),
                ('/memorization', l10n.navMemorization),
                ('/athkar', l10n.navAthkar),
                ('/settings', l10n.navSettings),
              ])
                ListTile(
                  title: Text(route.$2),
                  onTap: () {
                    context.go(route.$1);
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        ),
      );
    }
    return Scaffold(body: body, bottomNavigationBar: navigation);
  }
}
