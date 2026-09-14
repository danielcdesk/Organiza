import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../domain/models.dart';

class ReportExportService {
  const ReportExportService();

  Future<File> exportTransactions(
    Iterable<TransactionRecord> items, {
    DateTime? period,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final folder =
        Directory(path.join(directory.path, 'Organiza', 'relatorios'));
    if (!folder.existsSync()) folder.createSync(recursive: true);
    final now = DateTime.now();
    final stamp = now.toIso8601String().replaceAll(':', '-');
    final periodLabel = period == null
        ? 'completo'
        : '${period.year}-${period.month.toString().padLeft(2, '0')}';
    final file =
        File(path.join(folder.path, 'relatorio-$periodLabel-$stamp.csv'));
    final rows = <String>[
      'data;tipo;descricao;categoria;subcategoria;valor_centavos;status;forma;conta_id'
    ];
    for (final item in items) {
      rows.add([
        item.occurredOn.toIso8601String().substring(0, 10),
        item.type.name,
        _escape(item.description),
        _escape(item.category),
        _escape(item.subcategory),
        item.amountInCents,
        item.isSettled ? 'pago' : 'pendente',
        item.scheduleType.name,
        item.accountId,
      ].join(';'));
    }
    await file.writeAsString('\uFEFF${rows.join('\r\n')}');
    return file;
  }

  String _escape(String value) => '"${value.replaceAll('"', '""')}"';
}
