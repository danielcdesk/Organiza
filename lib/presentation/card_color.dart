import 'package:flutter/material.dart';

/// Text/icon color for the card gradient, including user-selected light hues.
Color cardContentColor(Color base) =>
    base.computeLuminance() > .32 ? Colors.black : Colors.white;
