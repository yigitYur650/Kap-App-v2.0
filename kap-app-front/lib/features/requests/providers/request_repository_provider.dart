import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/repositories/request_repository.dart';
import '../../requests/data/supabase_request_repository.dart';

final requestRepositoryProvider = Provider<RequestRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return SupabaseRequestRepository(supabaseClient);
});
