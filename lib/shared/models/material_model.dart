import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore data model for a study material entry.
class MaterialModel {
  final String   id;
  final String   title;
  final String   subject;
  final String   description;
  final String   fileType;      // "pdf" | "image" | "doc" | "link" | "other"
  final String   url;           // Download / access URL
  final String   fileName;      // Original file name (for display)
  final int      fileSize;      // Bytes (0 for links)
  final String   uploadedBy;
  final DateTime uploadedAt;

  const MaterialModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.url,
    required this.uploadedBy,
    required this.uploadedAt,
    this.description = '',
    this.fileType    = 'other',
    this.fileName    = '',
    this.fileSize    = 0,
  });

  // ── Computed ─────────────────────────────────────────────

  bool get isLink  => fileType == 'link';
  bool get isPdf   => fileType == 'pdf';
  bool get isImage => fileType == 'image';

  /// Formatted file size string.
  String get fileSizeLabel {
    if (fileSize == 0) return '';
    if (fileSize < 1024)       return '${fileSize} B';
    if (fileSize < 1048576)    return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / 1048576).toStringAsFixed(1)} MB';
  }

  // ── Serialisation ─────────────────────────────────────────

  factory MaterialModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MaterialModel(
      id:          doc.id,
      title:       d['title']       as String? ?? '',
      subject:     d['subject']     as String? ?? '',
      description: d['description'] as String? ?? '',
      fileType:    d['fileType']    as String? ??
                   (d['type'] as String? ?? 'other'),
      url:         d['url']         as String? ?? '',
      fileName:    d['fileName']    as String? ?? '',
      fileSize:    d['fileSize']    as int?    ?? 0,
      uploadedBy:  d['uploadedBy']  as String? ?? '',
      uploadedAt:  (d['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title':       title,
        'subject':     subject,
        'description': description,
        'fileType':    fileType,
        'url':         url,
        'fileName':    fileName,
        'fileSize':    fileSize,
        'uploadedBy':  uploadedBy,
        'uploadedAt':  Timestamp.fromDate(uploadedAt),
      };
}
