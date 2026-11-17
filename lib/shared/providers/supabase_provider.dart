import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  if (!Env.isConfigured) {
    throw StateError('Supabase is not configured.');
  }
  try {
    return Supabase.instance.client;
  } on AssertionError {
    // Widget tests do not run main(), so the Flutter singleton is not
    // initialized. A direct client keeps provider construction testable.
    return SupabaseClient(
      Env.supabaseUrl,
      Env.supabaseAnonKey,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  }
});
