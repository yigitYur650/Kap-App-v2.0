
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kap_app_front/l10n/app_localizations.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'core/navigation/router.dart';
import 'core/providers/shared_preferences_provider.dart';
import 'core/localization/custom_shadcn_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Environment-ready Supabase configuration variables
  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://placeholder.supabase.co',
  );
  const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'placeholder-anon-key',
  );

  print('SUPABASE_URL: $supabaseUrl');
  print('SUPABASE_ANON_KEY length: ${supabaseAnonKey.length}');
  if (supabaseAnonKey.length > 10) {
    print('SUPABASE_ANON_KEY prefix: ${supabaseAnonKey.substring(0, 10)}...');
  } else {
    print('SUPABASE_ANON_KEY value: $supabaseAnonKey');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseAnonKey,
  );

  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const KapApp(),
    ),
  );
}

const customDarkScheme = ColorScheme(
  brightness: Brightness.dark,
  background: Color(0xFF000000), // Solid Pitch Black
  foreground: Color(0xFFF9FAFB),
  card: Color(0xFF121414), // Level 1 dark surface
  cardForeground: Color(0xFFF9FAFB),
  popover: Color(0xFF030712),
  popoverForeground: Color(0xFFF9FAFB),
  primary: Color(0xFFE50914), // Crimson red
  primaryForeground: Color(0xFFFFFFFF),
  secondary: Color(0xFF1F2937),
  secondaryForeground: Color(0xFFF9FAFB),
  muted: Color(0xFF1F2937),
  mutedForeground: Color(0xFF9CA3AF),
  accent: Color(0xFF1F2937),
  accentForeground: Color(0xFFF9FAFB),
  destructive: Color(0xFF7F1D1D),
  destructiveForeground: Color(0xFFF9FAFB),
  border: Color(0xFF1F2937),
  input: Color(0xFF1F2937),
  ring: Color(0xFFD1D5DB),
  chart1: Color(0xFF2662D9),
  chart2: Color(0xFF2EB88A),
  chart3: Color(0xFFE88C30),
  chart4: Color(0xFFAF57DB),
  chart5: Color(0xFFE23670),
);

class KapApp extends ConsumerWidget {
  const KapApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return ShadcnApp.router(
      routerConfig: router,
      themeMode: ThemeMode.dark, // Enforce dark theme
      theme: ThemeData.dark(
        colorScheme: customDarkScheme,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        CustomShadcnLocalizationsDelegate(),
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('tr'),
      ],
    );
  }
}
