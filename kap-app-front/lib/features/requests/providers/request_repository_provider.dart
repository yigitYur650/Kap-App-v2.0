import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/repositories/request_repository.dart';
import '../data/supabase_request_repository.dart';

/// Provider to access the [RequestRepository] implementation.
final requestRepositoryProvider = Provider<RequestRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return SupabaseRequestRepository(supabaseClient);
});
