import 'package:flutter/material.dart';

import '../domain/financial_rules.dart';
import '../domain/models.dart';
import 'organiza_theme.dart';

part 'shared_surface_widgets.part.dart';
part 'shared_finance_widgets.part.dart';
part 'shared_action_widgets.part.dart';

EdgeInsets pagePadding(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 600
        ? const EdgeInsets.fromLTRB(14, 14, 14, 26)
        : const EdgeInsets.fromLTRB(34, 30, 34, 44);
