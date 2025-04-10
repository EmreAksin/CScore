import 'dart:convert';
import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logger/logger.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  final Logger _logger = Logger();
  Database? _database;
  static const String dbName = 'cs2_sabir_cache.db';
  static const String tableName = 'api_cache';

  // Singleton
  factory CacheService() {
    return _instance;
  }

  CacheService._internal();

  // Veritabanı bağlantısını başlat
  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  // Veritabanını oluştur
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, dbName);

    _logger.i('Veritabanı başlatılıyor: $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableName (
            key TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            expiry INTEGER NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        _logger.i('Veritabanı tablosu oluşturuldu: $tableName');
      },
    );
  }

  // Veriyi önbelleğe kaydet
  Future<void> saveToCache(
    String key,
    dynamic data, {
    Duration expiry = const Duration(hours: 2),
  }) async {
    try {
      final db = await database;
      final expiryTime = DateTime.now().add(expiry).millisecondsSinceEpoch;
      final jsonData = jsonEncode(data);

      await db.insert(tableName, {
        'key': key,
        'data': jsonData,
        'expiry': expiryTime,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      _logger.i('Veri önbelleğe kaydedildi: $key');
    } catch (e) {
      _logger.e('Veri önbelleğe kaydedilirken hata: $e');
    }
  }

  // Önbellekten veri al
  Future<dynamic> getFromCache(String key) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;

      final result = await db.query(
        tableName,
        where: 'key = ? AND expiry > ?',
        whereArgs: [key, now],
      );

      if (result.isNotEmpty) {
        _logger.i('Veri önbellekten alındı: $key');
        return jsonDecode(result.first['data'] as String);
      } else {
        _logger.i('Önbellekte veri bulunamadı veya süresi dolmuş: $key');
        return null;
      }
    } catch (e) {
      _logger.e('Önbellekten veri alınırken hata: $e');
      return null;
    }
  }

  // Önbellekten veri al veya yoksa API'den getir
  Future<dynamic> getOrFetch(
    String key,
    Future<dynamic> Function() fetchFunction, {
    Duration expiry = const Duration(hours: 2),
  }) async {
    // Önce önbellekten dene
    final cachedData = await getFromCache(key);

    if (cachedData != null) {
      return cachedData;
    }

    // Önbellekte yoksa API'den getir
    try {
      final data = await fetchFunction();

      // Veriyi önbelleğe kaydet
      if (data != null) {
        await saveToCache(key, data, expiry: expiry);
      }

      return data;
    } catch (e) {
      _logger.e('Veri getirme işlemi başarısız: $e');
      rethrow;
    }
  }

  // Belirli bir anahtara sahip veriyi önbellekten sil
  Future<void> removeFromCache(String key) async {
    try {
      final db = await database;
      await db.delete(tableName, where: 'key = ?', whereArgs: [key]);
      _logger.i('Veri önbellekten silindi: $key');
    } catch (e) {
      _logger.e('Veri önbellekten silinirken hata: $e');
    }
  }

  // Süresi dolmuş verileri önbellekten temizle
  Future<void> clearExpiredCache() async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;

      final deletedCount = await db.delete(
        tableName,
        where: 'expiry < ?',
        whereArgs: [now],
      );

      _logger.i('Süresi dolmuş $deletedCount öğe önbellekten temizlendi');
    } catch (e) {
      _logger.e('Önbellek temizleme hatası: $e');
    }
  }

  // Tüm önbelleği temizle
  Future<void> clearAllCache() async {
    try {
      final db = await database;
      await db.delete(tableName);
      _logger.i('Tüm önbellek temizlendi');
    } catch (e) {
      _logger.e('Tüm önbellek temizlenirken hata: $e');
    }
  }

  // Görseller için DefaultCacheManager
  static final DefaultCacheManager imageCacheManager = DefaultCacheManager();

  // Görsel önbelleğe alma
  Future<File> getImageFromCache(String url) async {
    try {
      final fileInfo = await imageCacheManager.getFileFromCache(url);

      if (fileInfo != null) {
        _logger.i('Görsel önbellekten alındı: $url');
        return fileInfo.file;
      }

      _logger.i('Görsel indirilip önbelleğe alınıyor: $url');
      return await imageCacheManager.getSingleFile(url);
    } catch (e) {
      _logger.e('Görsel önbellekleme hatası: $e');
      rethrow;
    }
  }

  // Uygulamanın tüm önbelleğini temizle (veritabanı + görseller)
  Future<void> clearAllCacheIncludingImages() async {
    try {
      // Veritabanı önbelleğini temizle
      await clearAllCache();

      // Görsel önbelleğini temizle
      await imageCacheManager.emptyCache();

      _logger.i('Tüm önbellek (veritabanı + görseller) temizlendi');
    } catch (e) {
      _logger.e('Tüm önbellek temizlenirken hata: $e');
    }
  }

  // Önbellek boyutunu hesapla
  Future<String> getCacheSize() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT SUM(LENGTH(data)) as size FROM $tableName',
      );
      final dbSize = result.first['size'] as int? ?? 0;

      // Görsel önbellek boyutunu hesapla
      final cacheDir = await getTemporaryDirectory();
      final cacheSize = await _getDirectorySize(cacheDir);

      final totalSize = dbSize + cacheSize;
      return _formatFileSize(totalSize);
    } catch (e) {
      _logger.e('Önbellek boyutu hesaplanırken hata: $e');
      return 'Hesaplanamadı';
    }
  }

  // Dizin boyutunu hesapla
  Future<int> _getDirectorySize(Directory dir) async {
    if (!dir.existsSync()) return 0;

    int size = 0;
    try {
      final List<FileSystemEntity> entities = await dir.list().toList();
      if (entities.isEmpty) return 0;

      for (final FileSystemEntity entity in entities) {
        try {
          if (entity is File) {
            size += await entity.length();
          } else if (entity is Directory) {
            size += await _getDirectorySize(entity);
          }
        } catch (e) {
          // Tekil dosya/dizin hatasını atla
          _logger.e('Dosya boyutu alınırken hata: $e');
        }
      }
      return size;
    } catch (e) {
      _logger.e('Dizin boyutu hesaplanırken hata: $e');
      return 0;
    }
  }

  // Dosya boyutunu formatla
  String _formatFileSize(int sizeInBytes) {
    if (sizeInBytes < 1024) {
      return '$sizeInBytes B';
    } else if (sizeInBytes < 1024 * 1024) {
      final kb = sizeInBytes / 1024;
      return '${kb.toStringAsFixed(2)} KB';
    } else if (sizeInBytes < 1024 * 1024 * 1024) {
      final mb = sizeInBytes / (1024 * 1024);
      return '${mb.toStringAsFixed(2)} MB';
    } else {
      final gb = sizeInBytes / (1024 * 1024 * 1024);
      return '${gb.toStringAsFixed(2)} GB';
    }
  }
}
