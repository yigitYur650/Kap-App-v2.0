import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/inventory_item.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/repositories/inventory_repository.dart';
import '../../../groups/presentation/providers/active_group_provider.dart';
import '../../data/supabase_inventory_repository.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return SupabaseInventoryRepository(supabaseClient);
});

final inventoryProvider = StreamProvider<List<InventoryItem>>((ref) {
  final activeGroup = ref.watch(activeGroupProvider);
  if (activeGroup == null) {
    return const Stream.empty();
  }

  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.getInventoryStream(activeGroup.id);
});
