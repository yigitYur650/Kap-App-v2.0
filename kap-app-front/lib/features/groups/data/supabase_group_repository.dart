import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/failure.dart';
import '../../../core/models/group_model.dart';
import '../../../core/repositories/group_repository.dart';

/// An implementation of [GroupRepository] using Supabase.
class SupabaseGroupRepository implements GroupRepository {
  final SupabaseClient _supabaseClient;

  SupabaseGroupRepository(this._supabaseClient);

  @override
  Future<Either<Failure, GroupModel>> createGroup({
    required String name,
    required String type,
  }) async {
    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) {
      return const Left(UnknownFailure('User is not authenticated'));
    }

    String? createdGroupId;
    try {
      // 1. Insert the new group row
      final groupResponse = await _supabaseClient
          .from('groups')
          .insert({
            'name': name,
            'type': type,
            'created_by': currentUser.id,
          })
          .select()
          .single();

      createdGroupId = groupResponse['id'] as String;

      // 2. Insert the creator into group_members as admin
      await _supabaseClient.from('group_members').insert({
        'user_id': currentUser.id,
        'group_id': createdGroupId,
        'role': 'admin',
      });

      return Right(GroupModel.fromJson(groupResponse));
    } catch (e) {
      // Rollback newly created group if membership insertion failed
      if (createdGroupId != null) {
        try {
          await _supabaseClient.from('groups').delete().eq('id', createdGroupId);
        } catch (_) {
          // Do not mask primary failure
        }
      }
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, void>> joinGroup({
    required String uniqueCode,
  }) async {
    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) {
      return const Left(UnknownFailure('User is not authenticated'));
    }

    try {
      // 1. Query public_user_lookup to find the owner's id
      final userResponse = await _supabaseClient
          .from('public_user_lookup')
          .select('id')
          .eq('unique_code', uniqueCode)
          .maybeSingle();

      if (userResponse == null) {
        return const Left(UnknownFailure('User with unique code not found'));
      }
      final ownerId = userResponse['id'] as String;

      // 2. Query groups to find the active family group created by this owner
      final groupResponse = await _supabaseClient
          .from('groups')
          .select('id')
          .eq('created_by', ownerId)
          .eq('type', 'family')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (groupResponse == null) {
        return const Left(UnknownFailure('No active family group found for the user'));
      }
      final groupId = groupResponse['id'] as String;

      // 3. Insert the joining user into group_members as member
      await _supabaseClient.from('group_members').insert({
        'user_id': currentUser.id,
        'group_id': groupId,
        'role': 'member',
      });

      return const Right(null);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, List<GroupModel>>> getMyGroups() async {
    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) {
      return const Left(UnknownFailure('User is not authenticated'));
    }

    try {
      final response = await _supabaseClient
          .from('groups')
          .select('*, group_members!inner(user_id)')
          .eq('group_members.user_id', currentUser.id);
      // Explanatory comment: dynamic is used here because JSON payload values can represent multiple different Dart types (e.g. String, bool, num, null).
      final list = (response as List)
          .map((json) => GroupModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return Right(list);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  /// Maps repository exceptions into domain failures.
  Failure _mapException(Object e) {
    if (e is PostgrestException) {
      if (e.code == '23505') {
        return UnknownFailure('Database unique constraint violation: ${e.message}');
      }
      return UnknownFailure('Database error: ${e.message}');
    }
    if (e is AuthException) {
      return UnknownFailure('Authentication error: ${e.message}');
    }
    if (e is SocketException) {
      return const NetworkFailure();
    }
    final str = e.toString().toLowerCase();
    if (str.contains('socketexception') ||
        str.contains('network') ||
        str.contains('connection failed')) {
      return const NetworkFailure();
    }
    return UnknownFailure(e.toString());
  }
}
