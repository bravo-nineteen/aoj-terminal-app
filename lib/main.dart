import 'package:flutter/material.dart';
import 'aoj_app.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const AOJApp());
}
