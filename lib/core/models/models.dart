
enum ProfilePrivacy { public, contacts, private }

class UserModel {
  final String id;
  final String? phone;
  final String? username;
  final String? fullName;
  final String? avatarUrl;
  final String status;
  final ProfilePrivacy privacy;
  final bool isPremium;
  final bool isOnline;
  final DateTime lastSeen;

  UserModel({
    required this.id,
    this.phone,
    this.username,
    this.fullName,
    this.avatarUrl,
    required this.status,
    required this.privacy,
    required this.isPremium,
    required this.isOnline,
    required this.lastSeen,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      phone: json['phone'],
      username: json['username'],
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      status: json['status'] ?? 'Hey there! I am using Crystal Messenger.',
      privacy: ProfilePrivacy.values.firstWhere(
        (e) => e.name == (json['profile_card_privacy'] ?? 'public'),
        orElse: () => ProfilePrivacy.public,
      ),
      isPremium: json['is_premium'] ?? false,
      isOnline: json['is_online'] ?? false,
      lastSeen: json['last_seen'] != null 
          ? DateTime.parse(json['last_seen']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    'username': username,
    'full_name': fullName,
    'avatar_url': avatarUrl,
    'status': status,
    'profile_card_privacy': privacy.name,
    'is_premium': isPremium,
    'is_online': isOnline,
    'last_seen': lastSeen.toIso8601String(),
  };

  String get displayName => fullName ?? username ?? phone ?? 'User';
}

enum RoomType { direct, group }

class RoomModel {
  final String id;
  final RoomType type;
  final String? name;
  final String? description;
  final String? avatarUrl;
  final String? lastMessage;
  final DateTime updatedAt;

  RoomModel({
    required this.id,
    required this.type,
    this.name,
    this.description,
    this.avatarUrl,
    this.lastMessage,
    required this.updatedAt,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] ?? '',
      type: RoomType.values.firstWhere(
        (e) => e.name == (json['type'] ?? 'direct'),
        orElse: () => RoomType.direct,
      ),
      name: json['name'],
      description: json['description'],
      avatarUrl: json['avatar_url'],
      lastMessage: json['last_message'],
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'name': name,
    'description': description,
    'avatar_url': avatarUrl,
    'last_message': lastMessage,
    'updated_at': updatedAt.toIso8601String(),
  };
}

enum MessageType { text, image, video, audio, document, system }

class MessageModel {
  final String id;
  final String roomId;
  final String senderId;
  final String? textContent;
  final String? mediaUrl;
  final MessageType type;
  final bool isDelivered;
  final bool isRead;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    this.textContent,
    this.mediaUrl,
    this.type = MessageType.text,
    required this.isDelivered,
    required this.isRead,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      roomId: json['room_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      textContent: json['text_content'],
      mediaUrl: json['media_url'],
      type: MessageType.values.firstWhere(
        (e) => e.name == (json['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      isDelivered: json['is_delivered'] ?? false,
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']).toLocal()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'room_id': roomId,
    'sender_id': senderId,
    'text_content': textContent,
    'media_url': mediaUrl,
    'type': type.name,
    'is_delivered': isDelivered,
    'is_read': isRead,
    'created_at': createdAt.toIso8601String(),
  };
}

enum CallType { audio, video }
enum CallStatus { dialing, ringing, connected, ended, rejected }

class CallSessionModel {
  final String id;
  final String callerId;
  final String receiverId;
  final CallType type;
  final CallStatus status;
  final Map<String, dynamic>? sdpOffer;
  final Map<String, dynamic>? sdpAnswer;
  final List<dynamic> iceCandidatesCaller;
  final List<dynamic> iceCandidatesReceiver;
  final DateTime createdAt;

  CallSessionModel({
    required this.id,
    required this.callerId,
    required this.receiverId,
    required this.type,
    required this.status,
    this.sdpOffer,
    this.sdpAnswer,
    required this.iceCandidatesCaller,
    required this.iceCandidatesReceiver,
    required this.createdAt,
  });

  factory CallSessionModel.fromJson(Map<String, dynamic> json) {
    return CallSessionModel(
      id: json['id'] ?? '',
      callerId: json['caller_id'] ?? '',
      receiverId: json['receiver_id'] ?? '',
      type: CallType.values.firstWhere(
        (e) => e.name == (json['type'] ?? 'audio'),
        orElse: () => CallType.audio,
      ),
      status: CallStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? 'dialing'),
        orElse: () => CallStatus.dialing,
      ),
      sdpOffer: json['sdp_offer'],
      sdpAnswer: json['sdp_answer'],
      iceCandidatesCaller: json['ice_candidates_caller'] ?? [],
      iceCandidatesReceiver: json['ice_candidates_receiver'] ?? [],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'caller_id': callerId,
    'receiver_id': receiverId,
    'type': type.name,
    'status': status.name,
    'sdp_offer': sdpOffer,
    'sdp_answer': sdpAnswer,
    'ice_candidates_caller': iceCandidatesCaller,
    'ice_candidates_receiver': iceCandidatesReceiver,
    'created_at': createdAt.toIso8601String(),
  };
}
