// Maç verilerini yönetmek için provider sınıfı

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../core/models/match_model.dart';
import '../../../core/services/api_service.dart';

enum MatchesStatus { initial, loading, loaded, error }

class MatchesProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final Logger _logger = Logger();

  // State variables
  List<MatchModel> _liveMatches = [];
  MatchesStatus _liveMatchesStatus = MatchesStatus.initial;
  String? _liveMatchesError;

  // Yaklaşan maçlar için state değişkenleri
  List<MatchModel> _upcomingMatches = [];
  MatchesStatus _upcomingMatchesStatus = MatchesStatus.initial;
  String? _upcomingMatchesError;
  int _upcomingMatchesPage = 1;
  bool _hasMoreUpcomingMatches = true;

  // Tamamlanan maçlar için state değişkenleri
  List<MatchModel> _pastMatches = [];
  MatchesStatus _pastMatchesStatus = MatchesStatus.initial;
  String? _pastMatchesError;
  int _pastMatchesPage = 1;
  bool _hasMorePastMatches = true;

  // Getters
  List<MatchModel> get liveMatches => _liveMatches;
  MatchesStatus get liveMatchesStatus => _liveMatchesStatus;
  String? get liveMatchesError => _liveMatchesError;

  List<MatchModel> get upcomingMatches => _upcomingMatches;
  MatchesStatus get upcomingMatchesStatus => _upcomingMatchesStatus;
  String? get upcomingMatchesError => _upcomingMatchesError;
  bool get hasMoreUpcomingMatches => _hasMoreUpcomingMatches;

  List<MatchModel> get pastMatches => _pastMatches;
  MatchesStatus get pastMatchesStatus => _pastMatchesStatus;
  String? get pastMatchesError => _pastMatchesError;
  bool get hasMorePastMatches => _hasMorePastMatches;

  // Yükleme durumları için getterlar
  bool get isLoadingMoreUpcoming =>
      _upcomingMatchesStatus == MatchesStatus.loading &&
      _upcomingMatchesPage > 1;
  bool get isLoadingMorePast =>
      _pastMatchesStatus == MatchesStatus.loading && _pastMatchesPage > 1;

  // Canlı maçların gruplandırılmış hali
  Map<String, List<MatchModel>> get liveMatchesByLeague {
    return _groupMatchesByLeague(_liveMatches);
  }

  // Yaklaşan maçların gruplandırılmış hali
  Map<String, List<MatchModel>> get upcomingMatchesByLeague {
    return _groupMatchesByLeague(_upcomingMatches);
  }

  // Tamamlanan maçların gruplandırılmış hali
  Map<String, List<MatchModel>> get pastMatchesByLeague {
    return _groupMatchesByLeague(_pastMatches);
  }

  // Maçları liglere göre grupla
  Map<String, List<MatchModel>> _groupMatchesByLeague(
    List<MatchModel> matches,
  ) {
    final Map<String, List<MatchModel>> grouped = {};
    // Liglerin tier değerlerini saklamak için
    final Map<String, String> leagueTiers = {};

    for (final match in matches) {
      // Lig adı yoksa "Diğer" grubuna ekle
      final leagueName = match.league?.name ?? 'Diğer';
      final tierValue = match.tournament?.tier?.toLowerCase() ?? 'unranked';

      // League key
      final key = leagueName;

      // Lig için tier değerini belirle
      if (!leagueTiers.containsKey(key)) {
        leagueTiers[key] = tierValue;
      }

      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }

      grouped[key]!.add(match);
    }

    // Ligleri önce tier seviyesine göre sırala, aynı tier içinde alfabetik sırala
    final sortedKeys =
        grouped.keys.toList()..sort((a, b) {
          // Tier sıralaması: S > A > B > C > D > Unranked
          final tierA = leagueTiers[a] ?? 'unranked';
          final tierB = leagueTiers[b] ?? 'unranked';

          // Tier değerlerini sayısal değerlere dönüştür
          // S=5, A=4, B=3, C=2, D=1, unranked=0
          final tierValueA = _getTierValue(tierA);
          final tierValueB = _getTierValue(tierB);

          // Önce tier seviyesine göre sırala (yüksekten düşüğe)
          final tierCompare = tierValueA.compareTo(tierValueB);
          if (tierCompare != 0) {
            return -tierCompare;
          }

          // Aynı tier içindeyse, lig adına göre alfabetik sırala
          return a.compareTo(b);
        });

    // Sıralanmış key listesinden yeni bir Map oluştur
    final result = <String, List<MatchModel>>{};
    for (final key in sortedKeys) {
      result[key] = grouped[key]!;
    }

    return result;
  }

  // Tier değerini sayısal bir değere dönüştür
  int _getTierValue(String tier) {
    switch (tier.toLowerCase()) {
      case 's':
        return 5;
      case 'a':
        return 4;
      case 'b':
        return 3;
      case 'c':
        return 2;
      case 'd':
        return 1;
      default:
        return 0; // unranked veya bilinmeyen değer
    }
  }

  // Canlı maçları getir
  Future<void> getLiveMatches() async {
    _liveMatchesStatus = MatchesStatus.loading;
    _liveMatchesError = null;
    notifyListeners();

    try {
      // API'den doğrudan veri al
      final matches = await _apiService.getLiveMatches();

      // Hata olmadan veriler geldi
      _liveMatches = matches;
      _liveMatchesStatus = MatchesStatus.loaded;
      _logger.i('${matches.length} canlı maç yüklendi');
    } catch (e) {
      // Hata durumunu kaydet ve loga yaz
      _liveMatchesStatus = MatchesStatus.error;
      _liveMatchesError = 'Canlı maçlar yüklenirken hata oluştu: $e';
      _logger.e(_liveMatchesError);
      // Hata durumunda boş liste ataması yap
      _liveMatches = [];
    }

    notifyListeners();
  }

  // Yaklaşan maçları getir
  Future<void> getUpcomingMatches({bool refresh = false}) async {
    if (refresh) {
      _upcomingMatchesPage = 1;
      _hasMoreUpcomingMatches = true;
    }

    if (_upcomingMatchesStatus == MatchesStatus.loading ||
        (!_hasMoreUpcomingMatches && !refresh)) {
      return;
    }

    _upcomingMatchesStatus = MatchesStatus.loading;
    _upcomingMatchesError = null;

    if (_upcomingMatchesPage == 1) {
      _upcomingMatches = [];
    }

    notifyListeners();

    try {
      _logger.i('Yaklaşan maçlar yükleniyor - Sayfa: $_upcomingMatchesPage');

      final matches = await _apiService.getUpcomingMatches(
        page: _upcomingMatchesPage,
        perPage: 60, // 20'den 60'a çıkarıldı
      );

      if (matches.isEmpty) {
        _hasMoreUpcomingMatches = false;
        _logger.i('Daha fazla yaklaşan maç yok');
      } else {
        _upcomingMatchesPage++;
        if (refresh) {
          _upcomingMatches = matches;
        } else {
          _upcomingMatches.addAll(matches);
        }
      }

      _upcomingMatchesStatus = MatchesStatus.loaded;
      _logger.i(
        '${matches.length} yaklaşan maç yüklendi (Toplam: ${_upcomingMatches.length})',
      );
    } catch (e) {
      _upcomingMatchesStatus = MatchesStatus.error;
      _upcomingMatchesError = 'Yaklaşan maçlar yüklenirken hata oluştu: $e';
      _logger.e(_upcomingMatchesError);
      // Hata durumunda da UI'yi güncelle
      if (_upcomingMatchesPage == 1) {
        _upcomingMatches = []; // İlk sayfada hata varsa listeyi temizle
      }
    }

    notifyListeners();
  }

  // Tamamlanan maçları getir
  Future<void> getPastMatches({
    bool refresh = false,
    bool autoLoadMore = true,
    int targetCount = 200, // Hedeflenen toplam maç sayısı
  }) async {
    if (refresh) {
      _pastMatchesPage = 1;
      _hasMorePastMatches = true;
    }

    // Zaten yükleme yapılıyorsa ve ilk yükleme değilse bekle
    if (_pastMatchesStatus == MatchesStatus.loading &&
        !(_pastMatchesPage == 1 && refresh)) {
      return;
    }

    // Daha fazla maç yoksa ve yenileme yapmıyorsak çık
    if (!_hasMorePastMatches && !refresh) {
      return;
    }

    _pastMatchesStatus = MatchesStatus.loading;
    _pastMatchesError = null;

    if (_pastMatchesPage == 1) {
      _pastMatches = [];
    }

    notifyListeners();

    try {
      _logger.i(
        'Tamamlanmış maçlar yükleniyor - Sayfa: $_pastMatchesPage (ilk yükleme: $refresh, hedef: $targetCount)',
      );

      // Her zaman maksimum sayıda maç yükle
      const perPage = 100; // PandaScore API limiti

      final matches = await _apiService.getPastMatches(
        page: _pastMatchesPage,
        perPage: perPage,
      );

      if (matches.isEmpty) {
        _hasMorePastMatches = false;
        _logger.i('Daha fazla tamamlanmış maç yok');
      } else {
        if (refresh) {
          _pastMatches = matches;
        } else {
          _pastMatches.addAll(matches);
        }

        _pastMatchesPage++;

        _logger.i(
          '${matches.length} tamamlanan maç yüklendi (Toplam: ${_pastMatches.length})',
        );

        // Eğer hedeflenen maç sayısına ulaşılmadıysa ve daha fazla maç varsa otomatik olarak yükle
        if (autoLoadMore &&
            _pastMatches.length < targetCount &&
            _hasMorePastMatches &&
            matches.length == perPage) {
          _logger.i(
            'Otomatik olarak daha fazla maç yükleniyor. Şu anki toplam: ${_pastMatches.length}, Hedef: $targetCount',
          );

          // Durumu güncelleyelim ki kullanıcı arayüzüne yansısın
          _pastMatchesStatus = MatchesStatus.loaded;
          notifyListeners();

          // Kısa bir gecikme ekleyelim ki UI önce güncellensin ve işlemler sıkışmasın
          await Future.delayed(const Duration(milliseconds: 300));

          // Otomatik olarak bir sonraki sayfayı yükle
          await getPastMatches(
            refresh: false,
            autoLoadMore: true,
            targetCount: targetCount,
          );
          return; // Rekürsif çağrıdan sonra çıkalım
        }
      }

      _pastMatchesStatus = MatchesStatus.loaded;
    } catch (e) {
      _pastMatchesStatus = MatchesStatus.error;
      _pastMatchesError = 'Tamamlanan maçlar yüklenirken hata oluştu: $e';
      _logger.e(_pastMatchesError);
      // Hata durumunda da UI'yi güncelle
      if (_pastMatchesPage == 1) {
        _pastMatches = []; // İlk sayfada hata varsa listeyi temizle
      }
    }

    notifyListeners();
  }

  // Maç detaylarını getir
  Future<MatchModel?> getMatchDetails(int matchId) async {
    try {
      final match = await _apiService.getMatchDetails(matchId);
      if (match != null) {
        _logger.i('Maç detayları yüklendi: ${match.name}');
      } else {
        _logger.w('Maç detayları bulunamadı: $matchId');
      }
      return match;
    } catch (e) {
      _logger.e('Maç detayları yüklenirken hata oluştu: $e');
      return null;
    }
  }

  // Tüm maç verilerini yenile
  Future<void> refreshAllMatches() async {
    await getLiveMatches();
    await getUpcomingMatches(refresh: true);
    await getPastMatches(refresh: true, targetCount: 200);
  }

  // Belirli bir ligin adını al
  String getLeagueName(int leagueId) {
    // Özel durum: Lig bilgisi olmayan maçlar
    if (leagueId == 0) {
      return 'Diğer Maçlar';
    }

    // Tüm maç listelerini tara ve lig adını bul
    for (var match in _liveMatches) {
      if (match.league?.id == leagueId) {
        return match.league!.name;
      }
    }

    for (var match in _upcomingMatches) {
      if (match.league?.id == leagueId) {
        return match.league!.name;
      }
    }

    for (var match in _pastMatches) {
      if (match.league?.id == leagueId) {
        return match.league!.name;
      }
    }

    return 'Bilinmeyen Lig';
  }

  // Belirli bir ligin maç sayısını al
  int getMatchCountByLeague(int leagueId) {
    int count = 0;

    // Canlı maçlarda ara
    if (_liveMatches.any((match) => match.league?.id == leagueId)) {
      count++;
    }

    // Yaklaşan maçlarda ara
    if (_upcomingMatches.any((match) => match.league?.id == leagueId)) {
      count++;
    }

    // Tamamlanan maçlarda ara
    if (_pastMatches.any((match) => match.league?.id == leagueId)) {
      count++;
    }

    return count;
  }

  // Belirli bir ligin canlı maçlarını al
  List<MatchModel> getLiveMatchesByLeague(int leagueId) {
    return _liveMatches.where((match) => match.league?.id == leagueId).toList();
  }

  // Belirli bir ligin yaklaşan maçlarını al
  List<MatchModel> getUpcomingMatchesByLeague(int leagueId) {
    return _upcomingMatches
        .where((match) => match.league?.id == leagueId)
        .toList();
  }

  // Belirli bir ligin tamamlanan maçlarını al
  List<MatchModel> getPastMatchesByLeague(int leagueId) {
    return _pastMatches.where((match) => match.league?.id == leagueId).toList();
  }

  // Belirli bir lige ait tüm maçları al
  List<MatchModel> getAllMatchesByLeague(int leagueId) {
    final List<MatchModel> allMatches = [];

    // Canlı maçları ekle
    if (_liveMatches.any((match) => match.league?.id == leagueId)) {
      allMatches.addAll(
        _liveMatches.where((match) => match.league?.id == leagueId),
      );
    }

    // Yaklaşan maçları ekle
    if (_upcomingMatches.any((match) => match.league?.id == leagueId)) {
      allMatches.addAll(
        _upcomingMatches.where((match) => match.league?.id == leagueId),
      );
    }

    // Tamamlanan maçları ekle
    if (_pastMatches.any((match) => match.league?.id == leagueId)) {
      allMatches.addAll(
        _pastMatches.where((match) => match.league?.id == leagueId),
      );
    }

    return allMatches;
  }

  // Tüm ligleri getir
  List<int> getAllLeagueIds() {
    final Set<int> leagueIds = {};

    // Tüm lig ID'lerini topla
    leagueIds.addAll(_liveMatches.map((match) => match.league?.id ?? 0));
    leagueIds.addAll(_upcomingMatches.map((match) => match.league?.id ?? 0));
    leagueIds.addAll(_pastMatches.map((match) => match.league?.id ?? 0));

    return leagueIds.toList()
      ..sort((a, b) => a == 0 ? 1 : (b == 0 ? -1 : a.compareTo(b)));
  }

  // Takım maçlarını getir (canlı, yaklaşan veya geçmiş)
  Future<List<MatchModel>> getTeamMatches(
    int teamId, {
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final matches = await _apiService.getTeamMatches(
        teamId,
        status: status,
        startDate: startDate,
        endDate: endDate,
        page: page,
        perPage: perPage,
      );
      return matches;
    } catch (e) {
      _logger.e('Takım maçları alınırken hata: $e');
      throw Exception('Takım maçları yüklenirken bir hata oluştu');
    }
  }
}
