class UserProfile {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoURL;
  final String? phoneNumber;
  final String? department;
  final String? studentId;

  UserProfile({
    required this.uid,
    this.displayName,
    this.email,
    this.photoURL,
    this.phoneNumber,
    this.department,
    this.studentId,
  });

  // Create from map (for database operations)
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      displayName: map['display_name'],
      email: map['email'],
      photoURL: map['photo_url'],
      phoneNumber: map['phone_number'],
      department: map['department'],
      studentId: map['student_id'],
    );
  }

  // Convert to map (for database operations)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'display_name': displayName,
      'email': email,
      'photo_url': photoURL,
      'phone_number': phoneNumber,
      'department': department,
      'student_id': studentId,
    };
  }

  // Create a copy with updated fields
  UserProfile copyWith({
    String? displayName,
    String? email,
    String? photoURL,
    String? phoneNumber,
    String? department,
    String? studentId,
  }) {
    return UserProfile(
      uid: this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      department: department ?? this.department,
      studentId: studentId ?? this.studentId,
    );
  }
}
