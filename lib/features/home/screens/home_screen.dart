// Uygulamanın ana ekranı

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/utils/app_localization.dart';
import '../../matches/screens/matches_screen.dart';
import '../../teams/screens/teams_screen.dart';
import '../../favorites/screens/favorites_screen.dart';
import '../../../core/widgets/responsive_builder.dart';
import '../../tournaments/screens/tournaments_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Uygulama ekranları
  static final List<Widget> _screens = [
    const MatchesScreen(),
    const TeamsScreen(),
    const TournamentsScreen(),
    const FavoritesScreen(),
  ];

  // Ekran başlık anahtarları (çeviri için)
  static const List<String> _titleKeys = [
    'matches',
    'teams',
    'tournaments',
    'favorites',
  ];

  // Ekran ikonları
  static const List<IconData> _icons = [
    Icons.sports_esports,
    Icons.people,
    Icons.emoji_events,
    Icons.star,
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    // Sadeleştirilmiş AppBar
    final appBar = AppBar(
      elevation: 0,
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.all(4.0),
        child: AspectRatio(
          aspectRatio: 1.0,
          child: Image.asset(
            'assets/Saydam zeminde logo3000x3000.png',
            width: 32,
            height: 32,
            fit: BoxFit.contain,
          ),
        ),
      ),
      title: Text(
        AppLocalization.of(context).translate(_titleKeys[_selectedIndex]),
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        // Dil değiştirme butonu
        PopupMenuButton<String>(
          icon: const Icon(Icons.language, size: 20),
          tooltip: 'Dil Seçenekleri',
          onSelected: (String languageCode) {
            final localeProvider = Provider.of<LocaleProvider>(
              context,
              listen: false,
            );
            localeProvider.setLocale(languageCode);
          },
          itemBuilder: (BuildContext context) {
            return AppConstants.supportedLanguages.map((String code) {
              return PopupMenuItem<String>(
                value: code,
                child: Text(AppConstants.languageNames[code] ?? code),
              );
            }).toList();
          },
        ),
        // Tema değiştirme butonu
        IconButton(
          icon: Icon(
            themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            size: 20,
          ),
          onPressed: () {
            themeProvider.toggleTheme();
          },
          tooltip: themeProvider.isDarkMode ? 'Açık Tema' : 'Koyu Tema',
        ),
      ],
    );

    return ResponsiveBuilder(
      builder: (context, deviceScreenType, child) {
        // Tablet ve desktop için yan menü ile responsive tasarım
        if (deviceScreenType == DeviceScreenType.tablet ||
            deviceScreenType == DeviceScreenType.desktop) {
          return Scaffold(
            appBar: appBar,
            body: Row(
              children: [
                // Yan menü - daha minimal
                NavigationRail(
                  extended: deviceScreenType == DeviceScreenType.desktop,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemTapped,
                  minWidth: 56,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  selectedIconTheme: IconThemeData(
                    color: theme.colorScheme.primary,
                  ),
                  unselectedIconTheme: IconThemeData(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  selectedLabelTextStyle: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  unselectedLabelTextStyle: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                  destinations: List.generate(
                    _icons.length,
                    (index) => NavigationRailDestination(
                      icon: Icon(_icons[index]),
                      label: Text(
                        AppLocalization.of(
                          context,
                        ).translate(_titleKeys[index]),
                      ),
                    ),
                  ),
                ),
                // Ana içerik
                Expanded(child: _screens[_selectedIndex]),
              ],
            ),
          );
        }

        // Mobil için alt navigasyon barı
        return Scaffold(
          appBar: appBar,
          body: _screens[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: theme.colorScheme.primary,
            unselectedItemColor: theme.colorScheme.onSurfaceVariant,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            items: List.generate(
              _icons.length,
              (index) => BottomNavigationBarItem(
                icon: Icon(_icons[index]),
                label: AppLocalization.of(context).translate(_titleKeys[index]),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
