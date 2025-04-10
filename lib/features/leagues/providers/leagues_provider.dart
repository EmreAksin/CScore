// Ligler için provider sınıfı

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../core/models/match_model.dart';
import '../../../core/services/api_service.dart';

enum LeaguesStatus { initial, loading, loaded, error }

class LeaguesProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final Logger _logger = Logger();

  // Ligler için state değişkenleri
  List<LeagueModel> _leagues = [];
  LeaguesStatus _leaguesStatus = LeaguesStatus.initial;
  String? _leaguesError;
  int _leaguesPage = 1;
  bool _hasMoreLeagues = true;

  // Getters
  List<LeagueModel> get leagues => _leagues;
  LeaguesStatus get leaguesStatus => _leaguesStatus;
  String? get leaguesError => _leaguesError;
  bool get hasMoreLeagues => _hasMoreLeagues;

  // Constructor
  LeaguesProvider() {
    // Provider oluşturulduğunda ligleri otomatik olarak yükle
    getLeagues();
  }

  // Ligleri getir
  Future<void> getLeagues({bool refresh = false}) async {
    if (refresh) {
      _leaguesPage = 1;
      _hasMoreLeagues = true;
    }

    if (_leaguesStatus == LeaguesStatus.loading ||
        (!_hasMoreLeagues && !refresh)) {
      return;
    }

    _leaguesStatus = LeaguesStatus.loading;
    _leaguesError = null;

    if (_leaguesPage == 1) {
      _leagues = [];
    }

    notifyListeners();

    try {
      _logger.i('Ligler yükleniyor... Sayfa: $_leaguesPage');
      final leagues = await _apiService.getLeagues(
        page: _leaguesPage,
        perPage: 25,
      );

      if (leagues.isEmpty) {
        _hasMoreLeagues = false;
      } else {
        if (_leaguesPage == 1) {
          _leagues = leagues;
        } else {
          _leagues.addAll(leagues);
        }
        _leaguesPage++;
      }

      _leaguesStatus = LeaguesStatus.loaded;
      _logger.i('${leagues.length} lig yüklendi');
    } catch (e) {
      _leaguesStatus = LeaguesStatus.error;
      _leaguesError = 'Ligler yüklenirken hata oluştu: $e';
      _logger.e(_leaguesError);
    }

    notifyListeners();
  }

  // Daha fazla lig yükle
  Future<void> loadMoreLeagues() async {
    if (_leaguesStatus != LeaguesStatus.loading && _hasMoreLeagues) {
      await getLeagues();
    }
  }

  // Ligleri yenile
  Future<void> refreshLeagues() async {
    await getLeagues(refresh: true);
  }

  // Lig detaylarını getir
  Future<LeagueModel?> getLeagueDetails(int leagueId) async {
    try {
      // Önce yerel listede ara
      final localLeague = _leagues.firstWhere(
        (league) => league.id == leagueId,
        orElse: () => LeagueModel(id: 0, name: ''),
      );

      // Eğer yerel listede bulunduysa ve geçerli bir ID'ye sahipse döndür
      if (localLeague.id != 0) {
        return localLeague;
      }

      // Yerel listede bulunamadıysa API'den getir
      final leagueDetails = await _apiService.getLeagueDetails(leagueId);
      return leagueDetails;
    } catch (e) {
      _logger.e('Lig detayları alınırken hata: $e');
      return null;
    }
  }

  // Lig adını getir
  String getLeagueName(int leagueId) {
    // Özel durum: Lig bilgisi olmayan maçlar
    if (leagueId == 0) {
      return 'Diğer Maçlar';
    }

    // Ligler listesinde ara
    for (var league in _leagues) {
      if (league.id == leagueId) {
        return league.name;
      }
    }

    return 'Bilinmeyen Lig';
  }

  // Lig logo URL'sini getir
  String? getLeagueImageUrl(int leagueId) {
    // Özel durum: Lig bilgisi olmayan maçlar
    if (leagueId == 0) {
      return null;
    }

    // Ligler listesinde ara
    for (var league in _leagues) {
      if (league.id == leagueId) {
        return league.imageUrl;
      }
    }

    return null;
  }
}
