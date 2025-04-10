// Favoriler ekranı

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/app_localization.dart';
import '../../teams/providers/teams_provider.dart';
import '../../teams/screens/team_detail_screen.dart';
import '../../../core/models/team_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/logger.dart';
import '../providers/favorites_provider.dart';
import '../../../core/extensions/country_code_extension.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _isLoadingTeams = false;
  List<TeamModel> _favoriteTeams = [];

  @override
  void initState() {
    super.initState();

    // Favorileri hemen yükle
    _loadFavorites();

    // Ekstra güvenlik için kısa bir süre sonra tekrar yükle
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _favoriteTeams.isEmpty) {
        _loadFavorites();
      }
    });
  }

  // Favorileri yükle
  Future<void> _loadFavorites() async {
    if (!mounted) return;

    setState(() {
      _isLoadingTeams = true;
    });

    final favoritesProvider = Provider.of<FavoritesProvider>(
      context,
      listen: false,
    );
    final teamsProvider = Provider.of<TeamsProvider>(context, listen: false);

    final favoriteTeamIds = favoritesProvider.favoriteTeamIds;

    try {
      if (favoriteTeamIds.isEmpty) {
        if (mounted) {
          setState(() {
            _favoriteTeams = [];
            _isLoadingTeams = false;
          });
        }
        return;
      }

      final teams = <TeamModel>[];
      for (var teamId in favoriteTeamIds) {
        try {
          if (!mounted) return;

          final team = await teamsProvider.getTeamDetails(teamId);
          if (team != null && mounted) {
            teams.add(team);
          }
        } catch (e) {
          Logger.error('Takım $teamId yüklenirken hata: $e');
          // Hata durumunda devam et
          continue;
        }
      }

      if (mounted) {
        setState(() {
          _favoriteTeams = teams;
          _isLoadingTeams = false;
        });
        // Favori takımları provider'a da bildir
        favoritesProvider.updateFavoriteTeams(teams);
      }
    } catch (e) {
      Logger.error('Takımlar yüklenirken genel hata: $e');
      if (mounted) {
        setState(() {
          _isLoadingTeams = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar'ı kaldırıyorum, ana ekrandaki başlık yeterli
      // appBar: AppBar(
      //   title: Text(AppLocalization.of(context).translate('favorites')),
      //   elevation: 0,
      // ),
      body: RefreshIndicator(
        onRefresh: _loadFavorites,
        child: _buildFavoriteContent(),
      ),
    );
  }

  // Favori takımlar içeriği
  Widget _buildFavoriteContent() {
    final favoriteTeamIds =
        Provider.of<FavoritesProvider>(context).favoriteTeamIds;

    if (_isLoadingTeams) {
      return const Center(child: CircularProgressIndicator());
    }

    if (favoriteTeamIds.isEmpty) {
      return _buildEmptyFavoritesMessage();
    }

    if (_favoriteTeams.isEmpty) {
      // Eğer ID'ler var ama takımlar yüklenemedi ise yeniden yükleme butonu göster
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalization.of(context).translate('no_data'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadFavorites,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalization.of(context).translate('try_again')),
            ),
          ],
        ),
      );
    }

    // Favori takımları gelişmiş kartlar halinde listele
    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: _favoriteTeams.length,
      itemBuilder: (context, index) {
        final team = _favoriteTeams[index];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => TeamDetailScreen(
                        teamId: team.id,
                        teamName: team.name,
                      ),
                ),
              ).then((_) => _loadFavorites()); // Geri döndüğünde yeniden yükle
            },
            child: Column(
              children: [
                // Takım banner bölümü
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Container(
                    height: 80,
                    width: double.infinity,
                    color: AppConstants.primaryColor.withAlpha(25),
                    child: Center(
                      child:
                          team.imageUrl != null
                              ? Image.network(
                                team.imageUrl!,
                                height: 60,
                                fit: BoxFit.contain,
                                errorBuilder:
                                    (context, error, stackTrace) => const Icon(
                                      Icons.sports_esports,
                                      size: 40,
                                    ),
                              )
                              : const Icon(Icons.sports_esports, size: 40),
                    ),
                  ),
                ),
                // Takım bilgileri
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              team.name,
                              style: Theme.of(context).textTheme.titleLarge!
                                  .copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (team.location != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  team.location!.isEmpty
                                      ? '🌍'
                                      : team.location!.toFlagEmoji(),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontSize: 20),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Consumer<FavoritesProvider>(
                        builder: (context, favoritesProvider, _) {
                          return IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await favoritesProvider.removeFavoriteTeam(
                                team.id,
                              );
                              _loadFavorites();
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Favoriler boşsa gösterilecek mesaj
  Widget _buildEmptyFavoritesMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_border, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            AppLocalization.of(context).translate('no_favorites'),
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalization.of(context).translate('add_teams_to_favorites'),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
