import 'package:flutter/material.dart';

import 'screens/aoj_desktop.dart';

class AOJApp extends StatefulWidget {
  const AOJApp({super.key, this.startupError});

  final String? startupError;

  @override
  State<AOJApp> createState() => _AOJAppState();
}

class _AOJAppState extends State<AOJApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleThemeMode() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF1F4EE),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF355E3B),
        secondary: Color(0xFF8A6D3B),
        surface: Color(0xFFFFFFFF),
      ),
      useMaterial3: true,
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0A0E0B),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF7E8B63),
        secondary: Color(0xFFB7A36B),
        surface: Color(0xFF121813),
      ),
      useMaterial3: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AOJ Terminal',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home: AOJDesktop(
        startupError: widget.startupError,
        isDarkTheme: _themeMode != ThemeMode.light,
        onToggleTheme: _toggleThemeMode,
      ),
    );
  }
}
