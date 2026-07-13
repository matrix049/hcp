import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  // `ProviderScope` is the root of Riverpod's dependency graph — every provider
  // in `core/di` and the features lives under here.
  runApp(
    const ProviderScope(
      child: HcpSurveyApp(),
    ),
  );
}
