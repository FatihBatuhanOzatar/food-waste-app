import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Type-safe reader for environment variables loaded from the `.env` file.
///
/// All values are read at call-time from [dotenv]. Ensure [dotenv.load]
/// has been called before accessing any getter.
class Env {
  Env._();

  /// The Supabase project URL.
  ///
  /// Example: `https://xyzabc.supabase.co`
  static String get supabaseUrl => _require('SUPABASE_URL');

  /// The Supabase anonymous (public) API key.
  static String get supabaseAnonKey => _require('SUPABASE_ANON_KEY');

  /// The Google Maps API key for map rendering.
  static String get googleMapsApiKey => _require('GOOGLE_MAPS_API_KEY');

  /// Reads a required environment variable by [key].
  ///
  /// Throws [StateError] if the variable is missing or empty,
  /// preventing silent misconfiguration at startup.
  static String _require(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw StateError(
        'Missing required environment variable: $key. '
        'Ensure .env file is present and contains this key.',
      );
    }
    return value;
  }
}
