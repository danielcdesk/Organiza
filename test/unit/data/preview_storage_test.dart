import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/database/app_database.dart';

void main() {
  test('preview uses a separate Windows data folder', () {
    const preview = bool.fromEnvironment('ORGANIZA_PREVIEW_BUILD');
    expect(AppDatabase.applicationFolderName,
        preview ? 'OrganizaPreview' : 'Organiza');
  });
}
