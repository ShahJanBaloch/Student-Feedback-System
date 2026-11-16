import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env.dart';
import 'supabase_provider.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  if (!Env.isConfigured) {
    return const Stream<AuthState>.empty();
  }
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

final currentSessionProvider = Provider<Session?>((ref) {
  if (!Env.isConfigured) {
    return null;
  }
  final asyncAuth = ref.watch(authStateProvider);
  return asyncAuth.maybeWhen(
    data: (state) => state.session,
    orElse: () => ref.watch(supabaseClientProvider).auth.currentSession,
  );
});
