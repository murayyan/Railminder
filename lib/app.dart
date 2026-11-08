import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'features/home/home_screen.dart';

class RailminderApp extends StatelessWidget {
  const RailminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Railminder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
