// API sabitlerini içerir - PandaScore bağlantıları

class ApiConstants {
  // PandaScore API sabitleri
  static const String pandaScoreBaseUrl = 'https://api.pandascore.co';
  static const String pandaScoreApiKey =
      'JOAnt_HSpXgJGD8EFYu95PhlZ2XYqSPUza6oL1o8r-2VDaJuDNM';

  // CS2 için API endpoint'leri
  static const String cs2MatchesEndpoint = '/csgo/matches';
  static const String cs2TeamsEndpoint = '/csgo/teams';
  static const String cs2LeaguesEndpoint = '/csgo/leagues';
  static const String cs2SeriesEndpoint = '/csgo/series';
  static const String cs2TournamentsEndpoint = '/csgo/tournaments';

  // CS2 için alternatif endpoint'ler (test için)
  static const String cs2AltMatchesEndpoint = '/cs2/matches';
  static const String cs2AltTeamsEndpoint = '/cs2/teams';
  static const String cs2AltTournamentsEndpoint = '/cs2/tournaments';

  // Turnuva durumları için endpoint'ler
  static const String cs2PastTournamentsEndpoint = '/csgo/tournaments/past';
  static const String cs2RunningTournamentsEndpoint =
      '/csgo/tournaments/running';
  static const String cs2UpcomingTournamentsEndpoint =
      '/csgo/tournaments/upcoming';

  // CS2 için alternatif turnuva durumları endpoint'leri (test için)
  static const String cs2AltPastTournamentsEndpoint = '/cs2/tournaments/past';
  static const String cs2AltRunningTournamentsEndpoint =
      '/cs2/tournaments/running';
  static const String cs2AltUpcomingTournamentsEndpoint =
      '/cs2/tournaments/upcoming';

  // Turnuva sonuçları için endpoint'ler
  static const String cs2TournamentBracketsEndpoint = 'brackets';
  static const String cs2TournamentStandingsEndpoint = 'standings';
  static const String cs2TournamentTeamsEndpoint = 'teams';

  // HTTP istek zaman aşımı sabitleri
  static const int connectTimeout = 30000; // 30 saniye
  static const int receiveTimeout = 30000; // 30 saniye

  // API sorgu parametreleri
  static const int defaultPageSize = 25;
  static const String defaultSort = 'begin_at';
}
