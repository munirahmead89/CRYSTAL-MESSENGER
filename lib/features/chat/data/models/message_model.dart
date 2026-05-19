/// Message data model supporting text, images, videos, files, and voice notes
class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String? recipientId;
  final String? content; // Text content
  final MessageType messageType;
  final List<String>? mediaUrls; // URLs for images/videos
  final String? fileName; // For file attachments
  final int? fileSizeBytes; // File size in bytes
  final String? voiceNotePath; // Path for voice notes
  final int? voiceNoteDurationMs; // Duration in milliseconds
  final DateTime sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.recipientId,
    this.content,
    required this.messageType,
    this.mediaUrls,
    this.fileName,
    this.fileSizeBytes,
    this.voiceNotePath,
    this.voiceNoteDurationMs,
    required this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.isDeleted = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      conversationId: json['conversation_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      recipientId: json['recipient_id'] as String?,
      content: json['content'] as String?,
      messageType: MessageType.values.byName(json['message_type'] ?? 'text'),
      mediaUrls: (json['media_urls'] as List?)?.cast<String>(),
      fileName: json['file_name'] as String?,
      fileSizeBytes: json['file_size_bytes'] as int?,
      voiceNotePath: json['voice_note_path'] as String?,
      voiceNoteDurationMs: json['voice_note_duration_ms'] as int?,
      sentAt: json['sent_at'] != null
          ? DateTime.tryParse(json['sent_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      deliveredAt: json['delivered_at'] != null
          ? DateTime.tryParse(json['delivered_at'] as String)
          : null,
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'] as String)
          : null,
      isDeleted: (json['is_deleted'] ?? false) as bool,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversation_id': conversationId,
    'sender_id': senderId,
    'recipient_id': recipientId,
    'content': content,
    'message_type': messageType.name,
    'media_urls': mediaUrls,
    'file_name': fileName,
    'file_size_bytes': fileSizeBytes,
    'voice_note_path': voiceNotePath,
    'voice_note_duration_ms': voiceNoteDurationMs,
    'sent_at': sentAt.toIso8601String(),
    'delivered_at': deliveredAt?.toIso8601String(),
    'read_at': readAt?.toIso8601String(),
    'is_deleted': isDeleted,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };

  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? recipientId,
    String? content,
    MessageType? messageType,
    List<String>? mediaUrls,
    String? fileName,
    int? fileSizeBytes,
    String? voiceNotePath,
    int? voiceNoteDurationMs,
    DateTime? sentAt,
    DateTime? deliveredAt,
    DateTime? readAt,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      fileName: fileName ?? this.fileName,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      voiceNotePath: voiceNotePath ?? this.voiceNotePath,
      voiceNoteDurationMs: voiceNoteDurationMs ?? this.voiceNoteDurationMs,
      sentAt: sentAt ?? this.sentAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Enum for different message types
enum MessageType {
  text,
  image,
  video,
  file,
  voiceNote,
  call,
}
