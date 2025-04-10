import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/match_model.dart';
import '../../../core/utils/app_localization.dart';
import '../../../core/utils/date_formatter.dart';
import '../screens/match_details_screen.dart';
import '../../tournaments/screens/tournament_detail_screen.dart';
import '../../tournaments/providers/tournaments_provider.dart';
import '../../../core/widgets/cached_image.dart';
import '../../../core/extensions/country_code_extension.dart';

class MatchCard extends StatelessWidget {
  final MatchModel match;
  final Function()? onTap;
  final bool showTournament;
  final bool isFavorite;
  final Function? onDelete;
  final bool showDetailAction;

  const MatchCard({
    super.key,
    required this.match,
    this.onTap,
    this.showTournament = true,
    this.isFavorite = false,
    this.onDelete,
    this.showDetailAction = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasScores =
        match.opponent1Score != null && match.opponent2Score != null;
    final isLive = match.status == 'running'; // Canlı maç kontrolü
    final theme = Theme.of(context);

    // Tarihi formatla
    String formattedDate = DateFormatter.formatMatchTime(
      context,
      match.beginAt,
      showTime: true,
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      elevation: 1.5,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withAlpha(26), width: 1),
      ),
      child: InkWell(
        onTap:
            onTap ??
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => MatchDetailsScreen(
                      matchId: match.id,
                      matchModel: match,
                    ),
              ),
            ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lig ve durum satırı
              Row(
                children: [
                  // Lig ismi ve logosu
                  if (match.league?.imageUrl != null) ...[
                    CachedImage(
                      imageUrl: match.league!.imageUrl!,
                      width: 16,
                      height: 16,
                      backgroundColor: Colors.transparent,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      match.league?.name ??
                          match.name ??
                          AppLocalization.of(
                            context,
                          ).translate('unknown_match'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withAlpha(179),
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Maç durumu
                  _buildStatusChip(context, match),
                ],
              ),

              // Takım bilgileri
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    // Takım 1
                    Expanded(
                      child: Row(
                        children: [
                          // Takım Logosu
                          Container(
                            width: 40,
                            height: 40,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: theme.dividerColor.withAlpha(13),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: CachedImage(
                              imageUrl: match.opponent1?.imageUrl ?? '',
                              fit: BoxFit.contain,
                              borderRadius: BorderRadius.circular(6),
                              errorWidget: Icon(
                                Icons.sports_esports,
                                color: theme.colorScheme.primary.withAlpha(179),
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Takım İsmi
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  match.opponent1?.name ??
                                      AppLocalization.of(
                                        context,
                                      ).translate('unknown_team'),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (match.opponent1?.location != null) ...[
                                  Text(
                                    match.opponent1!.location!.isEmpty
                                        ? '🌍'
                                        : match.opponent1!.location!
                                            .toFlagEmoji(),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Skor
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child:
                          hasScores
                              ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isLive
                                          ? Colors.red.withAlpha(26)
                                          : theme.dividerColor.withAlpha(26),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "${match.opponent1Score ?? '?'} - ${match.opponent2Score ?? '?'}",
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isLive
                                            ? Colors.red.withAlpha(26)
                                            : theme.colorScheme.primary
                                                .withAlpha(26),
                                  ),
                                ),
                              )
                              : isLive
                              ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withAlpha(26),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "VS",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.withAlpha(26),
                                  ),
                                ),
                              )
                              : Text(
                                formattedDate,
                                style: theme.textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                    ),

                    // Takım 2
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Takım İsmi
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  match.opponent2?.name ??
                                      AppLocalization.of(
                                        context,
                                      ).translate('unknown_team'),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.end,
                                ),
                                if (match.opponent2?.location != null) ...[
                                  Text(
                                    match.opponent2!.location!.isEmpty
                                        ? '🌍'
                                        : match.opponent2!.location!
                                            .toFlagEmoji(),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Takım Logosu
                          Container(
                            width: 40,
                            height: 40,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: theme.dividerColor.withAlpha(13),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: CachedImage(
                              imageUrl: match.opponent2?.imageUrl ?? '',
                              fit: BoxFit.contain,
                              borderRadius: BorderRadius.circular(6),
                              errorWidget: Icon(
                                Icons.sports_esports,
                                color: theme.colorScheme.primary.withAlpha(179),
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Turnuva bilgisi
              if (showTournament && match.tournament != null) ...[
                const SizedBox(height: 2),
                InkWell(
                  onTap: () async {
                    if (match.tournament?.id != null) {
                      final tournamentsProvider =
                          Provider.of<TournamentsProvider>(
                            context,
                            listen: false,
                          );

                      // Turnuva detaylarını önceden getir
                      final tournament = await tournamentsProvider
                          .getTournamentDetails(match.tournament!.id);

                      if (!context.mounted) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => TournamentDetailScreen(
                                tournamentId: match.tournament!.id,
                                tournamentName: match.tournament!.name,
                                preloadedTournament: tournament,
                              ),
                        ),
                      );
                    }
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 14,
                        color: theme.textTheme.bodySmall?.color?.withAlpha(179),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          match.tournament?.name ?? '-',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withAlpha(
                              179,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: theme.textTheme.bodySmall?.color?.withAlpha(179),
                      ),
                    ],
                  ),
                ),
              ],

              // Favorilerden silme butonu
              if (isFavorite && onDelete != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () => onDelete!(),
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

              // Detay butonu
              if (showDetailAction)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => MatchDetailsScreen(
                                    matchId: match.id,
                                    matchModel: match,
                                  ),
                            ),
                          ),
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: Text(
                        AppLocalization.of(context).translate('match_details'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
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

  // Durum etiketi
  Widget _buildStatusChip(BuildContext context, MatchModel match) {
    final status = match.status ?? 'unknown';
    final theme = Theme.of(context);

    Color chipColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'running':
        chipColor = Colors.red;
        statusText = AppLocalization.of(context).translate('match_live');
        statusIcon = Icons.fiber_manual_record;
        break;
      case 'finished':
        chipColor = Colors.green;
        statusText = AppLocalization.of(context).translate('finished');
        statusIcon = Icons.check_circle_outline;
        break;
      case 'not_started':
        chipColor = Colors.blue;
        statusText = AppLocalization.of(context).translate('upcoming');
        statusIcon = Icons.schedule;
        break;
      default:
        chipColor = Colors.grey;
        statusText = AppLocalization.of(context).translate('unknown');
        statusIcon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withAlpha(38),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 10, color: chipColor),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: chipColor,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
