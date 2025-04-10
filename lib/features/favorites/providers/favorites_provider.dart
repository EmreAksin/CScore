import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../core/models/team_model.dart';
import '../../../core/utils/logger.dart';

class FavoritesProvider with ChangeNotifier {
  final String _favoriteTeamsKey = 'favorite_teams';
  List<int> _favoriteTeamIds = [];
  List<TeamModel> _favoriteTeams = [];
  bool _isLoading = false;

  FavoritesProvider() {
    _loadFavoriteTeamsFromStorage();
  }

  // Getter'lar
  List<int> get favoriteTeamIds => _favoriteTeamIds;
  List<TeamModel> get favoriteTeams => _favoriteTeams;
  bool get isLoading => _isLoading;

  // Yerel depolamadan favorileri yükle
  Future<void> _loadFavoriteTeamsFromStorage() async {
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_favoriteTeamsKey);

      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _favoriteTeamIds = jsonList.map<int>((item) => item as int).toList();
      } else {
        _favoriteTeamIds = [];
      }

      _isLoading = false;
      notifyListeners();

      Logger.log('Favori takım sayısı: ${_favoriteTeamIds.length}');
    } catch (e) {
      Logger.error('Favorileri yüklerken hata: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Yerel depolamaya favorileri kaydet
  Future<void> _saveFavoriteTeamsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_favoriteTeamsKey, jsonEncode(_favoriteTeamIds));
    } catch (e) {
      Logger.error('Favorileri kaydederken hata: $e');
    }
  }

  // Takımı favorilere ekle
  Future<void> addFavoriteTeam(int teamId) async {
    if (!_favoriteTeamIds.contains(teamId)) {
      _favoriteTeamIds.add(teamId);
      await _saveFavoriteTeamsToStorage();
      notifyListeners();
    }
  }

  // Takımı favorilerden kaldır
  Future<void> removeFavoriteTeam(int teamId) async {
    if (_favoriteTeamIds.contains(teamId)) {
      _favoriteTeamIds.remove(teamId);
      await _saveFavoriteTeamsToStorage();
      notifyListeners();
    }
  }

  // Takım favorilerde mi?
  bool isTeamFavorite(int teamId) {
    return _favoriteTeamIds.contains(teamId);
  }

  // Favori takımları güncelle
  void updateFavoriteTeams(List<TeamModel> teams) {
    _favoriteTeams = teams;
    notifyListeners();
  }

  // Tüm favorileri temizle
  Future<void> clearFavorites() async {
    _favoriteTeamIds = [];
    _favoriteTeams = [];
    await _saveFavoriteTeamsToStorage();
    notifyListeners();
  }
}
