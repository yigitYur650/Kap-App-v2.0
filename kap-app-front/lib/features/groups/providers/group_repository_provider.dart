import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/repositories/group_repository.dart';
import '../data/supabase_group_repository.dart';

/// Provider to access the [GroupRepository] implementation.
final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return SupabaseGroupRepository(supabaseClient);
});
