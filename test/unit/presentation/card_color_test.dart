import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/presentation/card_color.dart';

void main() {
  test('texto contrasta com cartão claro ou escuro', () {
    expect(cardContentColor(const Color(0xFFFFFFFF)), Colors.black);
    expect(cardContentColor(const Color(0xFFFFEEAA)), Colors.black);
    expect(cardContentColor(const Color(0xFF245943)), Colors.white);
    expect(cardContentColor(const Color(0xFF10141A)), Colors.white);
  });
}
