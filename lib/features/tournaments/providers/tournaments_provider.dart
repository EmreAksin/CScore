// Turnuvalar için provider sınıfı

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../core/models/tournament_model.dart';
import '../../../core/models/match_model.dart';
import '../../../core/models/team_model.dart';
import '../../../core/models/tournament_bracket_model.dart';
import '../../../core/models/tournament_standings_model.dart';
import '../../../core/services/api_service.dart';

enum TournamentsStatus { initial, loading, loaded, error }

class TournamentsProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final Logger _logger = Logger();

  // Turnuvalar için state değişkenleri
  List<TournamentModel> _allTournaments = [];
  TournamentsStatus _allTournamentsStatus = TournamentsStatus.initial;
  String? _allTournamentsError;
  int _allTournamentsPage = 1;
  bool _hasMoreAllTournaments = true;

  // Canlı (devam eden) turnuvalar
  List<TournamentModel> _liveTournaments = [];
  TournamentsStatus _liveTournamentsStatus = TournamentsStatus.initial;
  String? _liveTournamentsError;

  // Yaklaşan turnuvalar
  List<TournamentModel> _upcomingTournaments = [];
  TournamentsStatus _upcomingTournamentsStatus = TournamentsStatus.initial;
  String? _upcomingTournamentsError;
  int _upcomingTournamentsPage = 1;
  bool _hasMoreUpcomingTournaments = true;

  // Tamamlanan turnuvalar
  List<TournamentModel> _pastTournaments = [];
  TournamentsStatus _pastTournamentsStatus = TournamentsStatus.initial;
  String? _pastTournamentsError;
  int _pastTournamentsPage = 1;
  bool _hasMorePastTournaments = true;

  // Getters
  List<TournamentModel> get allTournaments => _allTournaments;
  TournamentsStatus get allTournamentsStatus => _allTournamentsStatus;
  String? get allTournamentsError => _allTournamentsError;
  bool get hasMoreAllTournaments => _hasMoreAllTournaments;

  List<TournamentModel> get liveTournaments => _liveTournaments;
  TournamentsStatus get liveTournamentsStatus => _liveTournamentsStatus;
  String? get liveTournamentsError => _liveTournamentsError;

  List<TournamentModel> get upcomingTournaments => _upcomingTournaments;
  TournamentsStatus get upcomingTournamentsStatus => _upcomingTournamentsStatus;
  String? get upcomingTournamentsError => _upcomingTournamentsError;
  bool get hasMoreUpcomingTournaments => _hasMoreUpcomingTournaments;

  List<TournamentModel> get pastTournaments => _pastTournaments;
  TournamentsStatus get pastTournamentsStatus => _pastTournamentsStatus;
  String? get pastTournamentsError => _pastTournamentsError;
  bool get hasMorePastTournaments => _hasMorePastTournaments;

  // Constructor
  TournamentsProvider() {
    // Provider oluşturulduğunda tüm turnuvaları otomatik olarak yükle
    getLiveTournaments();
    getUpcomingTournaments();
    getPastTournaments(targetCount: 100);
  }

  // Tüm turnuvaları getir
  Future<void> getAllTournaments({bool refresh = false}) async {
    if (refresh) {
      _allTournamentsPage = 1;
      _hasMoreAllTournaments = true;
    }

    if (_allTournamentsStatus == TournamentsStatus.loading ||
        (!_hasMoreAllTournaments && !refresh)) {
      return;
    }

    _allTournamentsStatus = TournamentsStatus.loading;
    _allTournamentsError = null;

    if (_allTournamentsPage == 1) {
      _allTournaments = [];
    }

    notifyListeners();

    try {
      _logger.i('Tüm turnuvalar yükleniyor... Sayfa: $_allTournamentsPage');

      final tournaments = await _apiService.getTournaments(
        page: _allTournamentsPage,
        perPage: 25,
      );

      if (tournaments.isEmpty) {
        _hasMoreAllTournaments = false;
      } else {
        if (_allTournamentsPage == 1) {
          _allTournaments = tournaments;
        } else {
          _allTournaments.addAll(tournaments);
        }
        _allTournamentsPage++;
      }

      _allTournamentsStatus = TournamentsStatus.loaded;
      _logger.i('${tournaments.length} turnuva yüklendi');
    } catch (e) {
      _allTournamentsStatus = TournamentsStatus.error;
      _allTournamentsError = 'Turnuvalar yüklenirken hata oluştu: $e';
      _logger.e(_allTournamentsError);
    }

    notifyListeners();
  }

  // Canlı turnuvaları getir
  Future<void> getLiveTournaments({bool refresh = false}) async {
    _liveTournamentsStatus = TournamentsStatus.loading;
    _liveTournamentsError = null;
    notifyListeners();

    try {
      _logger.i('Canlı turnuvalar yükleniyor...');

      final tournaments = await _apiService.getLiveTournaments(perPage: 50);

      _liveTournaments = tournaments;
      _liveTournamentsStatus = TournamentsStatus.loaded;
      _logger.i('${tournaments.length} canlı turnuva yüklendi');
    } catch (e) {
      _liveTournamentsStatus = TournamentsStatus.error;
      _liveTournamentsError = 'Canlı turnuvalar yüklenirken hata oluştu: $e';
      _logger.e(_liveTournamentsError);
    }

    notifyListeners();
  }

  // Yaklaşan turnuvaları getir
  Future<void> getUpcomingTournaments({bool refresh = false}) async {
    if (refresh) {
      _upcomingTournamentsPage = 1;
      _hasMoreUpcomingTournaments = true;
    }

    if (_upcomingTournamentsStatus == TournamentsStatus.loading ||
        (!_hasMoreUpcomingTournaments && !refresh)) {
      return;
    }

    _upcomingTournamentsStatus = TournamentsStatus.loading;
    _upcomingTournamentsError = null;

    if (_upcomingTournamentsPage == 1) {
      _upcomingTournaments = [];
    }

    notifyListeners();

    try {
      _logger.i(
        'Yaklaşan turnuvalar yükleniyor... Sayfa: $_upcomingTournamentsPage',
      );

      final tournaments = await _apiService.getUpcomingTournaments(
        page: _upcomingTournamentsPage,
        perPage: 25,
      );

      if (tournaments.isEmpty) {
        _hasMoreUpcomingTournaments = false;
      } else {
        if (_upcomingTournamentsPage == 1) {
          _upcomingTournaments = tournaments;
        } else {
          _upcomingTournaments.addAll(tournaments);
        }
        _upcomingTournamentsPage++;
      }

      _upcomingTournamentsStatus = TournamentsStatus.loaded;
      _logger.i('${tournaments.length} yaklaşan turnuva yüklendi');
    } catch (e) {
      _upcomingTournamentsStatus = TournamentsStatus.error;
      _upcomingTournamentsError =
          'Yaklaşan turnuvalar yüklenirken hata oluştu: $e';
      _logger.e(_upcomingTournamentsError);
    }

    notifyListeners();
  }

  // Tamamlanan turnuvaları getir
  Future<void> getPastTournaments({
    bool refresh = false,
    bool autoLoadMore = true,
    int targetCount = 100, // Hedef turnuva sayısı
  }) async {
    if (refresh) {
      _pastTournamentsPage = 1;
      _hasMorePastTournaments = true;
    }

    // Zaten yükleme yapılıyorsa ve ilk yükleme değilse bekle
    if (_pastTournamentsStatus == TournamentsStatus.loading &&
        !(_pastTournamentsPage == 1 && refresh)) {
      return;
    }

    // Daha fazla turnuva yoksa ve yenileme yapmıyorsak çık
    if (!_hasMorePastTournaments && !refresh) {
      return;
    }

    _pastTournamentsStatus = TournamentsStatus.loading;
    _pastTournamentsError = null;

    if (_pastTournamentsPage == 1) {
      _pastTournaments = [];
    }

    notifyListeners();

    try {
      _logger.i(
        'Tamamlanan turnuvalar yükleniyor... Sayfa: $_pastTournamentsPage (hedef: $targetCount)',
      );

      final tournaments = await _apiService.getPastTournaments(
        page: _pastTournamentsPage,
        perPage: 50, // Sayfa başına daha fazla turnuva yükle
      );

      if (tournaments.isEmpty) {
        _hasMorePastTournaments = false;
        _logger.i('Daha fazla tamamlanan turnuva yok');
      } else {
        if (_pastTournamentsPage == 1) {
          _pastTournaments = tournaments;
        } else {
          _pastTournaments.addAll(tournaments);
        }
        _pastTournamentsPage++;

        _logger.i(
          '${tournaments.length} tamamlanan turnuva yüklendi (Toplam: ${_pastTournaments.length})',
        );

        // Eğer hedeflenen turnuva sayısına ulaşılmadıysa ve daha fazla turnuva varsa otomatik olarak yükle
        if (autoLoadMore &&
            _pastTournaments.length < targetCount &&
            _hasMorePastTournaments &&
            tournaments.isNotEmpty) {
          _logger.i(
            'Otomatik olarak daha fazla turnuva yükleniyor. Şu anki toplam: ${_pastTournaments.length}, Hedef: $targetCount',
          );

          // Durumu güncelleyelim ki kullanıcı arayüzüne yansısın
          _pastTournamentsStatus = TournamentsStatus.loaded;
          notifyListeners();

          // Kısa bir gecikme ekleyelim ki UI önce güncellensin
          await Future.delayed(const Duration(milliseconds: 300));

          // Otomatik olarak bir sonraki sayfayı yükle
          await getPastTournaments(
            refresh: false,
            autoLoadMore: true,
            targetCount: targetCount,
          );
          return; // Rekürsif çağrıdan sonra çıkalım
        }
      }

      _pastTournamentsStatus = TournamentsStatus.loaded;
    } catch (e) {
      _pastTournamentsStatus = TournamentsStatus.error;
      _pastTournamentsError =
          'Tamamlanan turnuvalar yüklenirken hata oluştu: $e';
      _logger.e(_pastTournamentsError);
    }

    notifyListeners();
  }

  // Turnuva detaylarını getir
  Future<TournamentModel?> getTournamentDetails(int tournamentId) async {
    try {
      // Önce yerel listede ara
      TournamentModel? tournament = _findTournamentInLists(tournamentId);

      // Bulunamadıysa API'den getir
      tournament ??= await _apiService.getTournamentDetails(tournamentId);

      return tournament;
    } catch (e) {
      _logger.e('Turnuva detayları alınırken hata: $e');
      return null;
    }
  }

  // Turnuvadaki maçları getir
  Future<List<MatchModel>> getMatchesByTournament(int tournamentId) async {
    try {
      return await _apiService.getMatchesByTournament(tournamentId);
    } catch (e) {
      _logger.e('Turnuva maçları alınırken hata: $e');
      return [];
    }
  }

  // Tüm turnuva listelerini yenile
  Future<void> refreshAllTournaments() async {
    await getLiveTournaments();
    await getUpcomingTournaments(refresh: true);
    await getPastTournaments(refresh: true, targetCount: 100);
  }

  // Yerel listelerden turnuva ara
  TournamentModel? _findTournamentInLists(int tournamentId) {
    // Canlı turnuvalarda ara
    for (var tournament in _liveTournaments) {
      if (tournament.id == tournamentId) {
        return tournament;
      }
    }

    // Yaklaşan turnuvalarda ara
    for (var tournament in _upcomingTournaments) {
      if (tournament.id == tournamentId) {
        return tournament;
      }
    }

    // Tamamlanan turnuvalarda ara
    for (var tournament in _pastTournaments) {
      if (tournament.id == tournamentId) {
        return tournament;
      }
    }

    // Tüm turnuvalarda ara
    for (var tournament in _allTournaments) {
      if (tournament.id == tournamentId) {
        return tournament;
      }
    }

    return null;
  }

  // Turnuva takımlarını getir
  Future<List<TeamModel>> getTournamentTeams(int tournamentId) async {
    try {
      return await _apiService.getTournamentTeams(tournamentId);
    } catch (e) {
      _logger.e('Turnuva takımları alınırken hata: $e');
      return [];
    }
  }

  // Turnuva eleme tablosunu getir
  Future<List<TournamentBracketModel>> getTournamentBrackets(
    int tournamentId,
  ) async {
    try {
      return await _apiService.getTournamentBrackets(tournamentId);
    } catch (e) {
      _logger.e('Turnuva eleme tablosu alınırken hata: $e');
      return [];
    }
  }

  // Turnuva sıralamasını getir
  Future<TournamentStandingsModel?> getTournamentStandings(
    int tournamentId,
  ) async {
    try {
      return await _apiService.getTournamentStandings(tournamentId);
    } catch (e) {
      _logger.e('Turnuva sıralaması alınırken hata: $e');
      return null;
    }
  }
}
