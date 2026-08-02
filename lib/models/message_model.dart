enum MessageStatus { sent, delivered, read }

class MessageModel {
  final String id;
  final String pairCode;
  final String senderId;
  final String receiverId;
  final String content;
  final String? reaction;
  final String? replyToId;
  final String? replyToContent;
  final MessageStatus status;
  final bool isStarred;
  final bool isDeleted;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.pairCode,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.reaction,
    this.replyToId,
    this.replyToContent,
    this.status = MessageStatus.sent,
    this.isStarred = false,
    this.isDeleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    MessageStatus parseStatus(String? statusStr) {
      switch (statusStr) {
        case 'delivered':
          return MessageStatus.delivered;
        case 'read':
          return MessageStatus.read;
        case 'sent':
        default:
          return MessageStatus.sent;
      }
    }

    return MessageModel(
      id: json['id'] as String,
      pairCode: json['pair_code'] as String? ?? 'DUO2026',
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      content: json['content'] as String? ?? '',
      reaction: json['reaction'] as String?,
      replyToId: json['reply_to_id'] as String?,
      replyToContent: json['reply_to_content'] as String?,
      status: parseStatus(json['status'] as String?),
      isStarred: json['is_starred'] as bool? ?? false,
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pair_code': pairCode,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'reaction': reaction,
      'reply_to_id': replyToId,
      'reply_to_content': replyToContent,
      'status': status.name,
      'is_starred': isStarred,
      'is_deleted': isDeleted,
      'created_at': createdAt.toIso8601String(),
    };
  }

  MessageModel copyWith({
    String? id,
    String? pairCode,
    String? senderId,
    String? receiverId,
    String? content,
    String? reaction,
    String? replyToId,
    String? replyToContent,
    MessageStatus? status,
    bool? isStarred,
    bool? isDeleted,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      pairCode: pairCode ?? this.pairCode,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      reaction: reaction ?? this.reaction,
      replyToId: replyToId ?? this.replyToId,
      replyToContent: replyToContent ?? this.replyToContent,
      status: status ?? this.status,
      isStarred: isStarred ?? this.isStarred,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
