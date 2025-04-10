// CS2 turnuva standings modelini temsil eder

import '../utils/logger.dart';

class TournamentStandingsModel {
  final List<StandingGroupModel> groups;

  TournamentStandingsModel({required this.groups});

  factory TournamentStandingsModel.fromJson(List<dynamic> json) {
    try {
      List<StandingGroupModel> groups = [];
      for (var groupJson in json) {
        groups.add(StandingGroupModel.fromJson(groupJson));
      }
      return TournamentStandingsModel(groups: groups);
    } catch (e) {
      Logger.error('TournamentStandingsModel.fromJson hata: $e');
      return TournamentStandingsModel(groups: []);
    }
  }
}

class StandingGroupModel {
  final String name;
  final List<StandingRowModel> rows;

  StandingGroupModel({required this.name, required this.rows});

  factory StandingGroupModel.fromJson(Map<String, dynamic> json) {
    try {
      List<StandingRowModel> rows = [];
      if (json['rows'] != null && json['rows'] is List) {
        rows =
            (json['rows'] as List)
                .map((row) => StandingRowModel.fromJson(row))
                .toList();
      }

      return StandingGroupModel(
        name: json['name'] ?? 'Bilinmeyen Grup',
        rows: rows,
      );
    } catch (e) {
      Logger.error('StandingGroupModel.fromJson hata: $e');
      return StandingGroupModel(name: 'Hata: Veri alınamadı', rows: []);
    }
  }
}

class StandingRowModel {
  final int position;
  final int teamId;
  final String teamName;
  final String? teamAcronym;
  final String? teamLogoUrl;
  final int wins;
  final int draws;
  final int losses;
  final int gamesPlayed;
  final int gamesWon;
  final int matchesPlayed;
  final int matchesWon;
  final int points;

  StandingRowModel({
    required this.position,
    required this.teamId,
    required this.teamName,
    this.teamAcronym,
    this.teamLogoUrl,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.gamesPlayed,
    required this.gamesWon,
    required this.matchesPlayed,
    required this.matchesWon,
    required this.points,
  });

  factory StandingRowModel.fromJson(Map<String, dynamic> json) {
    try {
      int teamId = 0;
      String teamName = 'Bilinmeyen Takım';
      String? teamAcronym;
      String? teamLogoUrl;

      if (json['team'] != null) {
        teamId = json['team']['id'] ?? 0;
        teamName = json['team']['name'] ?? 'Bilinmeyen Takım';
        teamAcronym = json['team']['acronym'];
        teamLogoUrl = json['team']['image_url'];
      }

      return StandingRowModel(
        position: json['position'] ?? 0,
        teamId: teamId,
        teamName: teamName,
        teamAcronym: teamAcronym,
        teamLogoUrl: teamLogoUrl,
        wins: json['wins'] ?? 0,
        draws: json['draws'] ?? 0,
        losses: json['losses'] ?? 0,
        gamesPlayed: json['games_played'] ?? 0,
        gamesWon: json['games_won'] ?? 0,
        matchesPlayed: json['matches_played'] ?? 0,
        matchesWon: json['matches_won'] ?? 0,
        points: json['points'] ?? 0,
      );
    } catch (e) {
      Logger.error('StandingRowModel.fromJson hata: $e');
      return StandingRowModel(
        position: 0,
        teamId: 0,
        teamName: 'Hata: Veri alınamadı',
        wins: 0,
        draws: 0,
        losses: 0,
        gamesPlayed: 0,
        gamesWon: 0,
        matchesPlayed: 0,
        matchesWon: 0,
        points: 0,
      );
    }
  }
}
