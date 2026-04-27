class UserModel {
  final int id;
  final String username;
  final String email;
  final bool isVerified;
  final VipInfo vip;
  final String? createdAt;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.isVerified = false,
    this.vip = const VipInfo(),
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      isVerified: json['is_verified'] ?? false,
      vip: json['vip'] != null ? VipInfo.fromJson(json['vip']) : const VipInfo(),
      createdAt: json['created_at'],
    );
  }
}

class VipInfo {
  final int level;
  final String levelName;
  final bool isActive;
  final String? expiresAt;

  const VipInfo({
    this.level = 0,
    this.levelName = '普通用户',
    this.isActive = false,
    this.expiresAt,
  });

  factory VipInfo.fromJson(Map<String, dynamic> json) {
    return VipInfo(
      level: json['level'] ?? 0,
      levelName: json['level_name'] ?? '普通用户',
      isActive: json['is_active'] ?? false,
      expiresAt: json['expires_at'],
    );
  }

  String get badgeText {
    if (!isActive) return '普通';
    return levelName;
  }
}

class MessageModel {
  final String id;
  final String senderName;
  final String content;
  final DateTime time;
  final bool isMe;
  final MessageType type;

  MessageModel({
    required this.id,
    required this.senderName,
    required this.content,
    required this.time,
    required this.isMe,
    this.type = MessageType.text,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json, {required String myName}) {
    return MessageModel(
      id: json['id'] ?? '',
      senderName: json['sender'] ?? '',
      content: json['content'] ?? '',
      time: DateTime.tryParse(json['time'] ?? '') ?? DateTime.now(),
      isMe: (json['sender'] ?? '') == myName,
    );
  }
}

enum MessageType { text, image, system }
