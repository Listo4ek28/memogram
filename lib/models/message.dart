class Message {
  final int messageId;
  final String type;
  final String? text;
  final String? image;
  final int reactions;
  final bool isFavorite;
  final int fromUser;
  final String time;

  Message({
    required this.messageId,
    required this.type,
    this.text,
    this.image,
    required this.reactions,
    required this.isFavorite,
    required this.fromUser,
    required this.time,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      messageId: json['message_id'],
      type: json['type'],
      text: json['text'],
      image: json['image'],
      reactions: json['reactions'] ?? 0,
      isFavorite: json['is_favorite'] ?? false,
      fromUser: json['from_user'],
      time: json['time'],
    );
  }
}