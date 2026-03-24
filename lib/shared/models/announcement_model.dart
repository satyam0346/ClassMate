import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore data model for an announcement.
class AnnouncementModel {
  final String   id;
  final String   title;
  final String   message;
  final String   attachmentUrl;
  final DateTime createdAt;
  final String   createdBy;
  final bool     isPinned;        // Pinned announcements float to top
  final bool     fcmSent;         // Whether FCM push was dispatched

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.createdBy,
    this.attachmentUrl = '',
    this.isPinned      = false,
    this.fcmSent       = false,
  });

  bool get hasAttachment => attachmentUrl.isNotEmpty;

  factory AnnouncementModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AnnouncementModel(
      id:            doc.id,
      title:         d['title']         as String? ?? '',
      message:       d['message']       as String? ?? '',
      attachmentUrl: d['attachmentUrl'] as String? ?? '',
      createdAt:     (d['createdAt']    as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy:     d['createdBy']     as String? ?? '',
      isPinned:      d['isPinned']      as bool?   ?? false,
      fcmSent:       d['fcmSent']       as bool?   ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title':         title,
        'message':       message,
        'attachmentUrl': attachmentUrl,
        'createdAt':     Timestamp.fromDate(createdAt),
        'createdBy':     createdBy,
        'isPinned':      isPinned,
        'fcmSent':       fcmSent,
      };

  AnnouncementModel copyWith({
    String? title,
    String? message,
    String? attachmentUrl,
    bool?   isPinned,
    bool?   fcmSent,
  }) =>
      AnnouncementModel(
        id:            id,
        title:         title         ?? this.title,
        message:       message       ?? this.message,
        attachmentUrl: attachmentUrl ?? this.attachmentUrl,
        createdAt:     createdAt,
        createdBy:     createdBy,
        isPinned:      isPinned      ?? this.isPinned,
        fcmSent:       fcmSent       ?? this.fcmSent,
      );
}
