// CS2 maçı modelini temsil eder

import 'team_model.dart';
import 'tournament_model.dart';
import '../utils/logger.dart';

// Stream model
class StreamModel {
  final bool? main;
  final String? language;
  final String? embedUrl;
  final bool? official;
  final String? rawUrl;

  StreamModel({
    this.main,
    this.language,
    this.embedUrl,
    this.official,
    this.rawUrl,
  });

  factory StreamModel.fromJson(Map<String, dynamic> json) {
    return StreamModel(
      main: json['main'] as bool?,
      language: json['language'] as String?,
      embedUrl: json['embed_url'] as String?,
      official: json['official'] as bool?,
      rawUrl: json['raw_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'main': main,
      'language': language,
      'embed_url': embedUrl,
      'official': official,
      'raw_url': rawUrl,
    };
  }
}

class MatchModel {
  final int id;
  final String? name;
  final String? status;
  final int? winnerId;
  final int? numberOfGames;
  final String? matchType;
  final TournamentModel? tournament;
  final LeagueModel? league;
  final TeamModel? opponent1;
  final TeamModel? opponent2;
  final int? opponent1Score;
  final int? opponent2Score;
  final DateTime? beginAt;
  final DateTime? endAt;
  final List<GameModel>? games;
  final SerieModel? serie;
  final String? liveUrl;
  final List<StreamModel>? streams;

  MatchModel({
    required this.id,
    this.name,
    this.status,
    this.winnerId,
    this.numberOfGames,
    this.matchType,
    this.tournament,
    this.league,
    this.opponent1,
    this.opponent2,
    this.opponent1Score,
    this.opponent2Score,
    this.beginAt,
    this.endAt,
    this.games,
    this.serie,
    this.liveUrl,
    this.streams,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    // Opponents listesinden takımları çıkart
    List<dynamic>? opponents = json['opponents'] as List<dynamic>?;
    TeamModel? opponent1;
    TeamModel? opponent2;
    int? opponent1Score;
    int? opponent2Score;

    if (opponents != null && opponents.isNotEmpty) {
      try {
        if (opponents.isNotEmpty) {
          final firstOpponent = opponents[0];
          if (firstOpponent != null &&
              firstOpponent['opponent'] != null &&
              firstOpponent['opponent'] is Map<String, dynamic>) {
            opponent1 = TeamModel.fromJson(
              firstOpponent['opponent'] as Map<String, dynamic>,
            );
          }
        }

        if (opponents.length > 1) {
          final secondOpponent = opponents[1];
          if (secondOpponent != null &&
              secondOpponent['opponent'] != null &&
              secondOpponent['opponent'] is Map<String, dynamic>) {
            opponent2 = TeamModel.fromJson(
              secondOpponent['opponent'] as Map<String, dynamic>,
            );
          }
        }
      } catch (e) {
        Logger.error('Opponents parse error: $e');
      }
    }

    // Sonuçlardan skorları çıkart
    List<dynamic>? results = json['results'] as List<dynamic>?;
    if (results != null && results.length > 1) {
      try {
        opponent1Score = results[0]['score'] as int?;
        opponent2Score = results[1]['score'] as int?;
      } catch (e) {
        Logger.error('Results parse error: $e');
      }
    }

    // Games listesini işle
    List<dynamic>? gamesList = json['games'] as List<dynamic>?;
    List<GameModel>? games;
    if (gamesList != null) {
      try {
        games =
            gamesList
                .map(
                  (gameJson) =>
                      GameModel.fromJson(gameJson as Map<String, dynamic>),
                )
                .toList();
      } catch (e) {
        Logger.error('Games parse error: $e');
      }
    }

    // Streams listesini işle
    List<dynamic>? streamsList = json['streams_list'] as List<dynamic>?;
    List<StreamModel>? streams;
    if (streamsList != null) {
      try {
        streams =
            streamsList
                .map(
                  (streamJson) =>
                      StreamModel.fromJson(streamJson as Map<String, dynamic>),
                )
                .toList();
      } catch (e) {
        Logger.error('Streams parse error: $e');
      }
    }

    // Live URL ayarla
    String? liveUrl;
    if (json['live'] != null && json['live']['url'] != null) {
      liveUrl = json['live']['url'] as String?;
    }

    // Stream listesinden daha iyi bir URL çıkarmaya çalış
    if ((liveUrl == null || liveUrl.isEmpty) &&
        streams != null &&
        streams.isNotEmpty) {
      // Önce official ve main olan stream'i bul
      StreamModel? officialStream = streams.firstWhere(
        (stream) => stream.official == true && stream.main == true,
        orElse: () => StreamModel(rawUrl: null),
      );

      // Eğer official stream yoksa, herhangi bir main stream'i bul
      if (officialStream.rawUrl == null) {
        officialStream = streams.firstWhere(
          (stream) => stream.main == true,
          orElse: () => StreamModel(rawUrl: null),
        );
      }

      // Hala yoksa, ilk stream'i al
      if (officialStream.rawUrl == null && streams.isNotEmpty) {
        officialStream = streams.first;
      }

      // Raw URL'yi tercih et, yoksa embed URL'den çıkar
      if (officialStream.rawUrl != null && officialStream.rawUrl!.isNotEmpty) {
        liveUrl = officialStream.rawUrl;
      } else if (officialStream.embedUrl != null &&
          officialStream.embedUrl!.isNotEmpty) {
        // Embed URL'yi raw URL'ye dönüştürmeyi dene
        final embedUrl = officialStream.embedUrl!;
        if (embedUrl.contains('youtube.com/embed/')) {
          final videoId = embedUrl.split('/').last;
          liveUrl = 'https://www.youtube.com/watch?v=$videoId';
        } else if (embedUrl.contains('player.twitch.tv')) {
          final channelOrVideoId = embedUrl.split('=').last;
          liveUrl = 'https://www.twitch.tv/$channelOrVideoId';
        } else {
          liveUrl = embedUrl;
        }
      }
    }

    return MatchModel(
      id: json['id'] as int,
      name: json['name'] as String?,
      status: json['status'] as String?,
      winnerId: json['winner_id'] as int?,
      numberOfGames: json['number_of_games'] as int?,
      matchType: json['match_type'] as String?,
      tournament:
          json['tournament'] != null
              ? TournamentModel.fromJson(
                json['tournament'] as Map<String, dynamic>,
              )
              : null,
      league:
          json['league'] != null
              ? LeagueModel.fromJson(json['league'] as Map<String, dynamic>)
              : null,
      opponent1: opponent1,
      opponent2: opponent2,
      opponent1Score: opponent1Score,
      opponent2Score: opponent2Score,
      beginAt:
          json['begin_at'] != null
              ? DateTime.parse(json['begin_at'] as String)
              : null,
      endAt:
          json['end_at'] != null
              ? DateTime.parse(json['end_at'] as String)
              : null,
      games: games,
      serie:
          json['serie'] != null
              ? SerieModel.fromJson(json['serie'] as Map<String, dynamic>)
              : null,
      liveUrl: liveUrl,
      streams: streams,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'winner_id': winnerId,
      'number_of_games': numberOfGames,
      'match_type': matchType,
      'tournament': tournament?.toJson(),
      'league': league?.toJson(),
      'opponent1': opponent1?.toJson(),
      'opponent2': opponent2?.toJson(),
      'opponent1_score': opponent1Score,
      'opponent2_score': opponent2Score,
      'begin_at': beginAt?.toIso8601String(),
      'end_at': endAt?.toIso8601String(),
      'games': games?.map((game) => game.toJson()).toList(),
      'serie': serie?.toJson(),
      'live_url': liveUrl,
      'streams': streams?.map((stream) => stream.toJson()).toList(),
    };
  }
}

class LeagueModel {
  final int id;
  final String name;
  final String? imageUrl;
  final String? url;

  LeagueModel({required this.id, required this.name, this.imageUrl, this.url});

  factory LeagueModel.fromJson(Map<String, dynamic> json) {
    try {
      return LeagueModel(
        id: json['id'] ?? 0,
        name: json['name'] ?? 'Bilinmeyen Lig',
        imageUrl: json['image_url'],
        url: json['url'],
      );
    } catch (e) {
      Logger.error('LeagueModel.fromJson hata: $e');
      return LeagueModel(id: json['id'] ?? 0, name: 'Hata: Veri alınamadı');
    }
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'image_url': imageUrl, 'url': url};
  }
}

class SerieModel {
  final int id;
  final String name;
  final DateTime? beginAt;
  final DateTime? endAt;
  final String? season;
  final String? description;
  final String? fullName;

  SerieModel({
    required this.id,
    required this.name,
    this.beginAt,
    this.endAt,
    this.season,
    this.description,
    this.fullName,
  });

  factory SerieModel.fromJson(Map<String, dynamic> json) {
    try {
      return SerieModel(
        id: json['id'] ?? 0,
        name: json['name'] ?? 'Bilinmeyen Seri',
        beginAt:
            json['begin_at'] != null ? DateTime.parse(json['begin_at']) : null,
        endAt: json['end_at'] != null ? DateTime.parse(json['end_at']) : null,
        season: json['season'],
        description: json['description'],
        fullName: json['full_name'],
      );
    } catch (e) {
      Logger.error('SerieModel.fromJson hata: $e');
      return SerieModel(id: json['id'] ?? 0, name: 'Hata: Veri alınamadı');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'begin_at': beginAt?.toIso8601String(),
      'end_at': endAt?.toIso8601String(),
      'season': season,
      'description': description,
      'full_name': fullName,
    };
  }
}

class GameModel {
  final int id;
  final String? status;
  final String? winner;
  final int? winnerId;
  final int? opponentId1;
  final int? opponentId2;
  final int? opponent1Score;
  final int? opponent2Score;
  final String? map;
  final bool? hasDetailedStats;

  GameModel({
    required this.id,
    this.status,
    this.winner,
    this.winnerId,
    this.opponentId1,
    this.opponentId2,
    this.opponent1Score,
    this.opponent2Score,
    this.map,
    this.hasDetailedStats,
  });

  factory GameModel.fromJson(Map<String, dynamic> json) {
    try {
      var id = json['id'] ?? 0;
      var status = json['status'];
      var winner = json['winner'] != null ? json['winner']['type'] : null;
      var winnerId = json['winner'] != null ? json['winner']['id'] : null;

      // Rakip ID'leri
      int? opponentId1;
      if (json['opponents'] != null &&
          json['opponents'] is List &&
          json['opponents'].isNotEmpty &&
          json['opponents'][0] != null &&
          json['opponents'][0]['opponent'] != null) {
        opponentId1 = json['opponents'][0]['opponent']['id'];
      }

      int? opponentId2;
      if (json['opponents'] != null &&
          json['opponents'] is List &&
          json['opponents'].length > 1 &&
          json['opponents'][1] != null &&
          json['opponents'][1]['opponent'] != null) {
        opponentId2 = json['opponents'][1]['opponent']['id'];
      }

      // Skor bilgileri
      int? opponent1Score;
      if (json['results'] != null &&
          json['results'] is List &&
          json['results'].isNotEmpty &&
          json['results'][0] != null) {
        opponent1Score = json['results'][0]['score'];
      }

      int? opponent2Score;
      if (json['results'] != null &&
          json['results'] is List &&
          json['results'].length > 1 &&
          json['results'][1] != null) {
        opponent2Score = json['results'][1]['score'];
      }

      // Harita bilgisi
      String? map;
      bool? hasDetailedStats;

      if (json['detailed_stats'] != null) {
        hasDetailedStats = true;
        if (json['detailed_stats'] is Map<String, dynamic>) {
          map = json['detailed_stats']['map'];
        }
      } else {
        hasDetailedStats = false;
      }

      return GameModel(
        id: id,
        status: status,
        winner: winner,
        winnerId: winnerId,
        opponentId1: opponentId1,
        opponentId2: opponentId2,
        opponent1Score: opponent1Score,
        opponent2Score: opponent2Score,
        map: map,
        hasDetailedStats: hasDetailedStats,
      );
    } catch (e) {
      Logger.error('GameModel.fromJson hata: $e');
      return GameModel(id: json['id'] ?? 0, status: 'error');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'winner': winner,
      'winner_id': winnerId,
      'opponent_id1': opponentId1,
      'opponent_id2': opponentId2,
      'opponent1_score': opponent1Score,
      'opponent2_score': opponent2Score,
      'map': map,
      'has_detailed_stats': hasDetailedStats,
    };
  }
}
