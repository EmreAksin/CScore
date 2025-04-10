// PandaScore API ile iletişimi sağlar

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../constants/api_constants.dart';
import '../models/match_model.dart';
import '../models/team_model.dart';
import '../models/tournament_model.dart';
import '../models/tournament_bracket_model.dart';
import '../models/tournament_standings_model.dart';
import 'cache_service.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  late final Dio _dio;
  final Logger _logger = Logger();
  final CacheService _cacheService = CacheService();

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.pandaScoreBaseUrl,
        connectTimeout: const Duration(
          milliseconds: ApiConstants.connectTimeout,
        ),
        receiveTimeout: const Duration(
          milliseconds: ApiConstants.receiveTimeout,
        ),
        headers: {
          'Authorization': 'Bearer ${ApiConstants.pandaScoreApiKey}',
          'Accept': 'application/json',
        },
        validateStatus: (status) => true,
      ),
    );

    // Istek ve yanıt logları için interceptor - sadece debug modunda çalışır
    if (kDebugMode) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            _logger.i('REQUEST[${options.method}] => PATH: ${options.path}');
            return handler.next(options);
          },
          onResponse: (response, handler) {
            _logger.i(
              'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
            );
            return handler.next(response);
          },
          onError: (DioException e, handler) {
            _logger.e(
              'ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}',
            );
            return handler.next(e);
          },
        ),
      );
    }

    // Uygulama başlatıldığında süresi dolmuş önbelleği temizle
    _clearExpiredCache();
  }

  // Süresi dolmuş önbelleği temizle
  Future<void> _clearExpiredCache() async {
    await _cacheService.clearExpiredCache();
  }

  // Canlı maçları getir - Önbelleksiz
  Future<List<MatchModel>> getLiveMatches() async {
    // Önbellek yerine doğrudan API'den veri al
    return _fetchLiveMatches();
  }

  // Canlı maçları API'den getir
  Future<List<MatchModel>> _fetchLiveMatches() async {
    try {
      final response = await _dio.get(
        ApiConstants.cs2MatchesEndpoint,
        queryParameters: {
          'filter[status]': 'running',
          'sort': ApiConstants.defaultSort,
          'per_page': 50, // Daha fazla maç yükle
        },
      );

      if (response.statusCode == 200) {
        // Gelen veriyi kontrol et
        final dynamic responseData = response.data;
        _logger.i('Canlı maçlar API yanıtı: Tür=${responseData.runtimeType}');

        // Yanıt boşsa boş liste döndür
        if (responseData == null) {
          _logger.w('Canlı maçlar için yanıt boş. Boş liste döndürülüyor.');
          return [];
        }

        // Yanıt liste değilse boş liste döndür
        if (responseData is! List) {
          _logger.e(
            'Canlı maçlar yanıtı liste değil: ${responseData.runtimeType}. Boş liste döndürülüyor.',
          );
          return [];
        }

        final List dataList = responseData;
        _logger.i('Canlı maçlar listesi: ${dataList.length} öğe içeriyor');

        // Skor bilgilerini kontrol et ve logla
        for (var match in dataList) {
          if (match is Map<String, dynamic>) {
            _logger.d('Maç #${match['id']} Sonuçlar: ${match['results']}');
          }
        }

        // Her bir öğeyi MatchModel'e dönüştür, dönüştürülemeyenleri atla
        final List<MatchModel> matches = [];
        for (var item in dataList) {
          try {
            if (item is Map<String, dynamic>) {
              final model = MatchModel.fromJson(item);
              matches.add(model);
            } else {
              _logger.w(
                'Atlanıyor: item Map<String, dynamic> değil: ${item.runtimeType}',
              );
            }
          } catch (e) {
            _logger.e('Maç modeli oluşturulurken hata: $e');
            // Hatayı yut ve bir sonraki öğeye geç
          }
        }

        _logger.i('Dönüştürülen MatchModel sayısı: ${matches.length}');
        return matches;
      } else {
        throw Exception(
          'Canlı maçlar alınırken bir hata oluştu: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('Canlı maçlar alınırken hata: $e');
      return []; // Hata durumunda boş liste döndür
    }
  }

  // Yaklaşan maçları getir - Önbelleksiz
  Future<List<MatchModel>> getUpcomingMatches({
    int page = 1,
    int perPage = 100,
  }) async {
    // Önbellek yerine doğrudan API'den veri al
    return _fetchUpcomingMatches(page: page, perPage: perPage);
  }

  // Yaklaşan maçları API'den getir
  Future<List<MatchModel>> _fetchUpcomingMatches({
    int page = 1,
    int perPage = 100,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.cs2MatchesEndpoint,
        queryParameters: {
          'filter[status]': 'not_started',
          'sort': ApiConstants.defaultSort,
          'page': page,
          'per_page': perPage,
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((item) => MatchModel.fromJson(item)).toList();
      } else {
        throw Exception(
          'Yaklaşan maçlar alınırken bir hata oluştu: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('Yaklaşan maçlar alınırken hata: $e');
      rethrow;
    }
  }

  // Tamamlanan maçları getir - Önbelleksiz
  Future<List<MatchModel>> getPastMatches({
    int page = 1,
    int perPage = 100,
  }) async {
    // Önbellek yerine doğrudan API'den veri al
    return _fetchPastMatches(page: page, perPage: perPage);
  }

  // Tamamlanan maçları API'den getir
  Future<List<MatchModel>> _fetchPastMatches({
    int page = 1,
    int perPage = 100,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.cs2MatchesEndpoint,
        queryParameters: {
          'filter[status]': 'finished',
          'sort': '-${ApiConstants.defaultSort}',
          'page': page,
          'per_page': perPage,
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((item) => MatchModel.fromJson(item)).toList();
      } else {
        throw Exception(
          'Geçmiş maçlar alınırken bir hata oluştu: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('Geçmiş maçlar alınırken hata: $e');
      rethrow;
    }
  }

  // Maç detaylarını getir - Önbelleksiz
  Future<MatchModel?> getMatchDetails(int matchId) async {
    // Önbellek yerine doğrudan API'den veri al
    return _fetchMatchDetails(matchId);
  }

  // Maç detaylarını API'den getir
  Future<MatchModel?> _fetchMatchDetails(int matchId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.cs2MatchesEndpoint}/$matchId',
      );

      if (response.statusCode == 200) {
        return MatchModel.fromJson(response.data);
      } else if (response.statusCode == 403) {
        _logger.w(
          'Maç detaylarına erişim yok. API sınırlaması veya izin sorunu: $matchId',
        );
        return null;
      } else if (response.statusCode == 404) {
        _logger.w('Maç bulunamadı: $matchId');
        return null;
      } else {
        _logger.e(
          'Maç detayları alınırken beklenmeyen durum kodu: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      _logger.e('Maç detayları alınırken hata: $e');
      return null;
    }
  }

  // Tüm takımları getir - Önbelleksiz
  Future<List<TeamModel>> getTeams({
    int page = 1,
    int perPage = 25,
    String? search,
  }) async {
    // Önbellek yerine doğrudan API'den veri al
    return _fetchTeams(page: page, perPage: perPage, search: search);
  }

  // Takımları API'den getir
  Future<List<TeamModel>> _fetchTeams({
    int page = 1,
    int perPage = 25,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'per_page': perPage};

      // Eğer arama metni varsa, API'ye search parametresi ekle
      if (search != null && search.isNotEmpty) {
        queryParams['search[name]'] = search;
      }

      _logger.i(
        'Takımlar API isteği başlatılıyor: Sayfa=$page, PerPage=$perPage, Arama=${search ?? "Yok"}',
      );

      final response = await _dio.get(
        ApiConstants.cs2TeamsEndpoint,
        queryParameters: queryParams,
      );

      _logger.i('Takımlar API yanıt kodu: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Yanıt veri tipini kontrol et
        if (response.data == null) {
          _logger.w('API null veri döndürdü');
          return [];
        }

        if (response.data is! List) {
          _logger.w(
            'API beklenmeyen veri formatı döndürdü: ${response.data.runtimeType}',
          );
          return [];
        }

        List<dynamic> data = response.data;
        _logger.i('API\'den ${data.length} takım alındı');

        if (data.isEmpty) {
          _logger.i('API\'den boş liste döndü (sayfa sonu olabilir)');
          return [];
        }

        // Her bir takım için fromJson dönüşümünü kontrol et
        List<TeamModel> teams = [];
        for (var item in data) {
          try {
            teams.add(TeamModel.fromJson(item));
          } catch (parseError) {
            _logger.e('Takım verisini ayrıştırma hatası: $parseError');
            // Hatayı atlayıp devam et
          }
        }

        _logger.i('${teams.length} takım başarıyla ayrıştırıldı');
        return teams;
      } else {
        _logger.e('Takımlar alınırken HTTP hatası: ${response.statusCode}');
        throw Exception(
          'Takımlar alınırken bir hata oluştu: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('Takımlar alınırken hata: $e');
      // Hata ayrıntılarını logla ama boş liste döndür
      return [];
    }
  }

  // Takım detaylarını getir - Önbelleksiz
  Future<TeamModel?> getTeamDetails(int teamId) async {
    // Önbellek yerine doğrudan API'den veri al
    return _fetchTeamDetails(teamId);
  }

  // Takım detaylarını API'den getir
  Future<TeamModel?> _fetchTeamDetails(int teamId) async {
    try {
      _logger.i(
        'Takım detayları isteniyor: $teamId - Endpoint: ${ApiConstants.cs2TeamsEndpoint}?filter[id]=$teamId',
      );

      // Doğru API endpoint formatı kullanılıyor
      final response = await _dio.get(
        ApiConstants.cs2TeamsEndpoint,
        queryParameters: {'filter[id]': teamId},
      );

      // Log response status ve içerik
      _logger.i('Takım detayları yanıt kodu: ${response.statusCode}');
      _logger.d('Takım detayları yanıt: ${response.data}');

      if (response.statusCode == 200) {
        if (response.data is List && (response.data as List).isNotEmpty) {
          _logger.i('Takım detayları başarıyla alındı: $teamId');
          return TeamModel.fromJson(
            (response.data as List).first as Map<String, dynamic>,
          );
        } else if (response.data is List && (response.data as List).isEmpty) {
          _logger.w('Takım bulunamadı (boş liste): $teamId');
          return null;
        } else {
          _logger.i('Takım detayları başarıyla alındı (tekil): $teamId');
          return TeamModel.fromJson(response.data as Map<String, dynamic>);
        }
      } else if (response.statusCode == 403) {
        _logger.w(
          'Takım detaylarına erişim yok. API sınırlaması veya izin sorunu: $teamId',
        );

        // Takım detaylarını alternatifte deneme
        try {
          final altResponse = await _dio.get(
            ApiConstants.cs2TeamsEndpoint,
            queryParameters: {'filter[id]': teamId},
          );

          if (altResponse.statusCode == 200) {
            final List<dynamic> data = altResponse.data;
            if (data.isNotEmpty) {
              _logger.i('Takım detayları alternatif ile alındı: $teamId');
              return TeamModel.fromJson(data.first);
            }
          }
        } catch (e) {
          _logger.e('Alternatif ile takım detayları alınamadı: $e');
        }
        return null;
      } else if (response.statusCode == 404) {
        _logger.w('Takım bulunamadı: $teamId');
        return null;
      } else {
        _logger.e(
          'Takım detayları alınırken beklenmeyen durum kodu: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      _logger.e('Takım detayları alınırken hata: $e');
      return null;
    }
  }

  // Takımın maçlarını getir - Önbelleksiz
  Future<List<MatchModel>> getTeamMatches(
    int teamId, {
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int perPage = 20,
  }) async {
    // Önbellek yerine doğrudan API'den veri al
    return _fetchTeamMatches(
      teamId,
      status: status ?? 'all',
      page: page,
      perPage: perPage,
    );
  }

  // Belirli bir anahtar kümesindeki önbellekleri temizle
  Future<void> invalidateCache(String keyPattern) async {
    final db = await _cacheService.database;
    final keys = await db.query(
      'api_cache',
      columns: ['key'],
      where: 'key LIKE ?',
      whereArgs: ['%$keyPattern%'],
    );

    for (final key in keys) {
      await _cacheService.removeFromCache(key['key'] as String);
    }

    _logger.i('Önbellek temizlendi: $keyPattern');
  }

  // Önbellek boyutunu hesapla
  Future<String> getCacheSize() async {
    return await _cacheService.getCacheSize();
  }

  // Tüm önbelleği temizle
  Future<void> clearAllCache() async {
    await _cacheService.clearAllCacheIncludingImages();
  }

  // Görsel dosyasını önbellekten al
  Future<String> getImageCacheUrl(String url) async {
    if (url.isEmpty) return '';

    try {
      final file = await _cacheService.getImageFromCache(url);
      return file.path;
    } catch (e) {
      _logger.e('Görsel önbellekten alınamadı: $e');
      return url;
    }
  }

  // Tüm ligleri getir
  Future<List<LeagueModel>> getLeagues({int page = 1, int perPage = 25}) async {
    try {
      final response = await _dio.get(
        ApiConstants.cs2LeaguesEndpoint,
        queryParameters: {'page': page, 'per_page': perPage},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((item) => LeagueModel.fromJson(item)).toList();
      } else {
        throw Exception(
          'Ligler alınırken bir hata oluştu: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('Ligler alınırken hata: $e');
      rethrow;
    }
  }

  // Lig detaylarını getir
  Future<LeagueModel> getLeagueDetails(int leagueId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.cs2LeaguesEndpoint}/$leagueId',
      );

      if (response.statusCode == 200) {
        return LeagueModel.fromJson(response.data);
      } else {
        throw Exception(
          'Lig detayları alınırken bir hata oluştu: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('Lig detayları alınırken hata: $e');
      rethrow;
    }
  }

  // Tüm turnuvaları getir
  Future<List<TournamentModel>> getTournaments({
    int page = 1,
    int perPage = 25,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.cs2TournamentsEndpoint,
        queryParameters: {
          'page': page,
          'per_page': perPage,
          'sort': ApiConstants.defaultSort,
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((item) => TournamentModel.fromJson(item)).toList();
      } else {
        throw Exception(
          'Turnuvalar alınırken bir hata oluştu: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('Turnuvalar alınırken hata: $e');
      rethrow;
    }
  }

  // Canlı (devam eden) turnuvaları getir
  Future<List<TournamentModel>> getLiveTournaments({
    int page = 1,
    int perPage = 25,
  }) async {
    try {
      _logger.i('Canlı turnuvalar isteniyor...');

      // CS2 endpoint'i ile istek
      try {
        final cs2Response = await _dio.get(
          ApiConstants.cs2AltRunningTournamentsEndpoint,
          queryParameters: {
            'page': page,
            'per_page': perPage,
            'sort': ApiConstants.defaultSort,
          },
        );

        // CS2 endpoint'i başarılı olursa bu verileri kullan
        if (cs2Response.statusCode == 200) {
          List<dynamic> data = cs2Response.data;
          final result =
              data.map((item) => TournamentModel.fromJson(item)).toList();
          _logger.i('${result.length} CS2 canlı turnuva alındı');
          return result;
        }
      } catch (dioError) {
        _logger.e('CS2 canlı turnuvalar istek hatası: $dioError');
      }

      // Normal CSGO endpoint'i ile istek
      final response = await _dio.get(
        ApiConstants.cs2RunningTournamentsEndpoint,
        queryParameters: {
          'page': page,
          'per_page': perPage,
          'sort': ApiConstants.defaultSort,
        },
      );

      _logger.i('Canlı turnuvalar yanıt kodu: ${response.statusCode}');
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        final result =
            data.map((item) => TournamentModel.fromJson(item)).toList();
        _logger.i('${result.length} canlı turnuva alındı');
        return result;
      } else {
        throw Exception(
          'Canlı turnuvalar alınırken bir hata oluştu: ${response.statusCode} - ${response.data}',
        );
      }
    } catch (e) {
      _logger.e('Canlı turnuvalar alınırken hata: $e');
      rethrow;
    }
  }

  // Yaklaşan turnuvaları getir
  Future<List<TournamentModel>> getUpcomingTournaments({
    int page = 1,
    int perPage = 25,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.cs2UpcomingTournamentsEndpoint,
        queryParameters: {
          'page': page,
          'per_page': perPage,
          'sort': ApiConstants.defaultSort,
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((item) => TournamentModel.fromJson(item)).toList();
      } else {
        throw Exception(
          'Yaklaşan turnuvalar alınırken bir hata oluştu: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('Yaklaşan turnuvalar alınırken hata: $e');
      rethrow;
    }
  }

  // Tamamlanan turnuvaları getir
  Future<List<TournamentModel>> getPastTournaments({
    int page = 1,
    int perPage = 25,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.cs2PastTournamentsEndpoint,
        queryParameters: {
          'page': page,
          'per_page': perPage,
          'sort': '-${ApiConstants.defaultSort}',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((item) => TournamentModel.fromJson(item)).toList();
      } else {
        throw Exception(
          'Tamamlanan turnuvalar alınırken bir hata oluştu: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('Tamamlanan turnuvalar alınırken hata: $e');
      rethrow;
    }
  }

  // Turnuva detaylarını getir
  Future<TournamentModel> getTournamentDetails(int tournamentId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.cs2TournamentsEndpoint}/$tournamentId',
      );

      if (response.statusCode == 200) {
        return TournamentModel.fromJson(response.data);
      } else {
        throw Exception(
          'Turnuva detayları alınırken bir hata oluştu: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('Turnuva detayları alınırken hata: $e');
      rethrow;
    }
  }

  // Turnuvadaki maçları getir
  Future<List<MatchModel>> getMatchesByTournament(int tournamentId) async {
    try {
      final response = await _dio.get(
        ApiConstants.cs2MatchesEndpoint,
        queryParameters: {
          'filter[tournament_id]': tournamentId,
          'sort': ApiConstants.defaultSort,
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((item) => MatchModel.fromJson(item)).toList();
      } else {
        throw Exception(
          'Turnuva maçları alınırken bir hata oluştu: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('Turnuva maçları alınırken hata: $e');
      rethrow;
    }
  }

  // Turnuva bracket'ını (eleme tablosunu) getir
  Future<List<TournamentBracketModel>> getTournamentBrackets(
    int tournamentId,
  ) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.cs2TournamentsEndpoint}/$tournamentId/${ApiConstants.cs2TournamentBracketsEndpoint}',
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data
            .map((item) => TournamentBracketModel.fromJson(item))
            .toList();
      } else {
        throw Exception(
          'Turnuva bracket\'ı alınırken bir hata oluştu: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('Turnuva bracket\'ı alınırken hata: $e');
      rethrow;
    }
  }

  // Turnuva sıralamasını (standinglerini) getir
  Future<TournamentStandingsModel> getTournamentStandings(
    int tournamentId,
  ) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.cs2TournamentsEndpoint}/$tournamentId/${ApiConstants.cs2TournamentStandingsEndpoint}',
      );

      if (response.statusCode == 200) {
        return TournamentStandingsModel.fromJson(response.data);
      } else {
        throw Exception(
          'Turnuva sıralaması alınırken bir hata oluştu: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('Turnuva sıralaması alınırken hata: $e');
      rethrow;
    }
  }

  // Turnuvadaki takımları getir
  Future<List<TeamModel>> getTournamentTeams(int tournamentId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.cs2TournamentsEndpoint}/$tournamentId/${ApiConstants.cs2TournamentTeamsEndpoint}',
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((item) => TeamModel.fromJson(item)).toList();
      } else {
        throw Exception(
          'Turnuva takımları alınırken bir hata oluştu: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('Turnuva takımları alınırken hata: $e');
      rethrow;
    }
  }

  // Takımın maçlarını getir
  Future<List<MatchModel>> _fetchTeamMatches(
    int teamId, {
    String status = 'all',
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final params = {
        'filter[opponent_id]': teamId,
        'page': page,
        'per_page': perPage,
        'sort': '-begin_at',
      };

      // Durum filtresi ekle
      if (status != 'all') {
        params['filter[status]'] = status;
      }

      final response = await _dio.get('/matches', queryParameters: params);

      final List<dynamic> matchesData = response.data;
      return matchesData
          .map((matchData) => MatchModel.fromJson(matchData))
          .toList();
    } on DioException catch (e) {
      _logger.e('Takım maçları API hatası: ${e.message}');
      throw Exception(
        'Takım maçları yüklenirken bir hata oluştu: ${e.message}',
      );
    } catch (e) {
      _logger.e('Takım maçları alınırken hata: $e');
      throw Exception('Takım maçları yüklenirken beklenmeyen bir hata oluştu');
    }
  }
}
