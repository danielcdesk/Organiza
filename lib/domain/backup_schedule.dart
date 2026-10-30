class BackupSchedule {
  const BackupSchedule._();

  static bool isDue(DateTime now, {required bool enabled,
    required int intervalDays, DateTime? lastSuccess, bool closing = false,
    bool backupOnClose = false}) {
    if (intervalDays < 1 || intervalDays > 365) {
      throw ArgumentError('Escolha um intervalo entre 1 e 365 dias.');
    }
    if (!enabled) return false;
    if (closing) return backupOnClose;
    if (lastSuccess == null) return true;
    // Compare calendar dates without DST or the hour of the previous backup.
    final today = DateTime.utc(now.year, now.month, now.day);
    final previous = DateTime.utc(
        lastSuccess.year, lastSuccess.month, lastSuccess.day);
    return today.difference(previous).inDays >= intervalDays;
  }
}
