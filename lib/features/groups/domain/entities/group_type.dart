enum GroupType {
  trip('trip'),
  couple('couple'),
  home('home'),
  custom('custom');

  final String value;
  const GroupType(this.value);

  static GroupType fromValue(String value) {
    return GroupType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => GroupType.custom,
    );
  }
}
