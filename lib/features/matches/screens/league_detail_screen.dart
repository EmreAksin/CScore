import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/match_model.dart';
import '../../../core/utils/app_localization.dart';
import '../providers/matches_provider.dart';
import 'match_details_screen.dart';

class LeagueDetailScreen extends StatefulWidget {
  final int leagueId;
  final String leagueName;
  final String? leagueImageUrl;

  const LeagueDetailScreen({
    super.key,
    required this.leagueId,
    required this.leagueName,
    this.leagueImageUrl,
  });

  @override
  State<LeagueDetailScreen> createState() => _LeagueDetailScreenState();
}

class _LeagueDetailScreenState extends State<LeagueDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (widget.leagueImageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.leagueImageUrl!,
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 32,
                      height: 32,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.emoji_events, size: 20),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                widget.leagueName,
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: AppLocalization.of(context).translate('live')),
            Tab(text: AppLocalization.of(context).translate('upcoming')),
            Tab(text: AppLocalization.of(context).translate('finished')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Canlı maçlar
          _buildLiveMatchesTab(),

          // Yaklaşan maçlar
          _buildUpcomingMatchesTab(),

          // Tamamlanan maçlar
          _buildPastMatchesTab(),
        ],
      ),
    );
  }

  // Canlı maçlar tab'ı
  Widget _buildLiveMatchesTab() {
    return Consumer<MatchesProvider>(
      builder: (context, provider, child) {
        final filteredMatches = provider.getLiveMatchesByLeague(
          widget.leagueId,
        );

        if (provider.liveMatchesStatus == MatchesStatus.loading &&
            filteredMatches.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.liveMatchesStatus == MatchesStatus.error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  provider.liveMatchesError ??
                      AppLocalization.of(context).translate('unknown_error'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.getLiveMatches(),
                  child: Text(
                    AppLocalization.of(context).translate('try_again'),
                  ),
                ),
              ],
            ),
          );
        }

        if (filteredMatches.isEmpty) {
          return Center(
            child: Text(
              AppLocalization.of(
                context,
              ).translate('no_live_matches_in_league'),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.getLiveMatches(),
          child: ListView.builder(
            itemCount: filteredMatches.length,
            itemBuilder: (context, index) {
              final match = filteredMatches[index];
              return _buildMatchCard(match);
            },
          ),
        );
      },
    );
  }

  // Yaklaşan maçlar tab'ı
  Widget _buildUpcomingMatchesTab() {
    return Consumer<MatchesProvider>(
      builder: (context, provider, child) {
        final filteredMatches = provider.getUpcomingMatchesByLeague(
          widget.leagueId,
        );

        if (provider.upcomingMatchesStatus == MatchesStatus.loading &&
            filteredMatches.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.upcomingMatchesStatus == MatchesStatus.error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  provider.upcomingMatchesError ??
                      AppLocalization.of(context).translate('unknown_error'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.getUpcomingMatches(refresh: true),
                  child: Text(
                    AppLocalization.of(context).translate('try_again'),
                  ),
                ),
              ],
            ),
          );
        }

        if (filteredMatches.isEmpty) {
          return Center(
            child: Text(
              AppLocalization.of(
                context,
              ).translate('no_upcoming_matches_in_league'),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.getUpcomingMatches(refresh: true),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: filteredMatches.length,
                  itemBuilder: (context, index) {
                    final match = filteredMatches[index];
                    return _buildMatchCard(match);
                  },
                ),
              ),
              if (provider.upcomingMatchesStatus == MatchesStatus.loading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (provider.hasMoreUpcomingMatches &&
                  provider.upcomingMatchesStatus != MatchesStatus.loading)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () => provider.getUpcomingMatches(),
                    child: Text(
                      AppLocalization.of(context).translate('load_more'),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Tamamlanan maçlar tab'ı
  Widget _buildPastMatchesTab() {
    return Consumer<MatchesProvider>(
      builder: (context, provider, child) {
        final filteredMatches = provider.getPastMatchesByLeague(
          widget.leagueId,
        );

        if (provider.pastMatchesStatus == MatchesStatus.loading &&
            filteredMatches.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.pastMatchesStatus == MatchesStatus.error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  provider.pastMatchesError ??
                      AppLocalization.of(context).translate('unknown_error'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.getPastMatches(refresh: true),
                  child: Text(
                    AppLocalization.of(context).translate('try_again'),
                  ),
                ),
              ],
            ),
          );
        }

        if (filteredMatches.isEmpty) {
          return Center(
            child: Text(
              AppLocalization.of(
                context,
              ).translate('no_past_matches_in_league'),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.getPastMatches(refresh: true),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: filteredMatches.length,
                  itemBuilder: (context, index) {
                    final match = filteredMatches[index];
                    return _buildMatchCard(match);
                  },
                ),
              ),
              if (provider.pastMatchesStatus == MatchesStatus.loading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (provider.hasMorePastMatches &&
                  provider.pastMatchesStatus != MatchesStatus.loading)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () => provider.getPastMatches(),
                    child: Text(
                      AppLocalization.of(context).translate('load_more'),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Maç kartı widget'ı
  Widget _buildMatchCard(MatchModel match) {
    final hasTeams = match.opponent1 != null && match.opponent2 != null;
    final hasScores =
        match.opponent1Score != null && match.opponent2Score != null;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MatchDetailsScreen(matchId: match.id),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Maç durumu ve tarihi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getMatchStatus(match.status ?? ''),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(match.status ?? ''),
                    ),
                  ),
                  if (match.beginAt != null)
                    Text(
                      _formatDate(match.beginAt!),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Takımlar ve skor
              if (hasTeams) ...[
                Row(
                  children: [
                    // İlk takım
                    Expanded(
                      child: Column(
                        children: [
                          if (match.opponent1?.imageUrl != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                match.opponent1!.imageUrl!,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 40,
                                    height: 40,
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.sports_esports,
                                      size: 24,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Text(
                            match.opponent1!.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Skor
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppConstants.cardColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        hasScores
                            ? '${match.opponent1Score} - ${match.opponent2Score}'
                            : AppLocalization.of(context).translate('vs'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // İkinci takım
                    Expanded(
                      child: Column(
                        children: [
                          if (match.opponent2?.imageUrl != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                match.opponent2!.imageUrl!,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 40,
                                    height: 40,
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.sports_esports,
                                      size: 24,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Text(
                            match.opponent2!.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  match.name ??
                      AppLocalization.of(context).translate('unknown_match'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Maç durumunu Türkçe'ye çevir
  String _getMatchStatus(String status) {
    switch (status) {
      case 'running':
        return AppLocalization.of(context).translate('status_live');
      case 'not_started':
        return AppLocalization.of(context).translate('status_not_started');
      case 'finished':
        return AppLocalization.of(context).translate('status_finished');
      case 'canceled':
        return AppLocalization.of(context).translate('status_canceled');
      case 'postponed':
        return AppLocalization.of(context).translate('status_postponed');
      default:
        return status.toUpperCase();
    }
  }

  // Durum rengini belirle
  Color _getStatusColor(String status) {
    switch (status) {
      case 'running':
        return Colors.green;
      case 'not_started':
        return Colors.blue;
      case 'finished':
        return Colors.grey;
      case 'canceled':
      case 'postponed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Tarihi formatla
  String _formatDate(DateTime date) {
    // UTC tarih bilgisini kullanıcının yerel saat dilimine çevir
    final localDate = date.toLocal();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final matchDate = DateTime(localDate.year, localDate.month, localDate.day);

    if (matchDate.isAtSameMomentAs(today)) {
      return AppLocalization.of(
        context,
      ).translate('today_format').replaceAll('{time}', _formatTime(localDate));
    } else if (matchDate.isAtSameMomentAs(tomorrow)) {
      return AppLocalization.of(context)
          .translate('tomorrow_format')
          .replaceAll('{time}', _formatTime(localDate));
    } else {
      return AppLocalization.of(context)
          .translate('date_format')
          .replaceAll('{day}', localDate.day.toString())
          .replaceAll('{month}', localDate.month.toString())
          .replaceAll('{year}', localDate.year.toString())
          .replaceAll('{time}', _formatTime(localDate));
    }
  }

  // Saati formatla
  String _formatTime(DateTime date) {
    // UTC saat bilgisini kullanıcının yerel saat dilimine çevir
    final localDateTime = date.toLocal();
    final hour = localDateTime.hour.toString().padLeft(2, '0');
    final minute = localDateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
