import 'package:fpdart/fpdart.dart';
import '../errors/failure.dart';
import '../models/group_model.dart';

abstract class GroupRepository {
  /// Creates a new group and automatically adds the creator as the admin of the group.
  Future<Either<Failure, GroupModel>> createGroup({
    required String name,
    required String type,
  });

  /// Joins an existing family group by looking up the creator's user unique code.
  Future<Either<Failure, void>> joinGroup({
    required String uniqueCode,
  });

  /// Fetches all active groups that the authenticated user belongs to.
  Future<Either<Failure, List<GroupModel>>> getMyGroups();
}
