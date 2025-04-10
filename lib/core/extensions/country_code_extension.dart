// Ülke kodlarını bayrak emojilerine çeviren extension
extension CountryCodeExtension on String {
  String toFlag() {
    // Eğer ülke kodu 2 karakterden kısa veya boşsa, orijinal değeri döndür
    if (length < 2) return this;

    // Ülke kodunu büyük harfe çevir
    final countryCode = toUpperCase();

    // Regional Indicator Symbol harflerine çevir
    // Her harf için 127397 ekleyerek emoji koduna çevir
    final flagEmoji = String.fromCharCodes(
      countryCode.runes.map((rune) => rune + 127397),
    );

    return flagEmoji;
  }

  // Özel durumlar için ülke kodlarını düzeltme
  String normalizeCountryCode() {
    // Bazı özel durumlar için düzeltmeler
    switch (toUpperCase()) {
      case 'ENG':
        return 'GB';
      case 'SCO':
        return 'GB';
      case 'WAL':
        return 'GB';
      case 'NIR':
        return 'GB';
      case 'RUS':
        return 'RU';
      case 'USA':
        return 'US';
      default:
        // Eğer kod 2 karakterden uzunsa ilk 2 karakteri al
        return length > 2 ? substring(0, 2).toUpperCase() : toUpperCase();
    }
  }

  // Ülke kodunu bayrak emojisine çevirme (normalizasyon ile)
  String toFlagEmoji() {
    return normalizeCountryCode().toFlag();
  }
}
