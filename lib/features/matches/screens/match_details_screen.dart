import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/match_model.dart';
import '../../../core/models/team_model.dart';
import '../../../core/utils/app_localization.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/color_extensions.dart';
import '../providers/matches_provider.dart';
import '../../tournaments/screens/tournament_detail_screen.dart';
import '../../teams/screens/team_detail_screen.dart';
import 'package:flutter/services.dart';
import '../../tournaments/providers/tournaments_provider.dart';

class MatchDetailsScreen extends StatefulWidget {
  final int matchId;
  final MatchModel? matchModel; // Doğrudan maç modeli alabilir

  const MatchDetailsScreen({
    super.key,
    required this.matchId,
    this.matchModel, // Opsiyonel model
  });

  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> {
  final _logger = Logger('MatchDetailsScreen');
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  MatchModel? _match;

  @override
  void initState() {
    super.initState();
    // Eğer direkt model geçildiyse, API'ye istek atma
    if (widget.matchModel != null) {
      setState(() {
        _match = widget.matchModel;
        _isLoading = false;
      });
    } else {
      _loadMatchDetails();
    }
  }

  Future<void> _loadMatchDetails() async {
    try {
      // Önce local provider'dan maç bilgisini almayı deneyelim
      final matchesProvider = Provider.of<MatchesProvider>(
        context,
        listen: false,
      );

      // Canlı, yaklaşan ve tamamlanan maçlar listesinde arama yapalım
      MatchModel? matchData;

      for (var match in matchesProvider.liveMatches) {
        if (match.id == widget.matchId) {
          matchData = match;
          break;
        }
      }

      if (matchData == null) {
        for (var match in matchesProvider.upcomingMatches) {
          if (match.id == widget.matchId) {
            matchData = match;
            break;
          }
        }
      }

      if (matchData == null) {
        for (var match in matchesProvider.pastMatches) {
          if (match.id == widget.matchId) {
            matchData = match;
            break;
          }
        }
      }

      // Provider'dan veri bulunamadıysa API'den almayı deneyelim
      if (matchData == null) {
        try {
          matchData = await matchesProvider.getMatchDetails(widget.matchId);
        } catch (e) {
          // API hatasını işleyeceğiz, ama önce lokalden alabildik mi kontrol edelim
        }
      }

      if (!mounted) return;

      if (matchData != null) {
        setState(() {
          _match = matchData;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Maç detayları bulunamadı';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Maç detayları yüklenirken hata oluştu: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isLoading
              ? AppLocalization.of(context).translate('match_details')
              : _hasError
              ? AppLocalization.of(context).translate('error')
              : _match!.name ??
                  AppLocalization.of(context).translate('match_details'),
        ),
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _hasError
              ? _buildErrorWidget()
              : _buildMatchDetailsWidget(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalization.of(context).translate('api_limit_info'),
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _loadMatchDetails,
                child: Text(AppLocalization.of(context).translate('try_again')),
              ),
              const SizedBox(width: 16),
              if (_match?.tournament != null)
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => TournamentDetailScreen(
                              tournamentId: _match!.tournament!.id,
                              tournamentName: _match!.tournament!.name,
                            ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.emoji_events_outlined),
                  label: Text(
                    AppLocalization.of(context).translate('view_tournament'),
                  ),
                ),
              if (_match?.tournament == null)
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: Text(AppLocalization.of(context).translate('go_back')),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchDetailsWidget() {
    if (_match == null) return const SizedBox();

    // Maç durum rengini belirle
    Color statusColor;
    switch (_match!.status) {
      case 'running':
        statusColor = Colors.green;
        break;
      case 'not_started':
        statusColor = Colors.blue;
        break;
      case 'finished':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Turnuva / Lig Bilgisi (Üst Kısımda)
          if (_match!.tournament != null || _match!.league != null)
            _buildTournamentInfo(),

          // Durum bilgisi
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tarih/Saat
                Text(
                  _match!.beginAt != null
                      ? _formatDateTime(_match!.beginAt!)
                      : 'Tarih bilgisi yok',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                // Durum
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacitySafe(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusText(_match!.status ?? 'unknown'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Takımlar ve Skor
          _buildTeamsSection(),

          // Oyunlar (Maplar) başlığı
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              AppLocalization.of(context).translate('maps'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),

          // Oyunlar (Maplar) - ListView.builder yerine Column ve List.generate kullanarak
          _buildMapsList(),

          // Ek Bilgiler - Kart şeklinde göster
          _buildMatchDetailsCard(),

          // Alt kısım için boşluk
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTournamentInfo() {
    return GestureDetector(
      onTap:
          _match!.tournament != null
              ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => TournamentDetailScreen(
                          tournamentId: _match!.tournament!.id,
                          tournamentName: _match!.tournament!.name,
                        ),
                  ),
                );
              }
              : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacitySafe(0.15),
              Theme.of(context).colorScheme.surface,
            ],
          ),
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacitySafe(0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events_outlined,
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _match!.tournament?.name ??
                        _match!.league?.name ??
                        'Turnuva/Lig bilgisi yok',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_match!.serie?.name != null &&
                      _match!.serie!.name.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _match!.serie!.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_match!.tournament != null)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withOpacitySafe(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamsSection() {
    if (_match == null) return const SizedBox();

    bool isLiveMatch = _match!.status == 'running';
    bool hasLiveUrl = _match!.liveUrl != null && _match!.liveUrl!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Canlı maç için live badge ve canlı izle butonu
          if (isLiveMatch) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacitySafe(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.withOpacitySafe(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalization.of(
                          context,
                        ).translate('match_live').toUpperCase(),
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Canlı izle butonu
            if (hasLiveUrl)
              Column(
                children: [
                  // Canlı izleme açıklaması
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacitySafe(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.amber.withOpacitySafe(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppLocalization.of(
                              context,
                            ).translate('live_stream_info'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _openLiveStream,
                    icon: const Icon(Icons.live_tv_rounded),
                    label: Text(
                      AppLocalization.of(context).translate('watch_live'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),

            if (hasLiveUrl) const SizedBox(height: 16),
          ],

          // Takımlar ve skorlar
          Row(
            children: [
              // Birinci takım
              Expanded(
                child: _buildTeamColumn(
                  _match!.opponent1,
                  _match!.opponent1Score,
                  isWinner:
                      _match!.winnerId == _match!.opponent1?.id &&
                      _match!.status == 'finished',
                ),
              ),

              // Maç durumu
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // VS veya Skor
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _match!.opponent1Score != null &&
                                    _match!.opponent2Score != null
                                ? '${_match!.opponent1Score} - ${_match!.opponent2Score}'
                                : 'vs',
                            style: TextStyle(
                              fontSize: isLiveMatch ? 20 : 16,
                              fontWeight: FontWeight.bold,
                              color:
                                  isLiveMatch
                                      ? Colors.red
                                      : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          if (_match!.numberOfGames != null &&
                              _match!.numberOfGames! > 0) ...[
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
                                'BO${_match!.numberOfGames}',
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

                    // Maç formatı (BO3, BO5 vb.)
                    if (_match!.serie != null &&
                        _match!.serie!.name.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _match!.serie!.name,
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
                child: _buildTeamColumn(
                  _match!.opponent2,
                  _match!.opponent2Score,
                  isWinner:
                      _match!.winnerId == _match!.opponent2?.id &&
                      _match!.status == 'finished',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // URL'nin geçerli olup olmadığını kontrol eden yardımcı fonksiyon
  bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;

    // URL formatını doğrula
    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute && uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Widget _buildTeamColumn(
    TeamModel? team,
    int? score, {
    bool isWinner = false,
  }) {
    if (team == null) return const SizedBox();

    // URL kontrolü ekleyelim
    bool hasValidImageUrl = isValidImageUrl(team.imageUrl);

    return GestureDetector(
      onTap: () => _navigateToTeamDetail(team),
      child: Column(
        children: [
          // Logo
          Container(
            width: 72,
            height: 72,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border:
                  isWinner ? Border.all(color: Colors.green, width: 3) : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacitySafe(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child:
                hasValidImageUrl
                    ? ClipOval(
                      child: Image.network(
                        team.imageUrl!,
                        fit: BoxFit.contain,
                        errorBuilder:
                            (_, __, ___) => const Icon(
                              Icons.sports_esports,
                              size: 36,
                              color: Colors.grey,
                            ),
                      ),
                    )
                    : const Icon(
                      Icons.sports_esports,
                      size: 36,
                      color: Colors.grey,
                    ),
          ),
          const SizedBox(height: 12),
          // Takım adı
          Text(
            team.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color:
                  isWinner
                      ? Colors.green
                      : Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _navigateToTeamDetail(TeamModel? team) {
    if (team == null) return;

    // Takım detay sayfasına yönlendir
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TeamDetailScreen(teamId: team.id, teamName: team.name),
      ),
    );
  }

  Widget _buildMatchDetailsCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withOpacitySafe(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Text(
              AppLocalization.of(context).translate('match_details'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Turnuva/Lig bilgisi
            if (_match!.tournament != null)
              _buildDetailItemWithIcon(
                Icons.emoji_events_outlined,
                AppLocalization.of(context).translate('tournament'),
                _match!.tournament!.name,
                onTap: () async {
                  final tournamentsProvider = Provider.of<TournamentsProvider>(
                    context,
                    listen: false,
                  );

                  // Turnuva detaylarını önceden getir
                  final tournament = await tournamentsProvider
                      .getTournamentDetails(_match!.tournament!.id);

                  if (!mounted) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => TournamentDetailScreen(
                            tournamentId: _match!.tournament!.id,
                            tournamentName: _match!.tournament!.name,
                            preloadedTournament:
                                tournament, // Önceden yüklenen turnuva bilgisini geç
                          ),
                    ),
                  );
                },
              ),

            // Lig bilgisi
            if (_match!.league != null)
              _buildDetailItemWithIcon(
                Icons.shield_outlined,
                AppLocalization.of(context).translate('league'),
                _match!.league!.name,
              ),

            // Seri Bilgisi
            if (_match!.serie != null && _match!.serie!.name.isNotEmpty)
              _buildDetailItemWithIcon(
                Icons.format_list_numbered,
                AppLocalization.of(context).translate('series'),
                _match!.serie!.name,
              ),

            // Maç Tarihi
            if (_match!.beginAt != null)
              _buildDetailItemWithIcon(
                Icons.calendar_today,
                AppLocalization.of(context).translate('match_date'),
                _formatDateTime(_match!.beginAt!),
              ),

            // Canlı Yayın Linki
          ],
        ),
      ),
    );
  }

  // İkonlu detay satırı
  Widget _buildDetailItemWithIcon(
    IconData icon,
    String label,
    String value, {
    bool isLink = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              margin: const EdgeInsets.only(right: 12, top: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color:
                          (isLink || onTap != null)
                              ? Theme.of(context).colorScheme.primary
                              : null,
                      decoration: null,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper metotlar
  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'running':
        return AppLocalization.of(context).translate('status_live');
      case 'not_started':
        return AppLocalization.of(context).translate('status_not_started');
      case 'finished':
        return AppLocalization.of(context).translate('status_finished');
      default:
        return status.toUpperCase();
    }
  }

  Widget _buildMapsList() {
    if (_match!.games == null || _match!.games!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(AppLocalization.of(context).translate('no_maps_data')),
        ),
      );
    }

    return Column(
      children: List.generate(_match!.games!.length, (index) {
        final game = _match!.games![index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${AppLocalization.of(context).translate('map')} ${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getMapStatusColor(
                          game.status ?? 'unknown',
                          game.winnerId,
                        ).withOpacitySafe(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getMapStatusText(
                          game.status ?? 'unknown',
                          game.winnerId,
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getMapStatusColor(
                            game.status ?? 'unknown',
                            game.winnerId,
                          ),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (game.map != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.map_outlined, size: 16),
                      const SizedBox(width: 4),
                      Text(game.map!, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ],

                // Harita skoru göster
                if (game.opponent1Score != null &&
                    game.opponent2Score != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${_match!.opponent1?.name ?? AppLocalization.of(context).translate('team1')}: ${game.opponent1Score}",
                        style: TextStyle(
                          fontWeight:
                              game.winnerId == game.opponentId1
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                          color:
                              game.winnerId == game.opponentId1
                                  ? Colors.green
                                  : null,
                        ),
                      ),
                      const Text(" - "),
                      Text(
                        "${game.opponent2Score}: ${_match!.opponent2?.name ?? AppLocalization.of(context).translate('team2')}",
                        style: TextStyle(
                          fontWeight:
                              game.winnerId == game.opponentId2
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                          color:
                              game.winnerId == game.opponentId2
                                  ? Colors.green
                                  : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }

  // Harita durumu rengi
  Color _getMapStatusColor(String status, int? winnerId) {
    switch (status) {
      case 'running':
        return Colors.red; // Canlı için kırmızı
      case 'not_started':
        return Colors.blue; // Başlamamış için mavi
      case 'finished':
        return Colors.green; // Tamamlanmış için yeşil
      default:
        return Colors.grey; // Bilinmeyen durumlar için gri
    }
  }

  // Harita durumu metni
  String _getMapStatusText(String status, int? winnerId) {
    switch (status) {
      case 'running':
        return AppLocalization.of(context).translate('running');
      case 'not_started':
        return AppLocalization.of(context).translate('not_started');
      case 'finished':
        // Kazanan takım adını göster
        if (winnerId != null) {
          if (_match?.opponent1?.id == winnerId) {
            return "${_match!.opponent1!.name} ${AppLocalization.of(context).translate('won')}";
          } else if (_match?.opponent2?.id == winnerId) {
            return "${_match!.opponent2!.name} ${AppLocalization.of(context).translate('won')}";
          }
        }
        return AppLocalization.of(context).translate('finished');
      default:
        return status;
    }
  }

  // Debug mesajı
  void _showDebugMessage(String title, dynamic content) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: Text(content.toString())),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalization.of(context).translate('ok')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Alert Dialog ile URL'yi kullanıcıya gösterme
  void _showUrlDialog(String url) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.live_tv_rounded, color: Colors.red),
              const SizedBox(width: 8),
              Text(AppLocalization.of(context).translate('live_stream')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalization.of(context).translate('copy_url_instructions'),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () {
                  // URL'yi panoya kopyala
                  final data = ClipboardData(text: url);
                  Clipboard.setData(data);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalization.of(context).translate('url_copied'),
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          url,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.copy, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(AppLocalization.of(context).translate('cancel')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.open_in_browser),
              label: Text(
                AppLocalization.of(context).translate('open_browser'),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  final uri = Uri.parse(url);
                  // Eğer launchUrl başarısız olursa, dışarıda açılacak
                  await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                    webViewConfiguration: const WebViewConfiguration(
                      enableJavaScript: true,
                      enableDomStorage: true,
                    ),
                  );
                } catch (e) {
                  if (context.mounted) {
                    _showErrorMessage(
                      '${AppLocalization.of(context).translate('cant_open_url')}: $e',
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // URL açma işlemini gerçekleştir
  Future<void> _launchUrlWithFallback(String url) async {
    try {
      final uri = Uri.parse(url);
      _logger.d("Stream URL açılıyor: $uri");

      // İlk yöntem: Doğrudan URL açma
      bool canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        bool launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          // Açılamadıysa dialog göster
          if (context.mounted) {
            _showUrlDialog(url);
          }
        }
      } else {
        // Doğrudan açılamıyorsa Dialog göster
        if (context.mounted) {
          _showUrlDialog(url);
        }
      }
    } catch (e) {
      _logger.e('URL açılırken hata: $e');
      if (context.mounted) {
        // Hata durumunda URL'yi manuel olarak açma seçeneği sunan dialog göster
        _showUrlDialog(url);
      }
    }
  }

  // Canlı yayın URL'sini açma işlemi
  Future<void> _openLiveStream() async {
    if (!mounted) return;

    if (_match == null) {
      _showErrorMessage(
        AppLocalization.of(context).translate('no_live_stream'),
      );
      return;
    }

    // Debug bilgisi
    final streamInfo =
        _match!.streams != null
            ? "Streams: ${_match!.streams!.length} adet"
            : "Streams listesi bulunamadı";

    String? streamUrl;

    // 1. Önce streams_list içinde raw_url'yi kontrol et
    if (_match!.streams != null && _match!.streams!.isNotEmpty) {
      try {
        // İlk olarak YouTube kanallarını tercih et
        var youtubeStream = _match!.streams!.firstWhere(
          (stream) =>
              stream.rawUrl != null && stream.rawUrl!.contains('youtube'),
          orElse: () => StreamModel(),
        );

        if (youtubeStream.rawUrl != null && youtubeStream.rawUrl!.isNotEmpty) {
          streamUrl = youtubeStream.rawUrl;
          _logger.d("YouTube stream bulundu: $streamUrl");
        } else {
          // Herhangi bir stream'i al
          var anyStream = _match!.streams!.firstWhere(
            (stream) => stream.rawUrl != null && stream.rawUrl!.isNotEmpty,
            orElse: () => StreamModel(),
          );

          if (anyStream.rawUrl != null && anyStream.rawUrl!.isNotEmpty) {
            streamUrl = anyStream.rawUrl;
            _logger.d("Herhangi bir stream bulundu: $streamUrl");
          } else {
            // Raw URL yoksa embed URL'yi kontrol et
            var embedStream = _match!.streams!.firstWhere(
              (stream) =>
                  stream.embedUrl != null && stream.embedUrl!.isNotEmpty,
              orElse: () => StreamModel(),
            );

            if (embedStream.embedUrl != null &&
                embedStream.embedUrl!.isNotEmpty) {
              streamUrl = _convertEmbedToDirectUrl(embedStream.embedUrl!);
              _logger.d("Embed URL'den stream bulundu: $streamUrl");
            }
          }
        }
      } catch (e) {
        _logger.e('Stream seçimi hatası: $e');
      }
    }

    // 2. Streams listesinde bulunamadıysa liveUrl'yi dene
    if (streamUrl == null &&
        _match!.liveUrl != null &&
        _match!.liveUrl!.isNotEmpty) {
      streamUrl = _match!.liveUrl;
      _logger.d("Live URL kullanılıyor: $streamUrl");
    }

    // Debug bilgisi göster - geliştirme aşamasında yardımcı olması için
    if (streamUrl == null) {
      _showDebugMessage(
        "Canlı Yayın Bilgisi",
        "Hiçbir yayın URL'si bulunamadı.\n\n$streamInfo\n\nMatch ID: ${_match!.id}\nLiveUrl: ${_match!.liveUrl}",
      );
      return;
    }

    // URL açma işlemini yeni metotla gerçekleştir
    await _launchUrlWithFallback(streamUrl);
  }

  // Embed URL'yi direkt URL'ye çevirme
  String _convertEmbedToDirectUrl(String embedUrl) {
    if (embedUrl.contains('youtube.com/embed/')) {
      final videoId = embedUrl.split('/').last.split('?').first;
      return 'https://www.youtube.com/watch?v=$videoId';
    } else if (embedUrl.contains('player.twitch.tv')) {
      if (embedUrl.contains('?channel=')) {
        final channelName = embedUrl.split('?channel=').last.split('&').first;
        return 'https://www.twitch.tv/$channelName';
      } else if (embedUrl.contains('?video=')) {
        final videoId = embedUrl.split('?video=').last.split('&').first;
        return 'https://www.twitch.tv/videos/$videoId';
      }
    }
    return embedUrl;
  }

  // Hata mesajını gösterme
  void _showErrorMessage(String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: AppLocalization.of(context).translate('ok'),
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
