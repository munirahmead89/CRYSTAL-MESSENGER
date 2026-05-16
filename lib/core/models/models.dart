enum ProfilePrivacy { public, contacts, private }

class UserModel {
  final String id;
  final String? username;
  final String status;
  final ProfilePrivacy privacy;
  final bool isPremium;

  UserModel({
    required this.id,
    this.username,
    required this.status,
    required this.privacy,
    required this.isPremium,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'],
    username: json['username'],
    status: json['status'] ?? '',
    privacy: ProfilePrivacy.values.byName(json['profile_card_privacy'] ?? 'public'),
    isPremium: json['is_premium'] ?? false,
  );
}

class RoomModel {
  final String id;
  final String? name;
  final String? lastMessage;

  RoomModel({required this.id, this.name, this.lastMessage});

  factory RoomModel.fromJson(Map<String, dynamic> json) => RoomModel(
    id: json['id'],
    name: json['name'],
    lastMessage: json['last_message'],
  );
}

enum MessageType { text, image, video, audio, document }

class MessageModel {
  final String id;
  final String roomId;
  final String senderId;
  final String? textContent;
  final MessageType type;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    this.textContent,
    this.type = MessageType.text,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
    id: json['id'] ?? '',
    roomId: json['room_id'] ?? '',
    senderId: json['sender_id'] ?? '',
    textContent: json['text_content'],
    type: MessageType.values.byName(json['type'] ?? 'text'),
    createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'room_id': roomId,
    'sender_id': senderId,
    'text_content': textContent,
    'type': type.name,
    'created_at': createdAt.toIso8601String(),
  };
}
