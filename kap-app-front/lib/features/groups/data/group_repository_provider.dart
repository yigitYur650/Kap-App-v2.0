import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/repositories/group_repository.dart';
import 'supabase_group_repository.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return SupabaseGroupRepository(supabaseClient);
});
