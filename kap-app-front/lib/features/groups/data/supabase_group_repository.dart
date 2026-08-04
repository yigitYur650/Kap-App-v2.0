import 'dart:io';
import 'dart:math' as dart_math;
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
  }) async {
    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) {
      return const Left(UnknownFailure('User is not authenticated'));
    }

    try {
      // Generate a 12-char hex join code (6 random bytes → 12 hex chars)
      // This uses Supabase's gen_random_bytes() via a raw RPC call,
      // or we generate it client-side using Dart's Random.secure().
      final joinCode = _generateJoinCode();

      // 1. Insert the new group row with join_code
      final groupResponse = await _supabaseClient
          .from('groups')
          .insert({
            'name': name,
            'created_by': currentUser.id,
            'join_code': joinCode,
          })
          .select()
          .single();

      final groupId = groupResponse['id'] as String;

      // 2. Insert the creator into group_members
      await _supabaseClient.from('group_members').insert({
        'user_id': currentUser.id,
        'group_id': groupId,
      });

      return Right(GroupModel.fromJson(groupResponse));
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  /// Generates an 8-character join code in 4-4 format (e.g. XK7M-2R9P).
  /// Uses 4 random bytes → hex encode → split into XXXX-XXXX.
  String _generateJoinCode() {
    final random = dart_math.Random.secure();
    final bytes = List<int>.generate(4, (_) => random.nextInt(256));
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
    return '${hex.substring(0, 4)}-${hex.substring(4, 8)}';
  }

  @override
  Future<Either<Failure, void>> joinGroup({
    required String joinCode,
  }) async {
    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) {
      return const Left(UnknownFailure('User is not authenticated'));
    }

    try {
      // 1. Query groups by join_code to find the target group
      final groupResponse = await _supabaseClient
          .from('groups')
          .select('id')
          .eq('join_code', joinCode)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (groupResponse == null) {
        return const Left(UnknownFailure('No active group found with this join code'));
      }
      final groupId = groupResponse['id'] as String;

      // 2. Insert the joining user into group_members
      await _supabaseClient.from('group_members').insert({
        'user_id': currentUser.id,
        'group_id': groupId,
      });

      return const Right(null);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteGroup({
    required String groupId,
  }) async {
    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) {
      return const Left(UnknownFailure('User is not authenticated'));
    }

    try {
      // Soft delete: set deleted_at to now
      // RLS will check is_group_admin(id) before allowing the update
      await _supabaseClient
          .from('groups')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', groupId);

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
          .eq('group_members.user_id', currentUser.id)
          .isFilter('deleted_at', null);
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
