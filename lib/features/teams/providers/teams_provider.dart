// Takımlar için provider sınıfı

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../core/models/team_model.dart';
import '../../../core/services/api_service.dart';

enum TeamsStatus { initial, loading, loaded, error }

class TeamsProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final Logger _logger = Logger();

  // Takımlar için state değişkenleri
  List<TeamModel> _teams = [];
  TeamsStatus _teamsStatus = TeamsStatus.initial;
  String? _teamsError;
  int _teamsPage = 1;
  bool _hasMoreTeams = true;
  String _searchQuery = ''; // Arama sorgusu

  // Getters
  List<TeamModel> get teams => _teams;
  TeamsStatus get teamsStatus => _teamsStatus;
  String? get teamsError => _teamsError;
  bool get hasMoreTeams => _hasMoreTeams;
  String get searchQuery => _searchQuery;

  // Constructor
  TeamsProvider() {
    // Provider oluşturulduğunda takımları otomatik olarak yükle
    getTeams();
  }

  // Takımları getir
  Future<void> getTeams({bool refresh = false}) async {
    if (refresh) {
      _teamsPage = 1;
      _hasMoreTeams = true;
    }

    if (_teamsStatus == TeamsStatus.loading || (!_hasMoreTeams && !refresh)) {
      return;
    }

    _teamsStatus = TeamsStatus.loading;
    _teamsError = null;

    if (_teamsPage == 1) {
      _teams = [];
    }

    notifyListeners();

    try {
      _logger.i(
        'Takımlar yükleniyor... Sayfa: $_teamsPage ve ${_teamsPage + 1}, Arama: $_searchQuery',
      );

      List<TeamModel> allTeams = [];
      try {
        // İlk sayfa için istek
        final firstPageTeams = await _apiService.getTeams(
          page: _teamsPage,
          perPage: 25,
          search: _searchQuery.isNotEmpty ? _searchQuery : null,
        );

        // İkinci sayfa için istek
        final secondPageTeams = await _apiService.getTeams(
          page: _teamsPage + 1,
          perPage: 25,
          search: _searchQuery.isNotEmpty ? _searchQuery : null,
        );

        // İki sayfayı birleştir
        allTeams = [...firstPageTeams, ...secondPageTeams];
      } catch (apiError) {
        _logger.e('Takımlar API isteği başarısız: $apiError');
        _teamsStatus = TeamsStatus.error;
        _teamsError = 'Takımlar yüklenirken API hatası: $apiError';
        if (_teamsPage == 1) {
          _teams = [];
        }
        notifyListeners();
        return;
      }

      _logger.i(
        'Takımlar API isteği tamamlandı. ${allTeams.length} takım alındı.',
      );

      // Hiç takım gelmezse, daha fazla takım olmadığını işaretle
      if (allTeams.isEmpty) {
        _hasMoreTeams = false;
        _teamsStatus = TeamsStatus.loaded;
        notifyListeners();
        return;
      }

      // Filtreleme: Logosu olmayan takımları VE oyuncu sayısı 5'ten az olan takımları gösterme
      final filteredTeams =
          allTeams.where((team) {
            // 1. Takımın logosu olmalı
            final hasLogo = team.logoUrl != null && team.logoUrl!.isNotEmpty;

            // 2. Takımın 5 veya daha fazla oyuncusu olmalı
            final hasEnoughPlayers =
                team.players != null && team.players!.length >= 5;

            return hasLogo && hasEnoughPlayers;
          }).toList();

      _logger.i('Filtreleme sonrası ${filteredTeams.length} takım kaldı.');

      // Eğer filtreleme sonrası takım kalmadıysa ve daha fazla takım varsa
      if (filteredTeams.isEmpty && allTeams.isNotEmpty) {
        _teamsPage += 2; // İki sayfa birden atla
        await getTeams(); // Bir sonraki iki sayfayı getir
        return;
      }

      // Takımları ekle
      if (_teamsPage == 1) {
        _teams = filteredTeams;
      } else {
        _teams.addAll(filteredTeams);
      }

      // Bir sonraki sayfa için hazırlan (2 sayfa birden atla)
      _teamsPage += 2;
      _hasMoreTeams =
          allTeams.length >= 50; // İki sayfada toplam 50 takım gelmeli

      _teamsStatus = TeamsStatus.loaded;
      _logger.i('${_teams.length} takım yüklendi');
    } catch (e) {
      _teamsStatus = TeamsStatus.error;
      _teamsError = 'Takımlar yüklenirken hata oluştu: $e';
      _logger.e(_teamsError);

      if (_teamsPage == 1) {
        _teams = [];
      }
    }

    notifyListeners();
  }

  // Arama sorgusunu ayarla ve takımları yeniden yükle
  Future<void> searchTeamsByName(String query) async {
    if (_searchQuery != query) {
      _searchQuery = query;
      await getTeams(refresh: true);
    }
  }

  // Daha fazla takım yükle
  Future<void> loadMoreTeams() async {
    if (_teamsStatus != TeamsStatus.loading && _hasMoreTeams) {
      await getTeams();
    }
  }

  // Takımları yenile
  Future<void> refreshTeams() async {
    await getTeams(refresh: true);
  }

  // Takım detaylarını getir
  Future<TeamModel?> getTeamDetails(int teamId) async {
    try {
      _logger.i('Takım detayları isteniyor (yerel liste ve API): $teamId');

      // Önce yerel listede ara
      final localTeam = _teams.firstWhere(
        (team) => team.id == teamId,
        orElse: () => TeamModel(id: 0, name: '', acronym: ''),
      );

      // Eğer yerel listede bulunduysa ve geçerli bir ID'ye sahipse döndür
      if (localTeam.id != 0) {
        _logger.i('Takım yerel listede bulundu: ${localTeam.name}');
        return localTeam;
      }

      // Yerel listede bulunamadıysa API'den getir
      _logger.i(
        'Takım yerel listede bulunamadı, API\'den getiriliyor: $teamId',
      );

      // Önce tüm takımları getirmeyi deneyelim (filtreleme için)
      try {
        final allTeams = await _apiService.getTeams(perPage: 100);
        // ID'ye göre filtreleme
        final teamFromList = allTeams.firstWhere(
          (team) => team.id == teamId,
          orElse: () => TeamModel(id: 0, name: '', acronym: ''),
        );

        if (teamFromList.id != 0) {
          _logger.i(
            'Takım tüm takımlar listesinde bulundu: ${teamFromList.name}',
          );
          return teamFromList;
        }
      } catch (e) {
        _logger.w('Tüm takımları getirirken hata: $e');
      }

      // Tek takım detayı almayı deneyelim
      final teamDetails = await _apiService.getTeamDetails(teamId);

      if (teamDetails == null) {
        _logger.e('API\'den takım detayları alınamadı. Takım ID: $teamId');
        throw Exception(
          'PandaScore API\'den takım bilgileri alınamadı (ID: $teamId). Lütfen internet bağlantınızı kontrol edin veya daha sonra tekrar deneyin.',
        );
      }

      _logger.i('Takım detayları başarıyla alındı: ${teamDetails.name}');
      return teamDetails;
    } catch (e) {
      _logger.e('Takım detayları alınırken hata: $e');
      // Kullanıcıya daha anlamlı bir hata mesajı
      throw Exception(
        'Takım bilgisi bulunamadı. Lütfen daha sonra tekrar deneyin.',
      );
    }
  }

  // Takımları sırala (Alfabetik olarak)
  void sortTeamsAlphabetically() {
    _teams.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  // Takımları sırala (Performansa göre)
  void sortTeamsByStatus() {
    _teams.sort((a, b) {
      // Status null değilse karşılaştır, aksi halde boş string kullan
      final statusA = a.status ?? '';
      final statusB = b.status ?? '';
      return statusB.compareTo(statusA); // Öncelikle CS2 takımlarını göster
    });
    notifyListeners();
  }

  // Takım ara
  List<TeamModel> searchTeams(String query) {
    if (query.isEmpty) {
      return _teams;
    }

    final lowercaseQuery = query.toLowerCase();
    return _teams.where((team) {
      return team.name.toLowerCase().contains(lowercaseQuery) ||
          (team.acronym.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }
}
