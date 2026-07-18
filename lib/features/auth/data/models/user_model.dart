import 'package:buy_control/core/sync/syncable.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String syncStatus;
  final int version;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
    required this.version,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final sync = SyncableFieldsData.fromMap(map);
    return UserModel(
      id: sync.id,
      name: map['name'] as String,
      email: map['email'] as String,
      avatarUrl: map['avatarUrl'] as String?,
      createdAt: sync.createdAt,
      updatedAt: sync.updatedAt,
      deletedAt: sync.deletedAt,
      syncStatus: sync.syncStatus.name,
      version: sync.version,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'syncStatus': syncStatus,
      'version': version,
    };
  }
}
