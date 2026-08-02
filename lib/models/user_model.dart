class UserModel {
  final String id;
  final String pairCode;
  final String name;
  final String? avatarUrl;
  final String statusMessage;
  final bool isOnline;
  final DateTime lastSeen;
  final bool isTyping;

  UserModel({
    required this.id,
    required this.pairCode,
    required this.name,
    this.avatarUrl,
    this.statusMessage = 'Hey there! I am using DuoChat.',
    this.isOnline = false,
    DateTime? lastSeen,
    this.isTyping = false,
  }) : lastSeen = lastSeen ?? DateTime.now();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      pairCode: json['pair_code'] as String? ?? 'DUO2026',
      name: json['name'] as String? ?? 'Partner',
      avatarUrl: json['avatar_url'] as String?,
      statusMessage: json['status_message'] as String? ?? 'Using DuoChat',
      isOnline: json['is_online'] as bool? ?? false,
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'] as String)
          : DateTime.now(),
      isTyping: json['is_typing'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pair_code': pairCode,
      'name': name,
      'avatar_url': avatarUrl,
      'status_message': statusMessage,
      'is_online': isOnline,
      'last_seen': lastSeen.toIso8601String(),
      'is_typing': isTyping,
    };
  }

  UserModel copyWith({
    String? id,
    String? pairCode,
    String? name,
    String? avatarUrl,
    String? statusMessage,
    bool? isOnline,
    DateTime? lastSeen,
    bool? isTyping,
  }) {
    return UserModel(
      id: id ?? this.id,
      pairCode: pairCode ?? this.pairCode,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      statusMessage: statusMessage ?? this.statusMessage,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}
