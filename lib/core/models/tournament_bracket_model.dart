// CS2 turnuva bracket modelini temsil eder

import '../utils/logger.dart';

class TournamentBracketModel {
  final int id;
  final String name;
  final String type;
  final List<BracketMatchModel> matches;

  TournamentBracketModel({
    required this.id,
    required this.name,
    required this.type,
    required this.matches,
  });

  factory TournamentBracketModel.fromJson(Map<String, dynamic> json) {
    try {
      List<BracketMatchModel> matches = [];
      if (json['matches'] != null && json['matches'] is List) {
        matches =
            (json['matches'] as List)
                .map((match) => BracketMatchModel.fromJson(match))
                .toList();
      }

      return TournamentBracketModel(
        id: json['id'] ?? 0,
        name: json['name'] ?? 'Bilinmeyen Eleme Tablosu',
        type: json['type'] ?? 'unknown',
        matches: matches,
      );
    } catch (e) {
      Logger.error('TournamentBracketModel.fromJson hata: $e');
      return TournamentBracketModel(
        id: 0,
        name: 'Hata: Veri alınamadı',
        type: 'error',
        matches: [],
      );
    }
  }
}

class BracketMatchModel {
  final int id;
  final int position;
  final int? nextMatchId;
  final int? opponent1Id;
  final int? opponent2Id;
  final int? winnerId;
  final String status;

  BracketMatchModel({
    required this.id,
    required this.position,
    this.nextMatchId,
    this.opponent1Id,
    this.opponent2Id,
    this.winnerId,
    required this.status,
  });

  factory BracketMatchModel.fromJson(Map<String, dynamic> json) {
    try {
      int? opponent1Id;
      int? opponent2Id;

      if (json['opponents'] != null && json['opponents'] is List) {
        if (json['opponents'].length > 0 &&
            json['opponents'][0] != null &&
            json['opponents'][0]['opponent'] != null) {
          opponent1Id = json['opponents'][0]['opponent']['id'];
        }

        if (json['opponents'].length > 1 &&
            json['opponents'][1] != null &&
            json['opponents'][1]['opponent'] != null) {
          opponent2Id = json['opponents'][1]['opponent']['id'];
        }
      }

      return BracketMatchModel(
        id: json['id'] ?? 0,
        position: json['position'] ?? 0,
        nextMatchId: json['next_match_id'],
        opponent1Id: opponent1Id,
        opponent2Id: opponent2Id,
        winnerId: json['winner_id'],
        status: json['status'] ?? 'unknown',
      );
    } catch (e) {
      Logger.error('BracketMatchModel.fromJson hata: $e');
      return BracketMatchModel(id: 0, position: 0, status: 'error');
    }
  }
}
