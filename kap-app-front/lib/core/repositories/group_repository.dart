import 'package:fpdart/fpdart.dart';
import '../errors/failure.dart';
import '../models/group_model.dart';

abstract class GroupRepository {
  /// Creates a new group and automatically adds the creator as the admin of the group.
  /// Creates a new group and automatically adds the creator as a member of the group.
  Future<Either<Failure, GroupModel>> createGroup({
    required String name,
  });

  /// Joins a group by its unique [joinCode].
  /// Each group has its own join_code (not the user's unique_code).
  Future<Either<Failure, void>> joinGroup({
    required String joinCode,
  });

  /// Deletes a group (soft delete by setting deleted_at).
  /// Only group admins can delete a group.
  Future<Either<Failure, void>> deleteGroup({
    required String groupId,
  });

  /// Fetches all active groups that the authenticated user belongs to.
  Future<Either<Failure, List<GroupModel>>> getMyGroups();
}
