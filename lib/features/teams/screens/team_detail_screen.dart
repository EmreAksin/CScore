// Takım detay ekranı

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/team_model.dart';
import '../../../core/models/match_model.dart';
import '../providers/teams_provider.dart';
import '../../matches/providers/matches_provider.dart';
import '../../../core/utils/app_localization.dart';
import '../../matches/widgets/match_card.dart';
import '../../matches/screens/match_details_screen.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../../../core/extensions/country_code_extension.dart';
import '../../tournaments/screens/tournament_detail_screen.dart';
import '../../tournaments/providers/tournaments_provider.dart';

class TeamDetailScreen extends StatefulWidget {
  final int teamId;
  final String teamName;

  const TeamDetailScreen({
    super.key,
    required this.teamId,
    required this.teamName,
  });

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  TeamModel? _team;
  String? _error;
  bool _isAddingToFavorites = false;

  // Takımın maçları
  List<MatchModel> _liveMatches = [];
  List<MatchModel> _upcomingMatches = [];
  List<MatchModel> _pastMatches = [];
  bool _isLoadingMatches = false;
  String? _matchesError;

  // Sonsuz kaydırma için değişkenler
  bool _isLoadingMoreUpcoming = false;
  bool _isLoadingMorePast = false;
  bool _hasMoreUpcoming = true;
  bool _hasMorePast = true;
  int _upcomingPage = 1;
  int _pastPage = 1;
  final ScrollController _upcomingScrollController = ScrollController();
  final ScrollController _pastScrollController = ScrollController();

  // Tab Controllers
  late TabController _tabController;
  late TabController _matchesTabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _matchesTabController = TabController(length: 3, vsync: this);

    // Scroll controller'lara kaydırma dinleyicisi ekle
    _upcomingScrollController.addListener(_scrollListenerUpcoming);
    _pastScrollController.addListener(_scrollListenerPast);

    _loadTeamDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _matchesTabController.dispose();
    _upcomingScrollController.dispose();
    _pastScrollController.dispose();
    super.dispose();
  }

  // Yaklaşan maçlar için scroll listener
  void _scrollListenerUpcoming() {
    if (_upcomingScrollController.position.pixels >=
            _upcomingScrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMoreUpcoming &&
        _hasMoreUpcoming) {
      _loadMoreUpcomingMatches();
    }
  }

  // Geçmiş maçlar için scroll listener
  void _scrollListenerPast() {
    if (_pastScrollController.position.pixels >=
            _pastScrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMorePast &&
        _hasMorePast) {
      _loadMorePastMatches();
    }
  }

  Future<void> _loadTeamDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await Provider.of<TeamsProvider>(
        context,
        listen: false,
      ).getTeamDetails(widget.teamId);

      if (mounted) {
        setState(() {
          _team = result;
          _isLoading = false;
        });

        // Takım detayları yüklendikten sonra maçları yükle
        _loadTeamMatches();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });

        // Hata durumunda kullanıcıya bilgi ver
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalization.of(context).translate('team_details_load_error')}: $e',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: AppLocalization.of(context).translate('try_again'),
              onPressed: _loadTeamDetails,
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  // Takımın maçlarını yükle
  Future<void> _loadTeamMatches() async {
    setState(() {
      _isLoadingMatches = true;
      _matchesError = null;
      _upcomingPage = 1;
      _pastPage = 1;
      _hasMoreUpcoming = true;
      _hasMorePast = true;
    });

    try {
      final matchesProvider = Provider.of<MatchesProvider>(
        context,
        listen: false,
      );

      // Canlı, yaklaşan ve geçmiş maçları yükle
      final liveMatchesResult = await matchesProvider.getTeamMatches(
        widget.teamId,
        status: 'running',
      );

      final upcomingMatchesResult = await matchesProvider.getTeamMatches(
        widget.teamId,
        status: 'not_started',
        page: _upcomingPage,
      );

      final pastMatchesResult = await matchesProvider.getTeamMatches(
        widget.teamId,
        status: 'finished',
        page: _pastPage,
      );

      if (mounted) {
        setState(() {
          _liveMatches = liveMatchesResult;
          _upcomingMatches = upcomingMatchesResult;
          _pastMatches = pastMatchesResult;
          _isLoadingMatches = false;

          // Daha fazla veri var mı kontrol et
          _hasMoreUpcoming = upcomingMatchesResult.length >= 20;
          _hasMorePast = pastMatchesResult.length >= 20;

          // Sayfa numaralarını güncelle
          if (_hasMoreUpcoming) _upcomingPage++;
          if (_hasMorePast) _pastPage++;

          // Hangi tab'ın seçili olacağını belirle
          if (_liveMatches.isNotEmpty) {
            _matchesTabController.index = 0;
          } else if (_upcomingMatches.isNotEmpty) {
            _matchesTabController.index = 1;
          } else {
            _matchesTabController.index = 2;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _matchesError = e.toString();
          _isLoadingMatches = false;
        });
      }
    }
  }

  // Daha fazla yaklaşan maç yükle
  Future<void> _loadMoreUpcomingMatches() async {
    if (_isLoadingMoreUpcoming || !_hasMoreUpcoming) return;

    setState(() {
      _isLoadingMoreUpcoming = true;
    });

    try {
      final matchesProvider = Provider.of<MatchesProvider>(
        context,
        listen: false,
      );

      final moreMatches = await matchesProvider.getTeamMatches(
        widget.teamId,
        status: 'not_started',
        page: _upcomingPage,
      );

      if (mounted) {
        setState(() {
          if (moreMatches.isNotEmpty) {
            _upcomingMatches.addAll(moreMatches);
            _hasMoreUpcoming = moreMatches.length >= 20;
            if (_hasMoreUpcoming) _upcomingPage++;
          } else {
            _hasMoreUpcoming = false;
          }
          _isLoadingMoreUpcoming = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMoreUpcoming = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalization.of(context).translate('error_loading_matches'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Daha fazla geçmiş maç yükle
  Future<void> _loadMorePastMatches() async {
    if (_isLoadingMorePast || !_hasMorePast) return;

    setState(() {
      _isLoadingMorePast = true;
    });

    try {
      final matchesProvider = Provider.of<MatchesProvider>(
        context,
        listen: false,
      );

      final moreMatches = await matchesProvider.getTeamMatches(
        widget.teamId,
        status: 'finished',
        page: _pastPage,
      );

      if (mounted) {
        setState(() {
          if (moreMatches.isNotEmpty) {
            _pastMatches.addAll(moreMatches);
            _hasMorePast = moreMatches.length >= 20;
            if (_hasMorePast) _pastPage++;
          } else {
            _hasMorePast = false;
          }
          _isLoadingMorePast = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMorePast = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalization.of(context).translate('error_loading_matches'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final favoritesProvider = Provider.of<FavoritesProvider>(
      context,
      listen: false,
    );

    setState(() {
      _isAddingToFavorites = true;
    });

    try {
      final isFavorite = favoritesProvider.isTeamFavorite(widget.teamId);

      if (isFavorite) {
        await favoritesProvider.removeFavoriteTeam(widget.teamId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalization.of(
                  context,
                ).translate('team_removed_from_favorites'),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await favoritesProvider.addFavoriteTeam(widget.teamId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalization.of(
                  context,
                ).translate('team_added_to_favorites'),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalization.of(context).translate('error')}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToFavorites = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = Provider.of<FavoritesProvider>(
      context,
    ).isTeamFavorite(widget.teamId);

    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalization.of(context).translate('error_occurred'),
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadTeamDetails,
                      child: Text(
                        AppLocalization.of(context).translate('try_again'),
                      ),
                    ),
                  ],
                ),
              )
              : _team == null
              ? Center(
                child: Text(
                  AppLocalization.of(context).translate('no_team_found'),
                ),
              )
              : CustomScrollView(
                slivers: [
                  // App Bar
                  SliverAppBar(
                    expandedHeight: 200,
                    pinned: true,
                    title: Text(_team!.name),
                    actions: [
                      // Favori Ekle/Çıkar Butonu
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.star : Icons.star_border,
                          color: isFavorite ? Colors.amber : Colors.white,
                        ),
                        onPressed:
                            _isAddingToFavorites ? null : _toggleFavorite,
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppConstants.primaryColor,
                              AppConstants.primaryColor.withAlpha(204),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Arka plan grafik deseni
                            Positioned.fill(
                              child: Opacity(
                                opacity: 0.1,
                                child: Image.asset(
                                  'assets/images/pattern.png',
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, __, ___) => const SizedBox(),
                                ),
                              ),
                            ),
                            // Takım logosu
                            Center(
                              child:
                                  _team!.imageUrl != null
                                      ? Image.network(
                                        _team!.imageUrl!,
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (_, __, ___) => const Icon(
                                              Icons.sports_esports,
                                              size: 80,
                                              color: Colors.white70,
                                            ),
                                      )
                                      : const Icon(
                                        Icons.sports_esports,
                                        size: 80,
                                        color: Colors.white70,
                                      ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Takım bilgileri
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Takım adı ve kısaltması
                          Text(
                            _team!.name,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (_team!.acronym.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${AppLocalization.of(context).translate('team_acronym')}: ${_team!.acronym}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Tabbar
                  SliverToBoxAdapter(
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: Theme.of(context).colorScheme.primary,
                      labelColor: Theme.of(context).colorScheme.primary,
                      unselectedLabelColor: Theme.of(context).hintColor,
                      tabs: [
                        Tab(
                          text: AppLocalization.of(
                            context,
                          ).translate('team_info'),
                        ),
                        Tab(
                          text: AppLocalization.of(
                            context,
                          ).translate('matches'),
                        ),
                      ],
                    ),
                  ),

                  // Tab içerikleri
                  SliverFillRemaining(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Takım bilgileri tab'ı
                        _buildTeamInfoTab(),

                        // Maçlar tab'ı
                        _buildMatchesTab(),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildTeamInfoTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Oyun ve konum
            if (_team!.status != null) ...[
              _buildInfoRow(
                AppLocalization.of(context).translate('game'),
                _team!.status!,
              ),
            ],
            if (_team!.location != null) ...[
              _buildInfoRow(
                AppLocalization.of(context).translate('location'),
                _team!.location!,
              ),
            ],

            const SizedBox(height: 24),

            // Oyuncular
            if (_team!.players != null && _team!.players!.isNotEmpty) ...[
              Text(
                AppLocalization.of(context).translate('players'),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ..._team!.players!.map((player) => _buildPlayerCard(player)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesTab() {
    if (_isLoadingMatches) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_matchesError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalization.of(context).translate('error_loading_matches'),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTeamMatches,
              child: Text(AppLocalization.of(context).translate('try_again')),
            ),
          ],
        ),
      );
    }

    if (_liveMatches.isEmpty &&
        _upcomingMatches.isEmpty &&
        _pastMatches.isEmpty) {
      return Center(
        child: Text(AppLocalization.of(context).translate('no_matches_found')),
      );
    }

    // Maç türleri için TabBar
    return Column(
      children: [
        TabBar(
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).hintColor,
          controller: _matchesTabController,
          tabs: [
            Tab(
              icon: const Icon(
                Icons.fiber_manual_record,
                color: Colors.red,
                size: 12,
              ),
              text: AppLocalization.of(context).translate('live_matches'),
            ),
            Tab(
              icon: const Icon(Icons.schedule, size: 16),
              text: AppLocalization.of(context).translate('upcoming_matches'),
            ),
            Tab(
              icon: const Icon(Icons.done_all, size: 16),
              text: AppLocalization.of(context).translate('past_matches'),
            ),
          ],
        ),

        // Maç listeleri için TabBarView
        Expanded(
          child: TabBarView(
            controller: _matchesTabController,
            children: [
              // Canlı maçlar
              _liveMatches.isNotEmpty
                  ? ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _liveMatches.length,
                    itemBuilder:
                        (context, index) => GestureDetector(
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => MatchDetailsScreen(
                                        matchId: _liveMatches[index].id,
                                        matchModel: _liveMatches[index],
                                      ),
                                ),
                              ),
                          child: MatchCard(match: _liveMatches[index]),
                        ),
                  )
                  : Center(
                    child: Text(
                      AppLocalization.of(
                        context,
                      ).translate('no_live_matches_in_league'),
                    ),
                  ),

              // Yaklaşan maçlar
              _upcomingMatches.isNotEmpty
                  ? ListView.builder(
                    controller: _upcomingScrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount:
                        _upcomingMatches.length + (_hasMoreUpcoming ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _upcomingMatches.length) {
                        return _isLoadingMoreUpcoming
                            ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                            : const SizedBox();
                      }
                      return GestureDetector(
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => MatchDetailsScreen(
                                      matchId: _upcomingMatches[index].id,
                                      matchModel: _upcomingMatches[index],
                                    ),
                              ),
                            ),
                        child: MatchCard(match: _upcomingMatches[index]),
                      );
                    },
                  )
                  : Center(
                    child: Text(
                      AppLocalization.of(
                        context,
                      ).translate('no_upcoming_matches_in_league'),
                    ),
                  ),

              // Geçmiş maçlar
              _pastMatches.isNotEmpty
                  ? ListView.builder(
                    controller: _pastScrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _pastMatches.length + (_hasMorePast ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _pastMatches.length) {
                        return _isLoadingMorePast
                            ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                            : const SizedBox();
                      }
                      return GestureDetector(
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => MatchDetailsScreen(
                                      matchId: _pastMatches[index].id,
                                      matchModel: _pastMatches[index],
                                    ),
                              ),
                            ),
                        child: MatchCard(match: _pastMatches[index]),
                      );
                    },
                  )
                  : Center(
                    child: Text(
                      AppLocalization.of(
                        context,
                      ).translate('no_past_matches_in_league'),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (label == AppLocalization.of(context).translate('location'))
            Text(
              value.isEmpty ? '🌍' : value.toFlagEmoji(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 20, // Bayrak emojisini biraz daha büyük göster
              ),
            )
          else if (label ==
                  AppLocalization.of(context).translate('tournament') &&
              value.isNotEmpty)
            GestureDetector(
              onTap: () async {
                // Turnuva ID'sini almak için gerekli kodlar burada olacak
                final tournamentsProvider = Provider.of<TournamentsProvider>(
                  context,
                  listen: false,
                );

                // Tournament ID değeri match içinden ya da bir turnuva listesinden elde edilmeli
                // Bu örnekte sabit bir ID kullanacağız
                final tournamentId = int.tryParse(value.split(':').last.trim());
                if (tournamentId != null) {
                  // Turnuva detaylarını önceden getir
                  final tournament = await tournamentsProvider
                      .getTournamentDetails(tournamentId);

                  if (!mounted) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => TournamentDetailScreen(
                            tournamentId: tournamentId,
                            tournamentName: value,
                            preloadedTournament: tournament,
                          ),
                    ),
                  );
                }
              },
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            )
          else
            Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(PlayerModel player) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Oyuncu resmi
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(30),
              ),
              child:
                  player.imageUrl != null
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.network(
                          player.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              size: 30,
                              color: Colors.grey.shade400,
                            );
                          },
                        ),
                      )
                      : Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.grey.shade400,
                      ),
            ),
            const SizedBox(width: 16),
            // Oyuncu bilgileri
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          player.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      // Milliyeti göster, boş veya null ise dünya emojisi göster
                      Text(
                        player.nationality == null ||
                                player.nationality!.isEmpty
                            ? '🌍'
                            : player.nationality!.toFlagEmoji(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  if (player.firstName != null || player.lastName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${AppLocalization.of(context).translate('player_real_name')}: ${[player.firstName, player.lastName].where((s) => s != null && s.isNotEmpty).join(' ')}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (player.role != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${AppLocalization.of(context).translate('player_role')}: ${player.role!}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppConstants.accentColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
