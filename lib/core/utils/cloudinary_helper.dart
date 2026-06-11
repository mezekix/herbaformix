class CloudinaryHelper {
  static const String cloudName = 'daal4ljca';

  static const String _imageBase = 'https://res.cloudinary.com/$cloudName/image/upload/';
  static const String _videoBase = 'https://res.cloudinary.com/$cloudName/video/upload/';

  /// Cloudinary resim URL'ine f_auto,q_auto ekler.
  /// Cloudinary olmayan URL'leri olduğu gibi döndürür.
  /// f_auto: cihaza göre en iyi format (WebP/AVIF/JPEG)
  /// q_auto: otomatik kalite seçimi (görsel kalite/dosya boyutu dengesi)
  static String? optimizeImage(String? url, {int? width}) {
    if (url == null || url.isEmpty) return url;
    if (!url.startsWith(_imageBase)) return url;
    if (url.contains('/f_auto') || url.contains('/q_auto')) return url;

    final tail = url.substring(_imageBase.length);
    final transforms = <String>['f_auto', 'q_auto'];
    if (width != null) transforms.add('w_$width');
    return '$_imageBase${transforms.join(',')}/$tail';
  }

  /// Cloudinary resmi 1:1 kare olarak akıllı kırpar (g_auto: önemli bölgeyi merkeze alır).
  /// Cloudinary olmayan URL'leri olduğu gibi döndürür.
  static String? optimizeImageSquare(String? url, {int width = 400}) {
    if (url == null || url.isEmpty) return url;
    if (!url.startsWith(_imageBase)) return url;

    var tail = url.substring(_imageBase.length);
    // Mevcut leading transformasyonları (q_auto/, f_auto/, c_fill,ar_1:1/) temizle.
    // [a-z]+_ ile başlayan segmentleri eşler; v1234 versiyonu (alt çizgi yok) korunur.
    tail = tail.replaceFirst(RegExp(r'^(?:[a-z]+_[^/]+/)+'), '');
    return '${_imageBase}c_fill,ar_1:1,g_auto,w_$width,f_auto,q_auto/$tail';
  }

  /// Cloudinary video URL'inden poster (thumbnail) URL'i üretir.
  /// video/upload/.../video.mp4 -> image/upload/.../video.jpg
  static String? videoPoster(String? videoUrl) {
    if (videoUrl == null || videoUrl.isEmpty) return null;
    if (!videoUrl.startsWith(_videoBase)) return null;

    final tail = videoUrl.substring(_videoBase.length);
    final withoutExt = tail.replaceAll(RegExp(r'\.(mp4|mov|webm|m4v|avi)$', caseSensitive: false), '');
    return '$_imageBase'
        'f_auto,q_auto,so_0/$withoutExt.jpg';
  }

  /// Cloudinary video URL'ine q_auto ekler (transcoding).
  static String? optimizeVideo(String? url) {
    if (url == null || url.isEmpty) return url;
    if (!url.startsWith(_videoBase)) return url;
    if (url.contains('/q_auto')) return url;

    final tail = url.substring(_videoBase.length);
    return '${_videoBase}q_auto/$tail';
  }
}
