// CS2 turnuva modelini temsil eder

import '../utils/logger.dart';
import 'match_model.dart';

class TournamentModel {
  final int id;
  final String name;
  final DateTime? beginAt;
  final DateTime? endAt;
  final String? prizepool;
  final String? tier;
  final String? imageUrl;
  final int? leagueId;
  final String? leagueName;
  final String? status;
  final String? slug;
  final SerieModel? serie;

  TournamentModel({
    required this.id,
    required this.name,
    this.beginAt,
    this.endAt,
    this.prizepool,
    this.tier,
    this.imageUrl,
    this.leagueId,
    this.leagueName,
    this.status,
    this.slug,
    this.serie,
  });

  factory TournamentModel.fromJson(Map<String, dynamic> json) {
    try {
      // Lig bilgisini al
      int? leagueId;
      String? leagueName;
      if (json['league'] != null && json['league'] is Map) {
        leagueId = json['league']['id'];
        leagueName = json['league']['name'];
      }

      // Serie bilgisini al
      SerieModel? serie;
      if (json['serie'] != null && json['serie'] is Map) {
        serie = SerieModel.fromJson(json['serie']);
      }

      return TournamentModel(
        id: json['id'] ?? 0,
        name: json['name'] ?? 'Bilinmeyen Turnuva',
        beginAt:
            json['begin_at'] != null ? DateTime.parse(json['begin_at']) : null,
        endAt: json['end_at'] != null ? DateTime.parse(json['end_at']) : null,
        prizepool: json['prizepool'],
        tier: json['tier'],
        imageUrl: json['league']?['image_url'] ?? json['image_url'],
        leagueId: leagueId,
        leagueName: leagueName,
        status: _determineStatus(
          json['begin_at'] != null ? DateTime.parse(json['begin_at']) : null,
          json['end_at'] != null ? DateTime.parse(json['end_at']) : null,
        ),
        slug: json['slug'],
        serie: serie,
      );
    } catch (e) {
      Logger.error('TournamentModel.fromJson hata: $e');
      return TournamentModel(id: 0, name: 'Hata: Veri alınamadı');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'begin_at': beginAt?.toIso8601String(),
      'end_at': endAt?.toIso8601String(),
      'prizepool': prizepool,
      'tier': tier,
      'image_url': imageUrl,
      'league_id': leagueId,
      'league_name': leagueName,
      'status': status,
      'slug': slug,
    };
  }

  // Turnuvanın mevcut durumunu hesaplar
  static String? _determineStatus(DateTime? beginAt, DateTime? endAt) {
    if (beginAt == null) return null;

    final now = DateTime.now();

    if (beginAt.isAfter(now)) {
      return 'not_started';
    } else if (endAt == null || endAt.isAfter(now)) {
      return 'running';
    } else {
      return 'finished';
    }
  }

  // Turnuva durumunu çevrilebilir olarak döndür
  String get statusText {
    if (status == null || status!.isEmpty) {
      return 'bilinmiyor';
    }
    return status!.toLowerCase();
  }

  // Slug'ı formatlanmış turnuva adı olarak dönüştür
  String get formattedName {
    if (slug == null || slug!.isEmpty) {
      return name; // Slug yoksa orijinal ismi kullan
    }

    // Çizgileri boşluklara çevir
    String formatted = slug!.replaceAll('-', ' ');

    // Her kelimenin ilk harfini büyüt
    List<String> words = formatted.split(' ');

    // Her kelimeyi işle ve özel durumları yönet
    for (int i = 0; i < words.length; i++) {
      if (words[i].isEmpty) continue;

      if (words[i].toLowerCase() == 'cs' &&
          i + 1 < words.length &&
          words[i + 1].toLowerCase() == 'go') {
        // CS GO özel durumu - her iki kelimeyi de büyük harf yap
        words[i] = 'CS';
        words[i + 1] = 'GO';
        i++; // GO kelimesini atla
      } else if (words[i].toLowerCase() == 'csgo') {
        // "csgo" kelimesini "CS GO" olarak değiştir
        words[i] = 'CS GO';
      } else {
        // Normal kelimeler için ilk harfi büyüt
        words[i] = words[i][0].toUpperCase() + words[i].substring(1);
      }
    }

    return words.join(' ');
  }
}
