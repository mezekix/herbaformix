// Davet kodunun yaşam döngüsü durumunu temsil eden enum.
//
// - [pending]: Kod oluşturuldu, henüz kullanılmadı, süresi dolmadı.
// - [used]: Kod bir müşteri tarafından kullanıldı (kayıt tamamlandı).
// - [expired]: Kod süresi doldu veya distribütör tarafından iptal edildi.
//
// Firestore'da string olarak saklanır.

enum InviteStatus { pending, used, expired }

extension InviteStatusExtension on InviteStatus {
  /// Firestore'a yazılacak string değer.
  String toFirestore() {
    switch (this) {
      case InviteStatus.pending:
        return 'pending';
      case InviteStatus.used:
        return 'used';
      case InviteStatus.expired:
        return 'expired';
    }
  }

  /// Kullanıcı arayüzünde gösterilecek Türkçe etiket.
  String get label {
    switch (this) {
      case InviteStatus.pending:
        return 'Davet Bekleniyor';
      case InviteStatus.used:
        return 'Bağlandı';
      case InviteStatus.expired:
        return 'Süresi Doldu';
    }
  }
}

/// Firestore'dan okunan string değeri [InviteStatus] enum'una çevirir.
///
/// Eski belgelerde `status` alanı yoksa `null` döner; bu durumda çağıran taraf
/// `isUsed` alanına bakarak fallback yapmalıdır.
InviteStatus? inviteStatusFromString(String? raw) {
  if (raw == null) return null;
  switch (raw) {
    case 'pending':
      return InviteStatus.pending;
    case 'used':
      return InviteStatus.used;
    case 'expired':
      return InviteStatus.expired;
    default:
      return null;
  }
}
