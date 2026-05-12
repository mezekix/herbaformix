class ImageUtils {
  /// Google Drive paylaşım linkini, doğrudan resmi gösterecek formata çevirir.
  /// Eğer link zaten uygun formattaysa veya Drive linki değilse aynen döndürür.
  static String getDirectImageUrl(String url) {
    if (url.isEmpty) return url;

    // Eğer zaten bir uc?export linki ise dokunma
    if (url.contains('drive.google.com/uc?export=')) {
      return url;
    }

    // Format 1: https://drive.google.com/file/d/ID/view...
    final RegExp fileIdRegex = RegExp(r'/file/d/([a-zA-Z0-9_-]+)/');
    final Match? fileIdMatch = fileIdRegex.firstMatch(url);
    if (fileIdMatch != null && fileIdMatch.groupCount >= 1) {
      final String fileId = fileIdMatch.group(1)!;
      return 'https://drive.google.com/uc?export=view&id=$fileId';
    }

    // Format 2: https://drive.google.com/open?id=ID
    final RegExp openIdRegex = RegExp(r'[?&]id=([a-zA-Z0-9_-]+)');
    final Match? openIdMatch = openIdRegex.firstMatch(url);
    if (url.contains('drive.google.com') && openIdMatch != null && openIdMatch.groupCount >= 1) {
      final String fileId = openIdMatch.group(1)!;
      return 'https://drive.google.com/uc?export=view&id=$fileId';
    }

    // Başka bir linkse aynen döndür
    return url;
  }
}
