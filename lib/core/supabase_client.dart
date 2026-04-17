import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/env.dart';

/// Helper for initializing the Supabase singleton.
///
/// Call [initialize] once at app startup before any Supabase
/// operations are performed.
class SupabaseClientInitializer {
  SupabaseClientInitializer._();

  /// Initializes the Supabase client with credentials loaded from [Env].
  ///
  /// Must be called after `dotenv.load()` in [main].
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
  }
}
