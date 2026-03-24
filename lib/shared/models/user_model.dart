import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore data model for a ClassMate user.
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String classGroup;
  final String section;
  final String rollNo;
  final String grNumber;
  final String photoUrl;
  final String bio;
  final String gender; // "Male" | "Female" | "Other"
  final String role; // "student" | "admin"
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.classGroup,
    required this.section,
    required this.rollNo,
    required this.grNumber,
    required this.photoUrl,
    required this.bio,
    required this.gender,
    required this.role,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';

  /// Returns the provided profile photo, or the Marwadi Student Portal photo 
  /// using their GR number if no custom photo is set.
  String get effectivePhotoUrl {
    if (photoUrl.isNotEmpty && photoUrl.startsWith('http')) return photoUrl;
    if (grNumber.isNotEmpty) {
      return 'https://student.marwadiuniversity.ac.in:553/handler/getImage.ashx?SID=$grNumber';
    }
    return '';
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid:        doc.id,
      name:       d['name']       as String? ?? '',
      email:      d['email']      as String? ?? '',
      phone:      d['phone']      as String? ?? '',
      classGroup: d['classGroup'] as String? ?? '',
      section:    d['section']    as String? ?? '',
      rollNo:     d['rollNo']     as String? ?? '',
      grNumber:   d['grNumber']   as String? ?? '',
      photoUrl:   d['photoUrl']   as String? ?? '',
      bio:        d['bio']        as String? ?? '',
      gender:     d['gender']     as String? ?? 'Other',
      role:       d['role']       as String? ?? 'student',
      createdAt:  (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name':       name,
    'email':      email,
    'phone':      phone,
    'classGroup': classGroup,
    'section':    section,
    'rollNo':     rollNo,
    'grNumber':   grNumber,
    'photoUrl':   photoUrl,
    'bio':        bio,
    'gender':     gender,
    'role':       role,
    'createdAt':  Timestamp.fromDate(createdAt),
  };

  UserModel copyWith({
    String? name,
    String? phone,
    String? classGroup,
    String? section,
    String? rollNo,
    String? grNumber,
    String? photoUrl,
    String? bio,
    String? gender,
  }) => UserModel(
    uid:        uid,
    name:       name        ?? this.name,
    email:      email,
    phone:      phone       ?? this.phone,
    classGroup: classGroup  ?? this.classGroup,
    section:    section     ?? this.section,
    rollNo:     rollNo      ?? this.rollNo,
    grNumber:   grNumber    ?? this.grNumber,
    photoUrl:   photoUrl    ?? this.photoUrl,
    bio:        bio         ?? this.bio,
    gender:     gender      ?? this.gender,
    role:       role,
    createdAt:  createdAt,
  );
}
