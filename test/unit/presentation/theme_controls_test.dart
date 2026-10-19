import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/presentation/organiza_theme.dart';

void main() {
  test('controles compartilham estados selecionado, foco e desabilitado', () {
    for (final theme in [OrganizaTheme.light(), OrganizaTheme.dark()]) {
      final checkbox = theme.checkboxTheme;
      expect(checkbox.fillColor!.resolve({WidgetState.selected}),
          theme.colorScheme.primary);
      expect(checkbox.fillColor!.resolve({WidgetState.disabled}),
          isNot(theme.colorScheme.primary));
      expect(checkbox.overlayColor!.resolve({WidgetState.focused}), isNotNull);
      expect(theme.radioTheme.fillColor!.resolve({WidgetState.selected}),
          theme.colorScheme.primary);
      expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
    }
  });
}
