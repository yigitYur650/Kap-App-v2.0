import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/group_model.dart';
import '../../providers/group_repository_provider.dart';

/// Provider that fetches the current user's groups asynchronously from the repository.
final userGroupsProvider = FutureProvider<List<GroupModel>>((ref) async {
  final repository = ref.watch(groupRepositoryProvider);
  final result = await repository.getMyGroups();
  return result.fold(
    (failure) => throw failure,
    (groups) => groups,
  );
});
