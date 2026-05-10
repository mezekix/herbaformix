enum UserRole { supervisor, distributor, successCreator, customer }

extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.supervisor:
        return 'Supervizör ve üstü';
      case UserRole.distributor:
        return 'Distribütör';
      case UserRole.successCreator:
        return 'Başarı Yaratıcısı';
      case UserRole.customer:
        return 'Müşteri';
    }
  }
}
