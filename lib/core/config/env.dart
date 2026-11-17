/// Reads Supabase settings from compile-time Dart defines.
///
/// The anon key is a public client key. Dart defines can override these
/// defaults for another Supabase project or deployment environment.
class Env {
  const Env._();

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ydfprhodrltkykqxhvnc.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlkZnByb2RybHRreWtxeGh2bmMiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTc5NDU5NDk4MywiZXhwIjoyMTEwMTcwOTgzfQ.IyAOKIpVdIYViXccG8kwtMrjgK0aJmlLK8nPvX_UAfY',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static String? get configurationError {
    if (supabaseUrl.isEmpty) {
      return 'SUPABASE_URL is missing. Run with tool/flutter-with-env.ps1.';
    }
    if (supabaseAnonKey.isEmpty) {
      return 'SUPABASE_ANON_KEY is missing. Add it to .env.example and '
          'run with tool/flutter-with-env.ps1.';
    }
    return null;
  }
}
