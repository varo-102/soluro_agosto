/// Sincronización de estados para entidades Cloud-Ready.
enum SyncStatus {
  pending,
  synced,
  error;

  String toValue() => name;

  static SyncStatus fromValue(String? value) {
    if (value == null) return SyncStatus.pending;
    return SyncStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SyncStatus.pending,
    );
  }
}
