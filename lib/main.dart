import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'core/constants/app_constants.dart';
import 'core/providers/theme_provider.dart';
import 'core/utils/app_localization.dart';
import 'features/matches/providers/matches_provider.dart';
import 'features/matches/screens/matches_screen.dart';
import 'features/teams/providers/teams_provider.dart';
import 'features/teams/screens/teams_screen.dart';
import 'features/tournaments/providers/tournaments_provider.dart';
import 'features/tournaments/screens/tournaments_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/favorites/providers/favorites_provider.dart';
import 'features/favorites/screens/favorites_screen.dart';
import 'core/widgets/black_splash_screen.dart';
import 'package:flutter/foundation.dart';

// Context olmadan Provider'a erişmek için global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Flutter logosu yerine siyah ekran göster
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge, overlays: []);

  // Sistem UI stilini ayarla
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Desteklenen yönlendirmeleri belirle (sadece dikey mod)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Dil sağlayıcı başlat
  final localeProvider = LocaleProvider();
  // Cihaz diline göre başlangıç dilini ayarla
  await localeProvider.loadSavedLocale();

  try {
    // Uygulamayı başlat
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: localeProvider),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => MatchesProvider()),
          ChangeNotifierProvider(create: (_) => TeamsProvider()),
          ChangeNotifierProvider(create: (_) => TournamentsProvider()),
          ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    logger.e('Uygulama başlatılırken hata: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, _) {
        return BlackSplashScreen(
          child: MaterialApp(
            navigatorKey: navigatorKey,
            title: 'CScore',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            locale: localeProvider.locale,
            localizationsDelegates: localizationsDelegates,
            supportedLocales: supportedLocales,
            home: const HomeScreen(),
          ),
        );
      },
    );
  }
}

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const MatchesScreen(),
    const TeamsScreen(),
    const TournamentsScreen(),
    const FavoritesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppConstants.accentColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_esports),
            label: 'Maçlar',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Takımlar'),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Turnuvalar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favoriler',
          ),
        ],
      ),
    );
  }
}
