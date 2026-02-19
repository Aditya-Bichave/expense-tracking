enum GroupRole {
  admin,
  member,
  viewer;

  String get value => name;

  static GroupRole fromValue(String value) {
    return GroupRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GroupRole.member,
    );
  }
}
