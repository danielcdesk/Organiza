import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../domain/models.dart';

class ReportExportService {
  const ReportExportService();

  Future<File> exportTransactions(Iterable<TransactionRecord> items) async {
    final directory = await getApplicationDocumentsDirectory();
    final folder =
        Directory(path.join(directory.path, 'Organiza', 'relatorios'));
    if (!folder.existsSync()) folder.createSync(recursive: true);
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File(path.join(folder.path, 'relatorio-$stamp.csv'));
    final rows = <String>['data;tipo;descricao;valor_centavos;conta_id'];
    for (final item in items) {
      rows.add([
        item.occurredOn.toIso8601String().substring(0, 10),
        item.type.name,
        _escape(item.description),
        item.amountInCents,
        item.accountId,
      ].join(';'));
    }
    await file.writeAsString(rows.join('\n'));
    return file;
  }

  String _escape(String value) => '"${value.replaceAll('"', '""')}"';
}
