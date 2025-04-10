import '../utils/logger.dart';

// CS2 takımı modelini temsil eder

class TeamModel {
  final int id;
  final String name;
  final String acronym;
  final String? logoUrl;
  final String? imageUrl;
  final String? location;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<PlayerModel>? players;

  TeamModel({
    required this.id,
    required this.name,
    required this.acronym,
    this.logoUrl,
    this.imageUrl,
    this.location,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.players,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    try {
      List<PlayerModel>? playersList;

      if (json['players'] != null && json['players'] is List) {
        playersList = [];
        for (var player in json['players']) {
          if (player != null) {
            try {
              playersList.add(PlayerModel.fromJson(player));
            } catch (e) {
              // Oyuncu dönüştürülürken hata olursa loglayıp devam et
              Logger.error('Player dönüştürme hatası: $e');
            }
          }
        }
      }

      // current_videogame kontrol et
      String? statusText;
      if (json['current_videogame'] != null &&
          json['current_videogame'] is Map) {
        String? gameName = json['current_videogame']['name'];
        statusText = gameName == 'CS:GO' ? 'CS2' : gameName;
      }

      return TeamModel(
        id: json['id'] ?? 0,
        name: json['name'] ?? 'Bilinmeyen Takım',
        acronym: json['acronym'] ?? '',
        logoUrl: json['image_url'],
        imageUrl: json['image_url'],
        location: json['location'],
        status: statusText,
        createdAt:
            json['created_at'] != null
                ? DateTime.parse(json['created_at'])
                : null,
        updatedAt:
            json['modified_at'] != null
                ? DateTime.parse(json['modified_at'])
                : null,
        players: playersList,
      );
    } catch (e) {
      Logger.error('TeamModel.fromJson hata: $e');
      return TeamModel(
        id: json['id'] ?? 0,
        name: json['name'] ?? 'Hata: Veri alınamadı',
        acronym: '',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'acronym': acronym,
      'logo_url': logoUrl,
      'image_url': imageUrl,
      'location': location,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'players': players?.map((player) => player.toJson()).toList(),
    };
  }
}

class PlayerModel {
  final int id;
  final String name;
  final String? firstName;
  final String? lastName;
  final String? imageUrl;
  final String? nationality;
  final String? role;
  final DateTime? birthday;

  PlayerModel({
    required this.id,
    required this.name,
    this.firstName,
    this.lastName,
    this.imageUrl,
    this.nationality,
    this.role,
    this.birthday,
  });

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    try {
      return PlayerModel(
        id: json['id'] ?? 0,
        name: json['name'] ?? 'Bilinmeyen Oyuncu',
        firstName: json['first_name'],
        lastName: json['last_name'],
        imageUrl: json['image_url'],
        nationality: json['nationality'],
        role: json['role'],
        birthday:
            json['birth_date'] != null
                ? DateTime.parse(json['birth_date'])
                : null,
      );
    } catch (e) {
      Logger.error('PlayerModel.fromJson hata: $e');
      return PlayerModel(id: 0, name: 'Hata: Veri alınamadı');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'first_name': firstName,
      'last_name': lastName,
      'image_url': imageUrl,
      'nationality': nationality,
      'role': role,
      'birth_date': birthday?.toIso8601String(),
    };
  }
}
