// Turnuvalar ekranı

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/tournament_model.dart';
import '../../../core/utils/app_localization.dart';
import '../providers/tournaments_provider.dart';
import 'tournament_detail_screen.dart';
import '../../../main.dart'; // navigatorKey için import ekledim

class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({super.key});

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _selectedTiers = <String>[];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  // Filtreleri temizle
  void _clearFilters() {
    setState(() {
      _selectedTiers.clear();
    });
  }

  // Tier filtresini toggle et
  void _toggleTier(String tier) {
    setState(() {
      if (_selectedTiers.contains(tier)) {
        _selectedTiers.remove(tier);
      } else {
        _selectedTiers.add(tier);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            Tab(
              text: AppLocalization.of(context).translate('live_tournaments'),
            ),
            Tab(
              text: AppLocalization.of(
                context,
              ).translate('upcoming_tournaments'),
            ),
            Tab(
              text: AppLocalization.of(context).translate('past_tournaments'),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Tier filtreleme seçenekleri
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
                  TextButton.icon(
                    onPressed: _clearFilters,
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
          // Tab view
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Canlı (devam eden) turnuvalar
                _LiveTournamentsTab(selectedTiers: _selectedTiers),

                // Yaklaşan turnuvalar
                _UpcomingTournamentsTab(selectedTiers: _selectedTiers),

                // Tamamlanan turnuvalar
                _PastTournamentsTab(selectedTiers: _selectedTiers),
              ],
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
}

// Turnuvaları filtreleme yardımcı fonksiyonu
bool _isHighTierTournament(TournamentModel tournament) {
  final tier = tournament.tier;

  if (tier == null) return false;

  // Sadece S tier, A tier ve B tier turnuvaları göster
  final upperTier = tier.toUpperCase();
  return upperTier == 'S' || upperTier == 'A' || upperTier == 'B';
}

// Turnuvaları liglere göre grupla
Map<String, List<TournamentModel>> _groupTournamentsByLeague(
  List<TournamentModel> tournaments,
  BuildContext context,
) {
  final Map<String, List<TournamentModel>> grouped = {};

  for (final tournament in tournaments) {
    // Lig adı yoksa "Diğer" grubuna ekle
    final leagueName =
        tournament.leagueName ?? AppLocalization.of(context).translate('other');

    if (!grouped.containsKey(leagueName)) {
      grouped[leagueName] = [];
    }

    grouped[leagueName]!.add(tournament);
  }

  // Liglerin alfabetik sıralanması için
  final sortedKeys = grouped.keys.toList()..sort();

  // Sıralanmış key listesinden yeni bir Map oluştur
  final result = <String, List<TournamentModel>>{};
  for (final key in sortedKeys) {
    result[key] = grouped[key]!;
  }

  return result;
}

// Liglere göre gruplanmış turnuvaları gösteren widget
Widget _buildLeagueGroupedTournaments(
  BuildContext context,
  Map<String, List<TournamentModel>> groupedTournaments,
  List<String> selectedTiers,
) {
  return ListView.builder(
    padding: const EdgeInsets.all(8.0),
    itemCount: groupedTournaments.length,
    itemBuilder: (context, index) {
      final leagueName = groupedTournaments.keys.elementAt(index);
      final tournamentsInLeague = groupedTournaments[leagueName]!;

      // Filtreleme işlemi
      final filteredTournaments =
          selectedTiers.isEmpty
              ? tournamentsInLeague
              : tournamentsInLeague.where((tournament) {
                final tier = tournament.tier?.toUpperCase() ?? '';
                return selectedTiers.contains(tier);
              }).toList();

      // Eğer filtrelemeden sonra turnuva kalmadıysa, bu ligi gösterme
      if (filteredTournaments.isEmpty) {
        return const SizedBox();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lig başlığı
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                leagueName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          // Lig içindeki turnuvalar
          ...filteredTournaments.map(
            (tournament) => _buildTournamentCard(context, tournament),
          ),
        ],
      );
    },
  );
}

// Canlı turnuvalar tab'ı
class _LiveTournamentsTab extends StatelessWidget {
  final List<String> selectedTiers;

  const _LiveTournamentsTab({required this.selectedTiers});

  @override
  Widget build(BuildContext context) {
    return Consumer<TournamentsProvider>(
      builder: (context, provider, child) {
        final status = provider.liveTournamentsStatus;
        final tournaments = provider.liveTournaments;
        final error = provider.liveTournamentsError;

        if (status == TournamentsStatus.initial ||
            status == TournamentsStatus.loading && tournaments.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (status == TournamentsStatus.error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalization.of(
                    context,
                  ).translate('live_tournaments_error'),
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  error ?? AppLocalization.of(context).translate('unknown'),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.getLiveTournaments(refresh: true),
                  child: Text(
                    AppLocalization.of(context).translate('try_again'),
                  ),
                ),
              ],
            ),
          );
        }

        // Önce filtreleme işlemi yap
        final filteredTournaments =
            selectedTiers.isEmpty
                ? tournaments
                : tournaments.where((tournament) {
                  final tier = tournament.tier?.toUpperCase() ?? '';
                  return selectedTiers.contains(tier);
                }).toList();

        if (filteredTournaments.isEmpty) {
          if (tournaments.isEmpty) {
            return Center(
              child: Text(
                AppLocalization.of(context).translate('no_live_tournaments'),
                textAlign: TextAlign.center,
              ),
            );
          } else {
            // Turnuvalar var ama filtrelenince sonuç yok
            return Center(
              child: Text(
                AppLocalization.of(context).translate('no_match_filter'),
                textAlign: TextAlign.center,
              ),
            );
          }
        }

        // Turnuvaları liglere göre grupla
        final groupedTournaments = _groupTournamentsByLeague(
          filteredTournaments,
          context,
        );

        return RefreshIndicator(
          onRefresh: () => provider.getLiveTournaments(refresh: true),
          child: _buildLeagueGroupedTournaments(
            context,
            groupedTournaments,
            selectedTiers,
          ),
        );
      },
    );
  }
}

// Yaklaşan turnuvalar tab'ı
class _UpcomingTournamentsTab extends StatelessWidget {
  final List<String> selectedTiers;

  const _UpcomingTournamentsTab({required this.selectedTiers});

  @override
  Widget build(BuildContext context) {
    return Consumer<TournamentsProvider>(
      builder: (context, provider, child) {
        final status = provider.upcomingTournamentsStatus;
        final tournaments = provider.upcomingTournaments;
        final error = provider.upcomingTournamentsError;

        if (status == TournamentsStatus.initial ||
            status == TournamentsStatus.loading && tournaments.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (status == TournamentsStatus.error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalization.of(
                    context,
                  ).translate('upcoming_tournaments_error'),
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  error ?? AppLocalization.of(context).translate('unknown'),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed:
                      () => provider.getUpcomingTournaments(refresh: true),
                  child: Text(
                    AppLocalization.of(context).translate('try_again'),
                  ),
                ),
              ],
            ),
          );
        }

        // Önce filtreleme işlemi yap
        final filteredTournaments =
            selectedTiers.isEmpty
                ? tournaments
                : tournaments.where((tournament) {
                  final tier = tournament.tier?.toUpperCase() ?? '';
                  return selectedTiers.contains(tier);
                }).toList();

        if (filteredTournaments.isEmpty) {
          if (tournaments.isEmpty) {
            return Center(
              child: Text(
                AppLocalization.of(
                  context,
                ).translate('no_upcoming_tournaments'),
              ),
            );
          } else {
            // Turnuvalar var ama filtrelenince sonuç yok
            return Center(
              child: Text(
                AppLocalization.of(context).translate('no_match_filter'),
                textAlign: TextAlign.center,
              ),
            );
          }
        }

        // Turnuvaları liglere göre grupla
        final groupedTournaments = _groupTournamentsByLeague(
          filteredTournaments,
          context,
        );

        return RefreshIndicator(
          onRefresh: () => provider.getUpcomingTournaments(refresh: true),
          child: _buildLeagueGroupedTournaments(
            context,
            groupedTournaments,
            selectedTiers,
          ),
        );
      },
    );
  }
}

// Tamamlanan turnuvalar tab'ı
class _PastTournamentsTab extends StatelessWidget {
  final List<String> selectedTiers;

  const _PastTournamentsTab({required this.selectedTiers});

  @override
  Widget build(BuildContext context) {
    return Consumer<TournamentsProvider>(
      builder: (context, provider, child) {
        final status = provider.pastTournamentsStatus;
        final tournaments = provider.pastTournaments;
        final error = provider.pastTournamentsError;

        if (status == TournamentsStatus.initial ||
            status == TournamentsStatus.loading && tournaments.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (status == TournamentsStatus.error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalization.of(
                    context,
                  ).translate('past_tournaments_error'),
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  error ?? AppLocalization.of(context).translate('unknown'),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.getPastTournaments(refresh: true),
                  child: Text(
                    AppLocalization.of(context).translate('try_again'),
                  ),
                ),
              ],
            ),
          );
        }

        // Önce filtreleme işlemi yap
        final filteredTournaments =
            selectedTiers.isEmpty
                ? tournaments
                : tournaments.where((tournament) {
                  final tier = tournament.tier?.toUpperCase() ?? '';
                  return selectedTiers.contains(tier);
                }).toList();

        // Filtrelenmiş turnuvalar boşsa
        if (filteredTournaments.isEmpty) {
          // API'den veri yüklenmiş ama filtrelenince boş kalmışsa
          if (tournaments.isNotEmpty) {
            return Center(
              child: Text(
                AppLocalization.of(context).translate('no_match_filter'),
                textAlign: TextAlign.center,
              ),
            );
          }
          // Hiç veri yoksa
          return Center(
            child: Text(
              AppLocalization.of(
                context,
              ).translate('no_past_tournaments_found'),
            ),
          );
        }

        // Turnuvaları liglere göre grupla
        final groupedTournaments = _groupTournamentsByLeague(
          filteredTournaments,
          context,
        );

        return RefreshIndicator(
          onRefresh:
              () =>
                  provider.getPastTournaments(refresh: true, targetCount: 100),
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              // Sadece yüklenecek daha fazla veri varsa ve yükleme durumunda değilse
              if (scrollInfo.metrics.pixels ==
                      scrollInfo.metrics.maxScrollExtent &&
                  provider.hasMorePastTournaments &&
                  status != TournamentsStatus.loading) {
                provider.getPastTournaments(targetCount: 100);
              }
              return false;
            },
            child: Stack(
              children: [
                _buildLeagueGroupedTournaments(
                  context,
                  groupedTournaments,
                  selectedTiers,
                ),
                // Yükleme göstergesi
                if (status == TournamentsStatus.loading)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      color: Colors.black26,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Turnuva kartı widget'ı
Widget _buildTournamentCard(BuildContext context, TournamentModel tournament) {
  // Tier değerine göre özel renkler belirle
  Color getTierColor(String? tier) {
    if (tier == null) {
      return Theme.of(context).colorScheme.surfaceContainerHighest;
    }

    // Tema modunu kontrol et
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    switch (tier.toUpperCase()) {
      case 'S':
        return isDarkMode
            ? Colors.amber.shade900.withAlpha(51) // 0.2 * 255 = 51
            : Colors.amber.shade100;
      case 'A':
        return isDarkMode
            ? Colors.blue.shade900.withAlpha(51) // 0.2 * 255 = 51
            : Colors.blue.shade100;
      case 'B':
        return isDarkMode
            ? Colors.green.shade900.withAlpha(51) // 0.2 * 255 = 51
            : Colors.green.shade100;
      default:
        return Theme.of(context).colorScheme.surfaceContainerHighest;
    }
  }

  Color getTierTextColor(String? tier) {
    if (tier == null) return Theme.of(context).colorScheme.onSurfaceVariant;

    // Tema modunu kontrol et
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    switch (tier.toUpperCase()) {
      case 'S':
        return isDarkMode ? Colors.amber.shade300 : Colors.amber.shade900;
      case 'A':
        return isDarkMode ? Colors.blue.shade300 : Colors.blue.shade900;
      case 'B':
        return isDarkMode ? Colors.green.shade300 : Colors.green.shade900;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  return Card(
    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
    child: InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => TournamentDetailScreen(
                  tournamentId: tournament.id,
                  tournamentName: tournament.formattedName,
                ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Turnuva logosu
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      tournament.imageUrl != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              tournament.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.emoji_events,
                                  size: 30,
                                  color: Colors.grey,
                                );
                              },
                            ),
                          )
                          : const Icon(
                            Icons.emoji_events,
                            size: 30,
                            color: Colors.grey,
                          ),
                ),
                const SizedBox(width: 16),
                // Turnuva bilgileri
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tournament.formattedName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            const SizedBox(height: 8),
            // Tarih ve ödül bilgisi
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarih bilgisi
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant
                            .withAlpha(179), // 0.7 * 255 = 179
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _formatDateRange(
                            tournament.beginAt,
                            tournament.endAt,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withAlpha(179), // 0.7 * 255 = 179
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Ödül bilgisi - ayrı bir satırda gösterilecek
                  if (tournament.prizepool != null &&
                      tournament.prizepool!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.attach_money,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant
                              .withAlpha(179), // 0.7 * 255 = 179
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            tournament.prizepool!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withAlpha(179), // 0.7 * 255 = 179
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// Tarih aralığını formatla
String _formatDateRange(DateTime? beginAt, DateTime? endAt) {
  final context = navigatorKey.currentContext!;

  if (beginAt == null && endAt == null) {
    return AppLocalization.of(context).translate('no_date_info');
  }

  // UTC tarih bilgilerini kullanıcının yerel saat dilimine çevirelim
  final localBeginAt = beginAt?.toLocal();
  final localEndAt = endAt?.toLocal();

  if (localBeginAt != null && localEndAt != null) {
    return '${localBeginAt.day}.${localBeginAt.month}.${localBeginAt.year} - ${localEndAt.day}.${localEndAt.month}.${localEndAt.year}';
  } else if (localBeginAt != null) {
    return '${AppLocalization.of(context).translate('start_date')}: ${localBeginAt.day}.${localBeginAt.month}.${localBeginAt.year}';
  } else if (localEndAt != null) {
    return '${AppLocalization.of(context).translate('end_date')}: ${localEndAt.day}.${localEndAt.month}.${localEndAt.year}';
  } else {
    return AppLocalization.of(context).translate('no_date_info');
  }
}
