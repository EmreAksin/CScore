// Turnuva detay ekranı

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/tournament_model.dart';
import '../../../core/models/match_model.dart';
import '../../../core/models/team_model.dart';
import '../providers/tournaments_provider.dart';
import '../../matches/screens/match_details_screen.dart';
import '../../matches/providers/matches_provider.dart';
import '../../../core/utils/app_localization.dart';
import '../../../core/utils/logger.dart';

class TournamentDetailScreen extends StatefulWidget {
  final int tournamentId;
  final String tournamentName;
  final TournamentModel? preloadedTournament;

  const TournamentDetailScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
    this.preloadedTournament,
  });

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TournamentModel? _tournament;
  List<MatchModel> _matches = [];
  bool _isLoading = true;
  bool _isLoadingResults = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Eğer önceden yüklenmiş turnuva bilgisi varsa kullan
    if (widget.preloadedTournament != null) {
      setState(() {
        _tournament = widget.preloadedTournament;
      });
    }

    // Sayfa açılır açılmaz veriyi yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTournamentData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTournamentData() async {
    // BuildContext kullanımını async gap öncesinde yap
    final tournamentsProvider = Provider.of<TournamentsProvider>(
      context,
      listen: false,
    );

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Turnuva detaylarını getir
      final tournament = await tournamentsProvider.getTournamentDetails(
        widget.tournamentId,
      );

      // Turnuva detayları gelince hemen state'i güncelle
      if (mounted) {
        setState(() {
          _tournament = tournament;
          // Burada sadece turnuva bilgilerini güncelliyoruz, yükleme durumunu henüz false yapmıyoruz
          // Böylece UI'da başlık bilgileri hemen görünür olacak
        });
      }

      List<MatchModel> matches = [];

      // Turnuvadaki maçları getir
      try {
        matches = await tournamentsProvider.getMatchesByTournament(
          widget.tournamentId,
        );

        _logger(
          'Turnuva ${widget.tournamentId} için ${matches.length} maç yüklendi',
        );

        // Maçlar boş gelmiş olabilir, kontrol edelim
        if (matches.isEmpty && mounted) {
          // MatchesProvider'dan tüm maçları alıp turnuvaya göre filtrelemeyi deneyelim
          final matchesProvider = Provider.of<MatchesProvider>(
            context,
            listen: false,
          );

          // Tüm maçları birleştir ve turnuva ID'sine göre filtrele
          final allMatches = [
            ...matchesProvider.liveMatches,
            ...matchesProvider.upcomingMatches,
            ...matchesProvider.pastMatches,
          ];

          matches =
              allMatches
                  .where(
                    (match) =>
                        match.tournament != null &&
                        match.tournament!.id == widget.tournamentId,
                  )
                  .toList();

          _logger('MatchesProvider\'dan ${matches.length} maç alındı');
        }
      } catch (e) {
        _logger('Turnuva maçları yüklenirken hata: $e');
        // Hata durumunda boş liste kullanılacak
        matches = [];
      }

      if (mounted) {
        setState(() {
          _matches = matches;
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger('Turnuva bilgileri yüklenirken hata: $e');
      if (mounted) {
        setState(() {
          _error = 'Turnuva bilgileri yüklenirken bir hata oluştu: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadTournamentResults() async {
    if (_isLoadingResults) {
      return;
    }

    // BuildContext kullanımını async gap öncesinde yap
    Provider.of<TournamentsProvider>(context, listen: false);
    final errorMessage = AppLocalization.of(
      context,
    ).translate('tournament_results_load_error');

    setState(() {
      _isLoadingResults = true;
    });

    try {
      // Tüm istekleri try-catch bloklarına al ve hataları sakla

      try {
        // Turnuvada oynayan takımları getir
      } catch (e) {
        _logger('Takımlar yüklenemedi: $e');
      }

      try {
        // Turnuva eleme tablosunu getir
      } catch (e) {
        _logger('Eleme tablosu yüklenemedi: $e');
      }

      try {
        // Turnuva sıralamasını getir
      } catch (e) {
        _logger('Sıralama tablosu yüklenemedi: $e');
      }

      if (mounted) {
        setState(() {
          _isLoadingResults = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingResults = false;
        });

        _showErrorSnackbar(errorMessage);
      }
    }
  }

  void _logger(String message) {
    // Debug modunda loglar sadece geliştirme aşamasında görünür
    Logger.log(message);
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isLoading && _error == null && _tournament != null) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_tournament!.leagueName != null &&
                      _tournament!.leagueName!.isNotEmpty)
                    Flexible(
                      child: Text(
                        _tournament!.leagueName!,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (_tournament!.leagueName != null &&
                      _tournament!.leagueName!.isNotEmpty &&
                      _tournament?.serie?.name != null &&
                      _tournament!.serie!.name.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '•',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  if (_tournament?.serie?.name != null &&
                      _tournament!.serie!.name.isNotEmpty)
                    Flexible(
                      child: Text(
                        _tournament!.serie!.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ],
            Flexible(
              child: Text(
                widget.tournamentName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTournamentData,
            tooltip: AppLocalization.of(context).translate('try_again'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          tabs: [
            Tab(text: AppLocalization.of(context).translate('matches')),
            Tab(text: AppLocalization.of(context).translate('results')),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _buildErrorWidget()
              : TabBarView(
                controller: _tabController,
                children: [
                  // Maçlar sekmesi (turnuva bilgilerini de içerecek)
                  _buildCombinedMatchesTab(),

                  // Turnuva sonuçları
                  _buildTournamentResultsTab(),
                ],
              ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppLocalization.of(
              context,
            ).translate('tournament_details_load_error'),
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? AppLocalization.of(context).translate('unknown_error'),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadTournamentData,
            child: Text(AppLocalization.of(context).translate('try_again')),
          ),
        ],
      ),
    );
  }

  // Maçlar ve Turnuva bilgilerini içeren birleştirilmiş sekme
  Widget _buildCombinedMatchesTab() {
    return RefreshIndicator(
      onRefresh: _loadTournamentData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Turnuva bilgilerini özet olarak göster
              if (_tournament != null) ...[
                const SizedBox(height: 16),
                _buildTournamentSummary(),
                const SizedBox(height: 16),
              ],

              // Maçlar listesi başlığı
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.sports_esports,
                        size: 20,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalization.of(context).translate('matches'),
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Canlı maçlar
              _buildMatchesByStatus(
                'running',
                AppLocalization.of(context).translate('live_matches'),
              ),

              // Yaklaşan maçlar
              _buildMatchesByStatus(
                'not_started',
                AppLocalization.of(context).translate('upcoming_matches'),
              ),

              // Tamamlanan maçlar
              _buildMatchesByStatus(
                'finished',
                AppLocalization.of(context).translate('past_matches'),
              ),

              // Eğer hiç maç yoksa
              if (_matches.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.sports_esports,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalization.of(
                            context,
                          ).translate('no_pending_matches'),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Turnuva özet bilgilerini gösteren widget
  Widget _buildTournamentSummary() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Turnuva logosu ve adı - yan yana (mobile) veya üst üste (tablet/desktop)
            LayoutBuilder(
              builder: (context, constraints) {
                // Logoyu merkeze hizalayalım ve Logo yoksa da yer açalım
                return Column(
                  children: [
                    // Logo için sabit bir alan oluşturalım
                    SizedBox(
                      height: 120,
                      child: Center(child: _buildTournamentLogo(100)),
                    ),
                    const SizedBox(height: 16),
                    _buildTournamentTitle(),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Turnuva temel bilgileri - daha responsive hale getirme
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                // Oyun adı
                _buildInfoBadge(
                  Icons.videogame_asset,
                  'Counter-Strike 2',
                  Theme.of(context).colorScheme.primary,
                ),

                // Turnuva Seviyesi
                if (_tournament!.tier != null)
                  _buildInfoBadge(
                    Icons.star,
                    '${AppLocalization.of(context).translate('tournament_tier')}: ${_tournament!.tier!.toUpperCase()}',
                    Colors.amber,
                  ),

                // Başlangıç tarihi
                if (_tournament!.beginAt != null)
                  _buildInfoBadge(
                    Icons.calendar_today,
                    '${AppLocalization.of(context).translate('start_date')}: ${_formatDate(_tournament!.beginAt!)}',
                    Colors.blue,
                  ),

                // Bitiş tarihi
                if (_tournament!.endAt != null)
                  _buildInfoBadge(
                    Icons.event,
                    '${AppLocalization.of(context).translate('end_date')}: ${_formatDate(_tournament!.endAt!)}',
                    Colors.green,
                  ),

                // Ödül havuzu
                if (_tournament!.prizepool != null)
                  _buildInfoBadge(
                    Icons.attach_money,
                    '${_tournament!.prizepool}',
                    Colors.deepOrange,
                  ),

                // Lig adı
                if (_tournament!.leagueName != null &&
                    _tournament!.leagueName!.isNotEmpty)
                  _buildInfoBadge(
                    Icons.shield,
                    '${AppLocalization.of(context).translate('league')}: ${_tournament!.leagueName}',
                    Colors.purple,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Turnuva logosu
  Widget _buildTournamentLogo(double size) {
    if (_tournament?.imageUrl == null) {
      // Logo yoksa boş yer yerine bir varsayılan logo göster
      return Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const ClipOval(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Icon(
              Icons.emoji_events_outlined,
              size: 40,
              color: Colors.amber,
            ),
          ),
        ),
      );
    }

    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.network(
            _tournament!.imageUrl!,
            fit: BoxFit.contain,
            errorBuilder:
                (_, __, ___) => const Icon(
                  Icons.emoji_events_outlined,
                  size: 40,
                  color: Colors.amber,
                ),
          ),
        ),
      ),
    );
  }

  // Turnuva başlığı
  Widget _buildTournamentTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          widget.tournamentName,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        // if (_tournament!.serie?.name != null && _tournament!.serie!.name.isNotEmpty)
        //   Padding(
        //     padding: const EdgeInsets.only(top: 4),
        //     child: Text(
        //       _tournament!.serie!.name,
        //       style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        //             color: Theme.of(context).colorScheme.onSurfaceVariant,
        //           ),
        //       textAlign: TextAlign.center,
        //     ),
        //   ),
      ],
    );
  }

  // Info badge widget - tekrar kullanılabilir bilgi rozeti
  Widget _buildInfoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  // Tarih formatlama yardımcı metodu
  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  // İstatistik öğesi

  // Bilgi chip'i

  // Maçları duruma göre filtrele ve göster
  Widget _buildMatchesByStatus(String status, String title) {
    final filteredMatches =
        _matches.where((match) => match.status == status).toList();

    if (filteredMatches.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              if (status == 'running')
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(8),
          itemCount: filteredMatches.length,
          itemBuilder: (context, index) {
            return _buildMatchCard(filteredMatches[index]);
          },
        ),
      ],
    );
  }

  Widget _buildTournamentResultsTab() {
    // Sonuçları yükle
    if (!_isLoadingResults) {
      _loadTournamentResults();
    }

    // Bu metot çağrıldığında, tamamlanan maçları getir
    final completedMatches =
        _matches.where((match) => match.status == 'finished').toList();

    // Tamamlanan maçları başlangıç tarihlerine göre sırala (en yeni en üstte)
    completedMatches.sort((a, b) {
      // null güvenliği için kontrol
      if (a.beginAt == null) return 1; // null tarihi sona at
      if (b.beginAt == null) return -1; // null tarihi sona at

      // Daha yakın tarihi (daha yeni maçı) üste yerleştir
      return b.beginAt!.compareTo(a.beginAt!);
    });

    // Debug için kontrol edelim
    _logger('Turnuva ID: ${widget.tournamentId}');
    _logger('Toplam maç sayısı: ${_matches.length}');
    _logger('Tamamlanan maç sayısı: ${completedMatches.length}');

    if (completedMatches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 48.0,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withAlpha(153),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalization.of(
                context,
              ).translate('no_completed_matches_tournament'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withAlpha(153),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    try {
      // Kazanan takımları ve istatistikleri hesapla
      final teamStats = _calculateTeamStats(completedMatches);

      // Takımları kazanma sayılarına göre sırala
      final sortedTeams =
          teamStats.entries.toList()..sort((a, b) {
            // Önce net kazanç puanına (G-M) göre sırala
            final netA = a.value.wins - a.value.losses;
            final netB = b.value.wins - b.value.losses;

            // Net kazançlar farklıysa, büyük olan önce gelir
            if (netA != netB) {
              return netB.compareTo(netA);
            }

            // Net kazançlar eşitse, galibiyet sayısına göre sırala
            return b.value.wins.compareTo(a.value.wins);
          });

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Puan durumu
            _buildSectionTitle(
              AppLocalization.of(context).translate('standings'),
            ),
            teamStats.isEmpty
                ? _buildNoDataMessage(
                  AppLocalization.of(context).translate('no_team_standings'),
                )
                : _buildTeamStandings(sortedTeams),

            const SizedBox(height: 24.0),

            // Tamamlanan maçlar
            _buildSectionTitle(
              '${AppLocalization.of(context).translate('completed_matches')} (${completedMatches.length})',
            ),
            _buildCompletedMatchesList(completedMatches),
          ],
        ),
      );
    } catch (e) {
      _logger('Turnuva sonuçları oluşturulurken hata: $e');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48.0, color: Colors.red),
            const SizedBox(height: 16.0),
            Text(
              AppLocalization.of(context).translate('tournament_results_error'),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),
            Text(
              e.toString(),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                setState(() {});
              },
              child: Text(AppLocalization.of(context).translate('try_again')),
            ),
          ],
        ),
      );
    }
  }

  // Veri yoksa gösterilecek mesaj widget'ı
  Widget _buildNoDataMessage(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.info_outline, size: 24, color: Colors.grey.shade600),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Takım istatistiklerini hesapla - hata yönetimini güçlendirdim
  Map<int, TeamStats> _calculateTeamStats(List<MatchModel> matches) {
    final teamStats = <int, TeamStats>{};

    for (final match in matches) {
      try {
        // Tüm gerekli alanlara sahip olduğundan emin olalım
        if (match.winnerId != null &&
            match.opponent1 != null &&
            match.opponent2 != null &&
            match.opponent1Score != null &&
            match.opponent2Score != null) {
          // İlk takım
          if (!teamStats.containsKey(match.opponent1!.id)) {
            teamStats[match.opponent1!.id] = TeamStats(
              team: match.opponent1!,
              wins: 0,
              losses: 0,
              roundsWon: 0,
              roundsLost: 0,
            );
          }

          // İkinci takım
          if (!teamStats.containsKey(match.opponent2!.id)) {
            teamStats[match.opponent2!.id] = TeamStats(
              team: match.opponent2!,
              wins: 0,
              losses: 0,
              roundsWon: 0,
              roundsLost: 0,
            );
          }

          // Maç sonuçlarını istatistiklere ekle
          if (match.winnerId == match.opponent1!.id) {
            // Birinci takım kazandı
            teamStats[match.opponent1!.id]!.wins++;
            teamStats[match.opponent2!.id]!.losses++;
            teamStats[match.opponent1!.id]!.roundsWon += match.opponent1Score!;
            teamStats[match.opponent1!.id]!.roundsLost += match.opponent2Score!;
            teamStats[match.opponent2!.id]!.roundsWon += match.opponent2Score!;
            teamStats[match.opponent2!.id]!.roundsLost += match.opponent1Score!;
          } else if (match.winnerId == match.opponent2!.id) {
            // İkinci takım kazandı
            teamStats[match.opponent2!.id]!.wins++;
            teamStats[match.opponent1!.id]!.losses++;
            teamStats[match.opponent2!.id]!.roundsWon += match.opponent2Score!;
            teamStats[match.opponent2!.id]!.roundsLost += match.opponent1Score!;
            teamStats[match.opponent1!.id]!.roundsWon += match.opponent1Score!;
            teamStats[match.opponent1!.id]!.roundsLost += match.opponent2Score!;
          }
        } else {
          _logger('Maç ID ${match.id} için eksik veri');
        }
      } catch (e) {
        _logger('Maç ID ${match.id} istatistiklerini hesaplarken hata: $e');
        // Hatayı yutuyoruz ama logluyoruz, böylece diğer maçlara devam edebiliriz
      }
    }

    return teamStats;
  }

  // Takım sıralamasını göster
  Widget _buildTeamStandings(List<MapEntry<int, TeamStats>> sortedTeams) {
    if (sortedTeams.isEmpty) {
      return _buildNoDataMessage(
        AppLocalization.of(context).translate('no_team_standings'),
      );
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(top: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Tablo başlıkları
            Row(
              children: [
                const SizedBox(width: 40),
                Expanded(
                  flex: 3,
                  child: Text(
                    AppLocalization.of(context).translate('team'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    AppLocalization.of(context).translate('w'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    AppLocalization.of(context).translate('l'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    AppLocalization.of(context).translate('net'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    AppLocalization.of(context).translate('k'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    AppLocalization.of(context).translate('y'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),

            const Divider(),

            // Takım sıralamaları
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedTeams.length,
              itemBuilder: (context, index) {
                try {
                  final teamEntry = sortedTeams[index];
                  final stats = teamEntry.value;
                  final team = stats.team;
                  // Net kazanç hesapla
                  final netScore = stats.wins - stats.losses;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              // Takım logosu; imageUrl null veya boş değilse network image göster, değilse varsayılan icon
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child:
                                    team.imageUrl != null &&
                                            team.imageUrl!.isNotEmpty
                                        ? Image.network(
                                          team.imageUrl!,
                                          width: 32,
                                          height: 32,
                                          fit: BoxFit.cover,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return Container(
                                              width: 32,
                                              height: 32,
                                              color:
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .surfaceContainerHighest,
                                              child: Icon(
                                                Icons.sports_esports,
                                                size: 16,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withOpacity(0.7),
                                              ),
                                            );
                                          },
                                        )
                                        : Container(
                                          width: 32,
                                          height: 32,
                                          color:
                                              Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                          child: Icon(
                                            Icons.sports_esports,
                                            size: 16,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.7),
                                          ),
                                        ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  team.name,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${stats.wins}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${stats.losses}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '$netScore',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  netScore > 0
                                      ? Colors.green
                                      : netScore < 0
                                      ? Colors.red
                                      : Colors.grey,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${stats.roundsWon}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${stats.roundsLost}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                } catch (e) {
                  _logger('Takım sıralaması gösterilirken hata: $e');
                  return const SizedBox.shrink(); // Hatalı satırı atla
                }
              },
            ),

            const SizedBox(height: 16),

            // Tablo açıklaması
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalization.of(context).translate('standings_info'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Tamamlanan maçları listele
  Widget _buildCompletedMatchesList(List<MatchModel> matches) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        return _buildMatchCard(matches[index]);
      },
    );
  }

  // Maç kartı widget'ı
  Widget _buildMatchCard(MatchModel match) {
    final bool isLive = match.status == 'running';
    final bool isFinished = match.status == 'finished';

    return Card(
      elevation: isLive ? 3 : 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            isLive
                ? BorderSide(color: Colors.red.shade400, width: 1.5)
                : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => MatchDetailsScreen(
                    matchId: match.id,
                    matchModel: match, // Maç modelini doğrudan geç
                  ),
            ),
          ).then((_) => _loadTournamentData());
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // Maç durumu ve zamanı
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Durum
                  _buildStatusChip(match),

                  // Zaman/Tarih
                  Text(
                    _getMatchTimestamp(match),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Takım bilgileri
              Row(
                children: [
                  // İlk takım
                  Expanded(
                    child: _buildTeamInfo(
                      match.opponent1,
                      match.opponent1Score,
                      alignment: Alignment.centerRight,
                      isWinner:
                          isFinished && match.opponent1?.id == match.winnerId,
                    ),
                  ),

                  // VS veya Skor
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          match.opponent1Score != null &&
                                  match.opponent2Score != null
                              ? '${match.opponent1Score} - ${match.opponent2Score}'
                              : 'vs',
                          style: TextStyle(
                            fontSize: isLive ? 20 : 16,
                            fontWeight: FontWeight.bold,
                            color:
                                isLive
                                    ? Colors.red
                                    : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        if (match.numberOfGames != null &&
                            match.numberOfGames! > 0) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'BO${match.numberOfGames}',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // İkinci takım
                  Expanded(
                    child: _buildTeamInfo(
                      match.opponent2,
                      match.opponent2Score,
                      alignment: Alignment.centerLeft,
                      isWinner:
                          isFinished && match.opponent2?.id == match.winnerId,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Takım bilgisi widget'ı
  Widget _buildTeamInfo(
    TeamModel? team,
    int? score, {
    Alignment alignment = Alignment.center,
    bool isWinner = false,
  }) {
    if (team == null) {
      return const Center(
        child: Text(
          'TBD',
          style: TextStyle(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment:
          alignment == Alignment.centerRight
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment:
              alignment == Alignment.centerRight
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
          children: [
            if (alignment == Alignment.centerLeft) _buildTeamLogo(team),

            SizedBox(width: alignment == Alignment.center ? 0 : 8),

            Flexible(
              child: Text(
                team.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                  color:
                      isWinner
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign:
                    alignment == Alignment.centerRight
                        ? TextAlign.right
                        : TextAlign.left,
              ),
            ),

            SizedBox(width: alignment == Alignment.center ? 0 : 8),

            if (alignment == Alignment.centerRight) _buildTeamLogo(team),
          ],
        ),
      ],
    );
  }

  // Takım logosu widget'ı
  Widget _buildTeamLogo(TeamModel team) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipOval(
        child:
            team.imageUrl != null && team.imageUrl!.isNotEmpty
                ? Image.network(
                  team.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => Icon(
                        Icons.sports_esports,
                        size: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.7),
                      ),
                )
                : Icon(
                  Icons.sports_esports,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                ),
      ),
    );
  }

  // Durum çipi widget'ı
  Widget _buildStatusChip(MatchModel match) {
    final String status = match.status ?? 'unknown';
    Color chipColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'running':
        chipColor = Colors.red;
        statusIcon = Icons.fiber_manual_record;
        statusText = AppLocalization.of(context).translate('status_live');
        break;
      case 'not_started':
        chipColor = Colors.blue;
        statusIcon = Icons.schedule;
        statusText = AppLocalization.of(
          context,
        ).translate('status_not_started');
        break;
      case 'finished':
        chipColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        statusText = AppLocalization.of(context).translate('status_finished');
        break;
      case 'cancelled':
        chipColor = Colors.grey;
        statusIcon = Icons.cancel_outlined;
        statusText = AppLocalization.of(context).translate('status_canceled');
        break;
      case 'postponed':
        chipColor = Colors.orange;
        statusIcon = Icons.update;
        statusText = AppLocalization.of(context).translate('status_postponed');
        break;
      default:
        chipColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.5), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 12, color: chipColor),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }

  // Maç zaman bilgisi
  String _getMatchTimestamp(MatchModel match) {
    if (match.status == 'running') {
      return AppLocalization.of(context).translate('canlı');
    }

    if (match.beginAt == null) {
      return AppLocalization.of(context).translate('bilinmiyor');
    }

    final now = DateTime.now();
    final matchDate = match.beginAt!;
    final isToday =
        matchDate.year == now.year &&
        matchDate.month == now.month &&
        matchDate.day == now.day;

    final isTomorrow =
        DateTime(now.year, now.month, now.day + 1).year == matchDate.year &&
        DateTime(now.year, now.month, now.day + 1).month == matchDate.month &&
        DateTime(now.year, now.month, now.day + 1).day == matchDate.day;

    final time =
        '${matchDate.hour.toString().padLeft(2, '0')}:${matchDate.minute.toString().padLeft(2, '0')}';

    if (isToday) {
      return '${AppLocalization.of(context).translate('today')}, $time';
    } else if (isTomorrow) {
      return '${AppLocalization.of(context).translate('tomorrow')}, $time';
    } else {
      return '${matchDate.day.toString().padLeft(2, '0')}/${matchDate.month.toString().padLeft(2, '0')}/${matchDate.year}, $time';
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

// Takım istatistikleri sınıfı
class TeamStats {
  final TeamModel team;
  int wins;
  int losses;
  int roundsWon;
  int roundsLost;

  TeamStats({
    required this.team,
    required this.wins,
    required this.losses,
    required this.roundsWon,
    required this.roundsLost,
  });

  int get totalMatches => wins + losses;

  double get winRate => totalMatches > 0 ? (wins / totalMatches) * 100 : 0;
}
