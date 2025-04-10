// Ligler ekranı

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/match_model.dart';
import '../../../core/utils/app_localization.dart';
import '../providers/leagues_provider.dart';
import '../../matches/screens/league_detail_screen.dart';

class LeaguesScreen extends StatelessWidget {
  const LeaguesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalization.of(context).translate('leagues_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<LeaguesProvider>(
                context,
                listen: false,
              ).refreshLeagues();
            },
          ),
        ],
      ),
      body: Consumer<LeaguesProvider>(
        builder: (context, leaguesProvider, child) {
          final status = leaguesProvider.leaguesStatus;
          final error = leaguesProvider.leaguesError;
          final leagues = leaguesProvider.leagues;

          if (status == LeaguesStatus.initial ||
              status == LeaguesStatus.loading && leagues.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (status == LeaguesStatus.error && leagues.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalization.of(
                      context,
                    ).translate('leagues_loading_error'),
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
                    onPressed: () => leaguesProvider.refreshLeagues(),
                    child: Text(
                      AppLocalization.of(context).translate('try_again'),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => leaguesProvider.refreshLeagues(),
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (scrollInfo.metrics.pixels ==
                        scrollInfo.metrics.maxScrollExtent &&
                    leaguesProvider.hasMoreLeagues &&
                    status != LeaguesStatus.loading) {
                  leaguesProvider.loadMoreLeagues();
                }
                return false;
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount:
                    leagues.length + (leaguesProvider.hasMoreLeagues ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == leagues.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final league = leagues[index];
                  return _buildLeagueCard(context, league);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeagueCard(BuildContext context, LeagueModel league) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => LeagueDetailScreen(
                    leagueId: league.id,
                    leagueName: league.name,
                    leagueImageUrl: league.imageUrl,
                  ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Lig logosu
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    league.imageUrl != null
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            league.imageUrl!,
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
              // Lig bilgileri
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      league.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (league.url != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        AppLocalization.of(context)
                            .translate('official_site')
                            .replaceAll('{0}', league.url!),
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
