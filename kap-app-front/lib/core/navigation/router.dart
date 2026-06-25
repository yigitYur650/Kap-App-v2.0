import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kap_app_front/l10n/app_localizations.dart';

final goRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const _PlaceholderHomeScreen(),
    ),
  ],
);

class _PlaceholderHomeScreen extends StatelessWidget {
  const _PlaceholderHomeScreen();

  @override
  Widget build(BuildContext context) {
    // Localization usage to avoid hardcoded text
    final l10n = AppLocalizations.of(context);
    final title = l10n?.appTitle ?? 'Kap App';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: const Center(
        child: Placeholder(),
      ),
    );
  }
}
