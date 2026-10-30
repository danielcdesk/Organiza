import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/domain/backup_schedule.dart';

void main() {
  test('backup vencido usa dias civis e respeita configuração', () {
    final now = DateTime(2026, 10, 29, 0, 1);
    expect(BackupSchedule.isDue(now, enabled: true, intervalDays: 7), isTrue);
    expect(BackupSchedule.isDue(now, enabled: false, intervalDays: 7), isFalse);
    expect(BackupSchedule.isDue(now, enabled: true, intervalDays: 7,
        lastSuccess: DateTime(2026, 10, 22, 23, 59)), isTrue);
    expect(BackupSchedule.isDue(now, enabled: true, intervalDays: 7,
        lastSuccess: DateTime(2026, 10, 23)), isFalse);
    expect(BackupSchedule.isDue(now, enabled: true, intervalDays: 7,
        lastSuccess: DateTime(2026, 11, 1)), isFalse);
  });

  test('fechamento só agenda se habilitado e intervalo inválido é rejeitado', () {
    final now = DateTime(2026, 10, 29);
    expect(BackupSchedule.isDue(now, enabled: true, intervalDays: 7,
        closing: true, backupOnClose: false), isFalse);
    expect(BackupSchedule.isDue(now, enabled: true, intervalDays: 7,
        closing: true, backupOnClose: true, lastSuccess: now), isTrue);
    expect(() => BackupSchedule.isDue(now, enabled: true, intervalDays: 0),
        throwsArgumentError);
  });
}
