import 'package:flutter/material.dart';
import 'aoj_app.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? startupError;

  try {
    await SupabaseService.initialize();
  } catch (e) {
    startupError = e.toString();
  }

  runApp(AOJApp(startupError: startupError));
}
