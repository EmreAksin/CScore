// Maçlar ekranı

import 'package:cscore/features/favorites/providers/favorites_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/models/match_model.dart';
import '../../../core/utils/app_localization.dart';
import '../providers/matches_provider.dart';
import 'league_detail_screen.dart';
import 'match_details_screen.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/cached_image.dart';

// Takım hizalama enum'u
enum TeamAlignment { left, right }

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  List<String> _selectedTiers = [];
  final TextEditingController _searchController = TextEditingController();

  // Kaydırma kontrolcüleri
  final ScrollController _liveScrollController = ScrollController();
  final ScrollController _upcomingScrollController = ScrollController();
  final ScrollController _pastScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Maç verilerini yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<MatchesProvider>(context, listen: false);
      provider.getLiveMatches();
      provider.getUpcomingMatches();
      provider.getPastMatches(targetCount: 200);

      // Scroll dinleyicileri ekle
      _setupScrollListeners(provider);
    });
  }

  // Scroll yöneticileri
  void _setupScrollListeners(MatchesProvider provider) {
    // Yaklaşan maçlar için scroll
    _upcomingScrollController.addListener(() {
      if (_upcomingScrollController.position.pixels >=
          _upcomingScrollController.position.maxScrollExtent - 500) {
        if (!provider.isLoadingMoreUpcoming &&
            provider.hasMoreUpcomingMatches) {
          provider.getUpcomingMatches(refresh: false);
        }
      }
    });

    // Tamamlanan maçlar için scroll
    _pastScrollController.addListener(() {
      if (_pastScrollController.position.pixels >=
          _pastScrollController.position.maxScrollExtent - 500) {
        if (!provider.isLoadingMorePast && provider.hasMorePastMatches) {
          provider.getPastMatches(refresh: false);
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _liveScrollController.dispose();
    _upcomingScrollController.dispose();
    _pastScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchesProvider = Provider.of<MatchesProvider>(context);

    // MatchesProvider'ın durumunu takip ederek yükleme ekranını güncelle
    if (matchesProvider.liveMatchesStatus == MatchesStatus.loading &&
        matchesProvider.liveMatches.isEmpty) {
      return const Center(child: LoadingWidget());
    }

    if (matchesProvider.liveMatchesStatus == MatchesStatus.error &&
        matchesProvider.liveMatches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalization.of(context).translate('live_matches_error'),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalization.of(context).translate('try_again')),
              onPressed: () {
                matchesProvider.getLiveMatches();
              },
            ),
          ],
        ),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.hintColor,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: [
            Tab(text: AppLocalization.of(context).translate('live_matches')),
            Tab(
              text: AppLocalization.of(context).translate('upcoming_matches'),
            ),
            Tab(text: AppLocalization.of(context).translate('past_matches')),
          ],
        ),
      ),
      body: Column(
        children: [
          // Arama ve filtreleme alanı
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppLocalization.of(context).translate('search_team'),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Tier filtreleme çipleri
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('S', 'S Tier'),
                  const SizedBox(width: 8),
                  _buildFilterChip('A', 'A Tier'),
                  const SizedBox(width: 8),
                  _buildFilterChip('B', 'B Tier'),
                  const SizedBox(width: 8),
                  _buildFilterChip('C', 'C Tier'),
                  const SizedBox(width: 8),
                  _buildFilterChip('D', 'D Tier'),
                  const SizedBox(width: 8),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedTiers = [];
                      });
                    },
                    icon: const Icon(Icons.clear_all),
                    label: Text(
                      AppLocalization.of(context).translate('clear_filters'),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Maç listeleri
          Expanded(
            child: Consumer<MatchesProvider>(
              builder: (context, provider, child) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    // CANLI MAÇLAR
                    _buildLiveMatchesTab(context, provider),

                    // YAKLAŞAN MAÇLAR
                    _buildUpcomingMatchesTab(context, provider),

                    // TAMAMLANAN MAÇLAR
                    _buildPastMatchesTab(context, provider),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Tier filtre çipi
  Widget _buildFilterChip(String tier, String label) {
    final isSelected = _selectedTiers.contains(tier);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedTiers.add(tier);
          } else {
            _selectedTiers.remove(tier);
          }
        });
      },
      showCheckmark: false,
      avatar: isSelected ? const Icon(Icons.check, size: 16) : null,
    );
  }

  // Maçları filtrele
  List<MatchModel> _filterMatches(List<MatchModel> matches) {
    // Önce arama filtresi
    var filteredMatches =
        matches.where((match) {
          final team1Name = match.opponent1?.name.toLowerCase() ?? '';
          final team2Name = match.opponent2?.name.toLowerCase() ?? '';
          return team1Name.contains(_searchQuery) ||
              team2Name.contains(_searchQuery);
        }).toList();

    // Sonra tier filtresi (seçili tier yoksa hepsini göster)
    if (_selectedTiers.isNotEmpty) {
      filteredMatches =
          filteredMatches.where((match) {
            final tier = match.tournament?.tier?.toUpperCase() ?? '';
            return _selectedTiers.contains(tier);
          }).toList();
    }

    return filteredMatches;
  }

  // CANLI MAÇLAR
  Widget _buildLiveMatchesTab(BuildContext context, MatchesProvider provider) {
    if (provider.liveMatchesStatus == MatchesStatus.loading &&
        provider.liveMatches.isEmpty) {
      return const Center(child: LoadingWidget());
    }

    if (provider.liveMatchesStatus == MatchesStatus.error) {
      return ErrorDisplayWidget(
        title: AppLocalization.of(context).translate('error_occurred'),
        message: provider.liveMatchesError,
        onRetry: () => provider.getLiveMatches(),
      );
    }

    final filteredMatches = _filterMatches(provider.liveMatches);

    if (filteredMatches.isEmpty) {
      if (provider.liveMatches.isEmpty) {
        return Center(
          child: Text(
            AppLocalization.of(context).translate('no_data'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        );
      } else {
        return Center(
          child: Text(
            AppLocalization.of(context).translate('no_match_filter'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        );
      }
    }

    return RefreshIndicator(
      onRefresh: () => provider.getLiveMatches(),
      child: ListView.builder(
        controller: _liveScrollController,
        itemCount: filteredMatches.length,
        padding: const EdgeInsets.all(8.0),
        itemBuilder: (context, index) {
          return _buildMatchCard(context, filteredMatches[index]);
        },
      ),
    );
  }

  // YAKLAŞAN MAÇLAR
  Widget _buildUpcomingMatchesTab(
    BuildContext context,
    MatchesProvider provider,
  ) {
    if (provider.upcomingMatchesStatus == MatchesStatus.loading &&
        provider.upcomingMatches.isEmpty) {
      return const Center(child: LoadingWidget());
    }

    if (provider.upcomingMatchesStatus == MatchesStatus.error) {
      return ErrorDisplayWidget(
        title: AppLocalization.of(context).translate('error_occurred'),
        message: provider.upcomingMatchesError,
        onRetry: () => provider.getUpcomingMatches(),
      );
    }

    final filteredMatches = _filterMatches(provider.upcomingMatches);

    if (filteredMatches.isEmpty) {
      if (provider.upcomingMatches.isEmpty) {
        return Center(
          child: Text(
            AppLocalization.of(context).translate('no_data'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        );
      } else {
        return Center(
          child: Text(
            AppLocalization.of(context).translate('no_match_filter'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        );
      }
    }

    return RefreshIndicator(
      onRefresh: () => provider.getUpcomingMatches(refresh: true),
      child: ListView.builder(
        controller: _upcomingScrollController,
        itemCount:
            filteredMatches.length +
            (provider.isLoadingMoreUpcoming || provider.hasMoreUpcomingMatches
                ? 1
                : 0),
        padding: const EdgeInsets.all(8.0),
        itemBuilder: (context, index) {
          if (index == filteredMatches.length) {
            // Sayfa sonunda loading gösterici
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child:
                    provider.isLoadingMoreUpcoming
                        ? const CircularProgressIndicator()
                        : TextButton(
                          onPressed:
                              () => provider.getUpcomingMatches(refresh: false),
                          child: Text(
                            AppLocalization.of(context).translate('load_more'),
                          ),
                        ),
              ),
            );
          }
          return _buildMatchCard(context, filteredMatches[index]);
        },
      ),
    );
  }

  // TAMAMLANAN MAÇLAR
  Widget _buildPastMatchesTab(BuildContext context, MatchesProvider provider) {
    if (provider.pastMatchesStatus == MatchesStatus.loading &&
        provider.pastMatches.isEmpty) {
      return const Center(child: LoadingWidget());
    }

    if (provider.pastMatchesStatus == MatchesStatus.error) {
      return ErrorDisplayWidget(
        title: AppLocalization.of(context).translate('error_occurred'),
        message: provider.pastMatchesError,
        onRetry: () => provider.getPastMatches(),
      );
    }

    final filteredMatches = _filterMatches(provider.pastMatches);

    if (filteredMatches.isEmpty) {
      if (provider.pastMatches.isEmpty) {
        return Center(
          child: Text(
            AppLocalization.of(context).translate('no_data'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        );
      } else {
        return Center(
          child: Text(
            AppLocalization.of(context).translate('no_match_filter'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        );
      }
    }

    // Maçları lige göre gruplandır
    final matchesByLeague = <String, List<MatchModel>>{};
    for (var match in filteredMatches) {
      final leagueName = match.league?.name ?? 'Diğer';
      if (!matchesByLeague.containsKey(leagueName)) {
        matchesByLeague[leagueName] = [];
      }
      matchesByLeague[leagueName]!.add(match);
    }

    // Ligleri sırala
    final sortedLeagues =
        matchesByLeague.keys.toList()..sort((a, b) => a.compareTo(b));

    // Yükleniyor durumunu hesapla
    final showLoading =
        provider.isLoadingMorePast || provider.hasMorePastMatches;

    return RefreshIndicator(
      onRefresh: () => provider.getPastMatches(refresh: true),
      child: ListView.builder(
        controller: _pastScrollController,
        itemCount: sortedLeagues.length + (showLoading ? 1 : 0),
        padding: const EdgeInsets.all(8.0),
        itemBuilder: (context, index) {
          if (index == sortedLeagues.length) {
            // Sayfa sonunda loading gösterici
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child:
                    provider.isLoadingMorePast
                        ? const CircularProgressIndicator()
                        : TextButton(
                          onPressed:
                              () => provider.getPastMatches(refresh: false),
                          child: Text(
                            AppLocalization.of(context).translate('load_more'),
                          ),
                        ),
              ),
            );
          }

          final leagueName = sortedLeagues[index];
          final matchesInLeague = matchesByLeague[leagueName]!;
          final leagueColor = _getLeagueColor(leagueName);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lig başlığı
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      color: leagueColor,
                      margin: const EdgeInsets.only(right: 8),
                    ),
                    Expanded(
                      child: Text(
                        leagueName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        final leagueId = matchesInLeague.first.league?.id;
                        if (leagueId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => LeagueDetailScreen(
                                    leagueId: leagueId,
                                    leagueName: leagueName,
                                  ),
                            ),
                          );
                        }
                      },
                      child: Text(
                        AppLocalization.of(context).translate('see_all'),
                      ),
                    ),
                  ],
                ),
              ),
              // Maç listesi
              ...matchesInLeague.map(
                (match) => _buildMatchCard(context, match),
              ),
            ],
          );
        },
      ),
    );
  }

  // Lig rengini belirle
  Color _getLeagueColor(String leagueName) {
    return AppColors.generateLeagueColor(leagueName);
  }

  // Maç zamanını formatla
  String _formatMatchTime(DateTime? time) {
    if (time == null) return 'TBD';

    // UTC tarih bilgisini kullanıcının yerel saat dilimine çevir
    final localDateTime = time.toLocal();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final matchDate = DateTime(
      localDateTime.year,
      localDateTime.month,
      localDateTime.day,
    );

    // Saat formatlaması
    final hour = localDateTime.hour.toString().padLeft(2, '0');
    final minute = localDateTime.minute.toString().padLeft(2, '0');
    final formattedTime = '$hour:$minute';

    if (matchDate.isAtSameMomentAs(today)) {
      return AppLocalization.of(
        context,
      ).translate('today_format').replaceAll('{time}', formattedTime);
    } else if (matchDate.isAtSameMomentAs(tomorrow)) {
      return AppLocalization.of(
        context,
      ).translate('tomorrow_format').replaceAll('{time}', formattedTime);
    } else {
      return AppLocalization.of(context)
          .translate('date_format')
          .replaceAll('{day}', localDateTime.day.toString())
          .replaceAll('{month}', localDateTime.month.toString())
          .replaceAll('{year}', localDateTime.year.toString())
          .replaceAll('{time}', formattedTime);
    }
  }

  // Favori maçları silme
  Future<void> _deleteFromFavorites(BuildContext context, int matchId) async {
    try {
      await Provider.of<FavoritesProvider>(
        context,
        listen: false,
      ).removeFavoriteTeam(matchId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalization.of(
              context,
            ).translate('match_removed_from_favorites'),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalization.of(context).translate('error_removing_match'),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Maç kartı widget'ı - Daha sade tasarım
  Widget _buildMatchCard(
    BuildContext context,
    MatchModel match, {
    bool isFavorite = false,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor =
        isDarkMode
            ? theme.colorScheme.onSurfaceVariant
            : theme.colorScheme.onSurface;

    final isFinished = match.status == 'finished';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withAlpha(26),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToMatchDetails(match),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Liga bilgisi satırı
              Row(
                children: [
                  if (match.league?.imageUrl != null) ...[
                    CachedNetworkImage(
                      imageUrl: match.league!.imageUrl!,
                      width: 18,
                      height: 18,
                      placeholder:
                          (context, url) =>
                              const SizedBox(width: 18, height: 18),
                      errorWidget:
                          (context, url, error) => Icon(
                            Icons.sports_esports,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      match.league?.name ??
                          AppLocalization.of(
                            context,
                          ).translate('unknown_league'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: textColor.withAlpha(179),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Maç durumu
                  _buildStatusChip(
                    context,
                    match.status ?? 'unknown',
                    match: match,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Takım bilgileri satırı
              Row(
                children: [
                  // İlk takım
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: theme.colorScheme.surfaceContainerHighest
                                .withAlpha(77),
                          ),
                          child: CachedImage(
                            imageUrl: match.opponent1?.imageUrl ?? '',
                            width: 40,
                            height: 40,
                            fit: BoxFit.contain,
                            borderRadius: BorderRadius.circular(8),
                            placeholder: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.primary.withAlpha(
                                    128,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: Icon(
                              Icons.sports_esports,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            match.opponent1?.name ??
                                AppLocalization.of(
                                  context,
                                ).translate('unknown_team'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Skor veya zaman
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child:
                        isFinished
                            ? Text(
                              '${match.opponent1Score ?? 0} - ${match.opponent2Score ?? 0}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            )
                            : match.status == 'running'
                            ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withAlpha(26),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'VS',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.red,
                                ),
                              ),
                            )
                            : Text(
                              _formatMatchTime(match.beginAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                  ),

                  // İkinci takım
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            match.opponent2?.name ??
                                AppLocalization.of(
                                  context,
                                ).translate('unknown_team'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: theme.colorScheme.surfaceContainerHighest
                                .withAlpha(77),
                          ),
                          child: CachedImage(
                            imageUrl: match.opponent2?.imageUrl ?? '',
                            width: 40,
                            height: 40,
                            fit: BoxFit.contain,
                            borderRadius: BorderRadius.circular(8),
                            placeholder: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.primary.withAlpha(
                                    128,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: Icon(
                              Icons.sports_esports,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (isFavorite)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () => _deleteFromFavorites(context, match.id),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: Text(
                        AppLocalization.of(context).translate('delete'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Durum etiketi widget'ı
  Widget _buildStatusChip(
    BuildContext context,
    String status, {
    MatchModel? match,
  }) {
    final theme = Theme.of(context);

    Color backgroundColor;
    Color textColor;
    String statusText;
    IconData? statusIcon;

    switch (status) {
      case 'running':
        backgroundColor = Colors.red.withAlpha(230);
        textColor = Colors.white;
        statusIcon = Icons.sensors;
        if (match != null &&
            match.opponent1Score != null &&
            match.opponent2Score != null) {
          statusText = '${match.opponent1Score}-${match.opponent2Score}';
        } else {
          statusText = AppLocalization.of(context).translate('match_live');
        }
        break;
      case 'finished':
        backgroundColor = theme.colorScheme.primary.withAlpha(204);
        textColor = Colors.white;
        statusIcon = Icons.check_circle_outlined;
        statusText = AppLocalization.of(context).translate('finished');
        break;
      case 'not_started':
        backgroundColor = theme.colorScheme.surfaceContainerHighest;
        textColor = theme.colorScheme.onSurfaceVariant;
        statusIcon = Icons.schedule;
        statusText = AppLocalization.of(context).translate('upcoming');
        break;
      default:
        backgroundColor = Colors.grey.withAlpha(179);
        textColor = Colors.white;
        statusText = AppLocalization.of(context).translate('unknown');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor.withAlpha(77),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (statusIcon != null) ...[
            Icon(statusIcon, size: 10, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            statusText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 10,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // Maç detaylarına git
  void _navigateToMatchDetails(MatchModel match) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                MatchDetailsScreen(matchId: match.id, matchModel: match),
      ),
    );
  }
}
