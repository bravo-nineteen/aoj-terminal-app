import 'package:flutter/material.dart';

import 'screens/aoj_desktop.dart';

class AOJApp extends StatelessWidget {
  const AOJApp({super.key, this.startupError});

  final String? startupError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AOJ Terminal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E0B),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7E8B63),
          secondary: Color(0xFFB7A36B),
          surface: Color(0xFF121813),
        ),
        useMaterial3: true,
      ),
      home: AOJDesktop(startupError: startupError),
    );
  }
}
