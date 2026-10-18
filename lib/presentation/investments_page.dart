import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../application/organiza_store.dart';
import '../domain/financial_rules.dart';
import '../domain/investment_rules.dart';
import '../domain/models.dart';
import 'shared_widgets.dart';

part 'investments_main.part.dart';
part 'investments_telemetry.part.dart';
part 'investments_summary.part.dart';
part 'investments_positions.part.dart';

String _percent(double rate, {int decimals = 2}) =>
    (rate * 100).toStringAsFixed(decimals).replaceAll('.', ',');
