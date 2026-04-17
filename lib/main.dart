import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/supabase_client.dart';

/// Entry point for the Food Waste App.
///
/// Execution order:
/// 1. [WidgetsFlutterBinding.ensureInitialized] — required before any async work.
/// 2. [dotenv.load] — reads `.env` asset into memory.
/// 3. [SupabaseClientInitializer.initialize] — boots Supabase with env credentials.
/// 4. [runApp] — mounts the widget tree inside a [ProviderScope].
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from the bundled .env asset.
  await dotenv.load();

  // Initialize Supabase using credentials from the loaded environment.
  await SupabaseClientInitializer.initialize();

  runApp(const ProviderScope(child: App()));
}
