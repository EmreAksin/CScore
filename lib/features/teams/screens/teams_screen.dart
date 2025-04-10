// Takımlar ekranı

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/team_model.dart';
import '../../../core/utils/app_localization.dart';
import '../providers/teams_provider.dart';
import 'team_detail_screen.dart';
import 'dart:async';
import '../../../core/extensions/country_code_extension.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();

    // Arama kutusu değişikliğini izle
    _searchController.addListener(_onSearchChanged);

    // Scroll dinleyicisi ekle - kullanıcı sayfanın sonuna yaklaştığında daha fazla takım yükle
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // Arama metni değiştiğinde çağrılır
  void _onSearchChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = _searchController.text;
      });

      // Server tarafında arama yap
      Provider.of<TeamsProvider>(
        context,
        listen: false,
      ).searchTeamsByName(_searchController.text);
    });
  }

  // Scroll dinleyicisi - sayfanın sonuna yaklaşıldığında daha fazla takım yükle
  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Son 200 piksele geldiğimizde daha fazla takım yükle
      final teamsProvider = Provider.of<TeamsProvider>(context, listen: false);
      if (teamsProvider.teamsStatus != TeamsStatus.loading &&
          teamsProvider.hasMoreTeams) {
        teamsProvider.loadMoreTeams();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Arama kutusu
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppLocalization.of(context).translate('search_team'),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
              ),
            ),
          ),
          // Takım listesi
          Expanded(child: _buildTeamsList()),
        ],
      ),
    );
  }

  Widget _buildTeamsList() {
    return Consumer<TeamsProvider>(
      builder: (context, teamsProvider, child) {
        final status = teamsProvider.teamsStatus;

        // İlk yükleme durumdaysa ve henüz takım yoksa yükleniyor göster
        if (status == TeamsStatus.loading && teamsProvider.teams.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  "Takımlar yükleniyor...",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }

        // Hata
        if (status == TeamsStatus.error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  teamsProvider.teamsError ??
                      AppLocalization.of(context).translate('error_occurred'),
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => teamsProvider.refreshTeams(),
                  label: Text(
                    AppLocalization.of(context).translate('try_again'),
                  ),
                ),
              ],
            ),
          );
        }

        // Takım listesini al
        List<TeamModel> teamsList = List.from(teamsProvider.teams);

        // Takım listesi boşsa ve yükleme tamamlandıysa
        if (teamsList.isEmpty && status == TeamsStatus.loaded) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.group_off, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Kriterlere uygun takım bulunamadı.\nSadece logosu olan ve en az 5 oyuncusu olan takımlar gösterilmektedir.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => teamsProvider.refreshTeams(),
                  label: Text(AppLocalization.of(context).translate('refresh')),
                ),
              ],
            ),
          );
        }

        // Filtre uygula
        final filteredTeams =
            teamsList.where((team) {
              final searchLower = _searchQuery.toLowerCase();
              final teamNameLower = team.name.toLowerCase();
              final teamAcronymLower = (team.acronym).toLowerCase();
              return teamNameLower.contains(searchLower) ||
                  teamAcronymLower.contains(searchLower);
            }).toList();

        // Arama sonucu yok
        if (filteredTeams.isEmpty && _searchQuery.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  '"$_searchQuery" ile eşleşen takım bulunamadı',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                    teamsProvider.searchTeamsByName('');
                  },
                  child: const Text('Aramayı Temizle'),
                ),
              ],
            ),
          );
        }

        // Takımlar listesi
        return RefreshIndicator(
          onRefresh: () => teamsProvider.refreshTeams(),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount:
                filteredTeams.length +
                (teamsProvider.hasMoreTeams && status != TeamsStatus.loading
                    ? 1
                    : 0),
            itemBuilder: (context, index) {
              // Sayfanın sonunda ve daha fazla takım varsa yükleniyor göster
              if (index == filteredTeams.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(
                    child: Column(
                      children: [
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Daha fazla takım yükleniyor...',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              }
              final team = filteredTeams[index];
              return _buildTeamCard(context, team);
            },
          ),
        );
      },
    );
  }

  Widget _buildTeamCard(BuildContext context, TeamModel team) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      TeamDetailScreen(teamId: team.id, teamName: team.name),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Takım logosu
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    team.logoUrl != null
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            team.logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.sports_esports,
                                size: 30,
                                color: Colors.grey,
                              );
                            },
                          ),
                        )
                        : const Icon(
                          Icons.sports_esports,
                          size: 30,
                          color: Colors.grey,
                        ),
              ),
              const SizedBox(width: 16),
              // Takım bilgileri
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            team.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (team.location != null && team.location!.isNotEmpty)
                          Text(
                            team.location!.toFlagEmoji(),
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(fontSize: 20),
                          )
                        else if (team.location == null ||
                            team.location!.isEmpty)
                          Text(
                            '🌍',
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(fontSize: 20),
                          ),
                      ],
                    ),
                    if (team.acronym.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        team.acronym,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                        ),
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
