class SubjectModel {
  final int subjectId;
  final String name;
  final String description;

  SubjectModel({
    required this.subjectId,
    required this.name,
    required this.description,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      subjectId: _asInt(json['subjectId'] ?? json['id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}

class AvailabilityModel {
  final int availabilityId;
  final int tutorId;
  final int? subjectId;
  final String dayOfWeek;
  final String mode;
  final String level;
  final DateTime startCourseTime;
  final DateTime endCourseTime;
  final String startTime;
  final String endTime;
  final int slot;
  final int remainingSlot;
  final double pricePerSlot;
  final String status;
  final String? subjectName;
  final double totalCoursePrice;
  final int tutorUserId;
  final String tutorName;
  final bool hasBookings;
  final String? tutorAvatarUrl;

  AvailabilityModel({
    required this.availabilityId,
    required this.tutorId,
    required this.subjectId,
    required this.dayOfWeek,
    required this.mode,
    required this.level,
    required this.startCourseTime,
    required this.endCourseTime,
    required this.startTime,
    required this.endTime,
    required this.slot,
    required this.remainingSlot,
    required this.pricePerSlot,
    required this.status,
    required this.subjectName,
    required this.totalCoursePrice,
    required this.tutorUserId,
    required this.tutorName,
    required this.hasBookings,
    this.tutorAvatarUrl,
  });

  factory AvailabilityModel.fromJson(Map<String, dynamic> json) {
    return AvailabilityModel(
      availabilityId: _asInt(json['availabilityId']),
      tutorId: _asInt(json['tutorId']),
      subjectId: json['subjectId'] == null ? null : _asInt(json['subjectId']),
      dayOfWeek: json['dayOfWeek']?.toString() ?? '',
      mode: json['mode']?.toString() ?? '',
      level: json['level']?.toString() ?? '',
      startCourseTime: _asDate(json['startCourseTime']),
      endCourseTime: _asDate(json['endCourseTime']),
      startTime: _timeString(json['startTime']),
      endTime: _timeString(json['endTime']),
      slot: _asInt(json['slot']),
      remainingSlot: _asInt(json['remainingSlot']),
      pricePerSlot: _asDouble(json['pricePerSlot']),
      status: json['status']?.toString() ?? '',
      subjectName: _subjectName(json),
      totalCoursePrice: _asDouble(
        json['totalCoursePrice'] ??
            (_asDouble(json['pricePerSlot']) * _asInt(json['slot'])),
      ),
      tutorUserId: _asInt(
        json['tutorUserId'] ?? json['tutor']?['userId'] ?? json['tutorId'],
      ),
      tutorName:
          json['tutorName']?.toString() ?? 'Tutor #${_asInt(json['tutorId'])}',
      hasBookings: json['hasBookings'] == true,
      tutorAvatarUrl: _avatarUrl(
        json['tutorAvatarUrl'] ??
            json['avatarUrl'] ??
            json['tutor']?['avatarUrl'] ??
            json['tutor']?['user']?['avatarUrl'] ??
            json['tutor']?['user']?['AvatarUrl'],
      ),
    );
  }
}

class BookingModel {
  final int bookingId;
  final int availabilityId;
  final int userId;
  final int tutorId;
  final int? subjectId;
  final double priceAtBooking;
  final String status;
  final DateTime createdAt;

  BookingModel({
    required this.bookingId,
    required this.availabilityId,
    required this.userId,
    required this.tutorId,
    required this.subjectId,
    required this.priceAtBooking,
    required this.status,
    required this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      bookingId: _asInt(json['bookingId']),
      availabilityId: _asInt(json['availabilityId']),
      userId: _asInt(json['userId']),
      tutorId: _asInt(json['tutorId']),
      subjectId: json['subjectId'] == null ? null : _asInt(json['subjectId']),
      priceAtBooking: _asDouble(json['priceAtBooking']),
      status: json['status']?.toString() ?? '',
      createdAt: _asDate(json['createdAt']),
    );
  }
}

class PaymentModel {
  final int paymentId;
  final int bookingId;
  final double amount;
  final String status;
  final String provider;
  final int orderCode;
  final String description;
  final String? checkoutUrl;
  final String? qrCode;

  PaymentModel({
    required this.paymentId,
    required this.bookingId,
    required this.amount,
    required this.status,
    required this.provider,
    required this.orderCode,
    required this.description,
    required this.checkoutUrl,
    required this.qrCode,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      paymentId: _asInt(json['paymentId']),
      bookingId: _asInt(json['bookingId']),
      amount: _asDouble(json['amount']),
      status: json['status']?.toString() ?? '',
      provider: json['provider']?.toString() ?? '',
      orderCode: _asInt(json['orderCode']),
      description: json['description']?.toString() ?? '',
      checkoutUrl: json['checkoutUrl']?.toString(),
      qrCode: json['qrCode']?.toString(),
    );
  }
}

class LessonModel {
  final int lessonId;
  final int bookingId;
  final DateTime scheduleTime;
  final int duration;
  final String status;
  final String? meetingLink;
  final int availabilityId;
  final int tutorId;
  final int tutorUserId;
  final String tutorName;
  final int? subjectId;
  final String? subjectName;
  final String? tutorAvatarUrl;

  LessonModel({
    required this.lessonId,
    required this.bookingId,
    required this.scheduleTime,
    required this.duration,
    required this.status,
    required this.meetingLink,
    required this.availabilityId,
    required this.tutorId,
    required this.tutorUserId,
    required this.tutorName,
    required this.subjectId,
    required this.subjectName,
    this.tutorAvatarUrl,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      lessonId: _asInt(json['lessonId']),
      bookingId: _asInt(json['bookingId']),
      scheduleTime: _asDate(json['scheduleTime']),
      duration: _asInt(json['duration']),
      status: json['status']?.toString() ?? '',
      meetingLink: json['meetingLink']?.toString(),
      availabilityId: _asInt(json['availabilityId']),
      tutorId: _asInt(json['tutorId']),
      tutorUserId: _asInt(json['tutorUserId']),
      tutorName:
          json['tutorName']?.toString() ?? 'Tutor #${_asInt(json['tutorId'])}',
      subjectId: json['subjectId'] == null ? null : _asInt(json['subjectId']),
      subjectName: json['subjectName']?.toString(),
      tutorAvatarUrl: json['tutorAvatarUrl']?.toString(),
    );
  }
}

class WalletModel {
  final int walletId;
  final int tutorId;
  final double balance;
  final double pendingBalance;

  WalletModel({
    required this.walletId,
    required this.tutorId,
    required this.balance,
    required this.pendingBalance,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      walletId: _asInt(json['walletId']),
      tutorId: _asInt(json['tutorId']),
      balance: _asDouble(json['balance']),
      pendingBalance: _asDouble(json['pendingBalance']),
    );
  }
}

class WalletTransactionModel {
  final int walletTransactionId;
  final int walletId;
  final String type;
  final double amount;
  final String? description;
  final DateTime createdAt;

  WalletTransactionModel({
    required this.walletTransactionId,
    required this.walletId,
    required this.type,
    required this.amount,
    required this.description,
    required this.createdAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      walletTransactionId: _asInt(json['walletTransactionId']),
      walletId: _asInt(json['walletId']),
      type: json['type']?.toString() ?? '',
      amount: _asDouble(json['amount']),
      description: json['description']?.toString(),
      createdAt: _asDate(json['createdAt']),
    );
  }
}

class PayoutModel {
  final int payoutId;
  final int tutorId;
  final double amount;
  final String status;
  final DateTime requestedAt;
  final DateTime? paidAt;

  PayoutModel({
    required this.payoutId,
    required this.tutorId,
    required this.amount,
    required this.status,
    required this.requestedAt,
    required this.paidAt,
  });

  factory PayoutModel.fromJson(Map<String, dynamic> json) {
    return PayoutModel(
      payoutId: _asInt(json['payoutId']),
      tutorId: _asInt(json['tutorId']),
      amount: _asDouble(json['amount']),
      status: json['status']?.toString() ?? '',
      requestedAt: _asDate(json['requestedAt']),
      paidAt: json['paidAt'] == null ? null : _asDate(json['paidAt']),
    );
  }
}

class ConversationModel {
  final int conversationId;
  final DateTime lastMessageAt;
  final bool isActive;
  final List<int> userIds;
  final int otherUserId;
  final String otherUserName;
  final String otherUserRole;
  final String? otherUserAvatarUrl;

  ConversationModel({
    required this.conversationId,
    required this.lastMessageAt,
    required this.isActive,
    required this.userIds,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserRole,
    this.otherUserAvatarUrl,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      conversationId: _asInt(json['conversationId']),
      lastMessageAt: _asDate(json['lastMessageAt']),
      isActive: json['isActive'] == true,
      userIds: (json['userIds'] as List? ?? []).map(_asInt).toList(),
      otherUserId: _asInt(json['otherUserId']),
      otherUserName: json['otherUserName']?.toString() ?? 'User',
      otherUserRole: json['otherUserRole']?.toString() ?? '',
      otherUserAvatarUrl: json['otherUserAvatarUrl']?.toString(),
    );
  }
}

class MessageModel {
  final int messageId;
  final int conversationId;
  final int userId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  MessageModel({
    required this.messageId,
    required this.conversationId,
    required this.userId,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      messageId: _asInt(json['messageId']),
      conversationId: _asInt(json['conversationId']),
      userId: _asInt(json['userId']),
      content: json['content']?.toString() ?? '',
      isRead: json['isRead'] == true,
      createdAt: _asDate(json['createdAt']),
    );
  }
}

class LessonDetailModel {
  final int mainLessonId;
  final int availabilityId;
  final int tutorId;
  final int? subjectId;
  final DateTime scheduleTime;
  final int duration;
  final DateTime endTime;
  final String status;
  final String meetingLink;
  final bool canTakeAttendance;
  final bool canComplete;
  final List<LessonStudentModel> students;

  LessonDetailModel({
    required this.mainLessonId,
    required this.availabilityId,
    required this.tutorId,
    required this.subjectId,
    required this.scheduleTime,
    required this.duration,
    required this.endTime,
    required this.status,
    required this.meetingLink,
    required this.canTakeAttendance,
    required this.canComplete,
    required this.students,
  });

  factory LessonDetailModel.fromJson(Map<String, dynamic> json) {
    return LessonDetailModel(
      mainLessonId: _asInt(json['mainLessonId']),
      availabilityId: _asInt(json['availabilityId']),
      tutorId: _asInt(json['tutorId']),
      subjectId: json['subjectId'] == null ? null : _asInt(json['subjectId']),
      scheduleTime: _asDate(json['scheduleTime']),
      duration: _asInt(json['duration']),
      endTime: _asDate(json['endTime']),
      status: json['status']?.toString() ?? '',
      meetingLink: json['meetingLink']?.toString() ?? '',
      canTakeAttendance: json['canTakeAttendance'] == true,
      canComplete: json['canComplete'] == true,
      students: (json['students'] as List? ?? [])
          .map((e) => LessonStudentModel.fromJson(_asMap(e)))
          .toList(),
    );
  }
}

class LessonStudentModel {
  final int lessonId;
  final int bookingId;
  final int userId;
  final String studentName;
  final String attendanceStatus;
  final String lessonStatus;

  LessonStudentModel({
    required this.lessonId,
    required this.bookingId,
    required this.userId,
    required this.studentName,
    required this.attendanceStatus,
    required this.lessonStatus,
  });

  factory LessonStudentModel.fromJson(Map<String, dynamic> json) {
    return LessonStudentModel(
      lessonId: _asInt(json['lessonId']),
      bookingId: _asInt(json['bookingId']),
      userId: _asInt(json['userId']),
      studentName: json['studentName']?.toString() ?? '',
      attendanceStatus: json['attendanceStatus']?.toString() ?? '',
      lessonStatus: json['lessonStatus']?.toString() ?? '',
    );
  }
}

class AdminDashboardModel {
  final int totalDownloads;
  final int totalInstalls;
  final int totalSubjects;
  final int totalTutors;
  final int pendingTutors;
  final int approvedTutors;
  final int pendingPayouts;
  final double pendingPayoutAmount;
  final int completedLessons;
  final double grossLessonRevenue;
  final double platformRevenue;
  final double tutorRevenue;

  AdminDashboardModel({
    required this.totalDownloads,
    required this.totalInstalls,
    required this.totalSubjects,
    required this.totalTutors,
    required this.pendingTutors,
    required this.approvedTutors,
    required this.pendingPayouts,
    required this.pendingPayoutAmount,
    required this.completedLessons,
    required this.grossLessonRevenue,
    required this.platformRevenue,
    required this.tutorRevenue,
  });

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardModel(
      totalDownloads: _asInt(json['totalDownloads']),
      totalInstalls: _asInt(json['totalInstalls']),
      totalSubjects: _asInt(json['totalSubjects']),
      totalTutors: _asInt(json['totalTutors']),
      pendingTutors: _asInt(json['pendingTutors']),
      approvedTutors: _asInt(json['approvedTutors']),
      pendingPayouts: _asInt(json['pendingPayouts']),
      pendingPayoutAmount: _asDouble(json['pendingPayoutAmount']),
      completedLessons: _asInt(json['completedLessons']),
      grossLessonRevenue: _asDouble(json['grossLessonRevenue']),
      platformRevenue: _asDouble(json['platformRevenue']),
      tutorRevenue: _asDouble(json['tutorRevenue']),
    );
  }
}

class AdminTutorModel {
  final int tutorId;
  final int userId;
  final String tutorName;
  final String email;
  final String? phone;
  final String? bio;
  final bool isVerified;

  AdminTutorModel({
    required this.tutorId,
    required this.userId,
    required this.tutorName,
    required this.email,
    this.phone,
    this.bio,
    required this.isVerified,
  });

  factory AdminTutorModel.fromJson(Map<String, dynamic> json) {
    return AdminTutorModel(
      tutorId: _asInt(json['tutorId']),
      userId: _asInt(json['userId']),
      tutorName: json['tutorName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      bio: json['bio']?.toString(),
      isVerified: json['isVerified'] == true,
    );
  }
}

class TutorVerificationModel {
  final int tutorId;
  final int userId;
  final String tutorName;
  final String email;
  final bool isVerified;
  final String verificationStatus;

  final String? nationalIdNumber;
  final String? cccdFrontImageUrl;
  final String? cccdBackImageUrl;
  final String? certificateImageUrl;

  final String? bankName;
  final String? accountNumber;
  final String? accountHolderName;
  final String? branchName;
  final String? bankBin;

  final String? verificationRejectReason;
  final bool isActive;

  TutorVerificationModel({
    required this.tutorId,
    required this.userId,
    required this.tutorName,
    required this.email,
    required this.isVerified,
    required this.verificationStatus,
    this.nationalIdNumber,
    this.cccdFrontImageUrl,
    this.cccdBackImageUrl,
    this.certificateImageUrl,
    this.bankName,
    this.accountNumber,
    this.accountHolderName,
    this.branchName,
    this.bankBin,
    this.verificationRejectReason,
    required this.isActive,
  });

  factory TutorVerificationModel.fromJson(Map<String, dynamic> json) {
    return TutorVerificationModel(
      tutorId: _asInt(json['tutorId']),
      userId: _asInt(json['userId']),
      tutorName: json['tutorName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      isVerified: json['isVerified'] == true,
      verificationStatus:
          json['verificationStatus']?.toString() ?? 'NotSubmitted',
      nationalIdNumber: json['nationalIdNumber']?.toString(),
      cccdFrontImageUrl: json['cccdFrontImageUrl']?.toString(),
      cccdBackImageUrl: json['cccdBackImageUrl']?.toString(),
      certificateImageUrl: json['certificateImageUrl']?.toString(),
      bankName: json['bankName']?.toString(),
      accountNumber: json['accountNumber']?.toString(),
      accountHolderName: json['accountHolderName']?.toString(),
      branchName: json['branchName']?.toString(),
      verificationRejectReason: json['verificationRejectReason']?.toString(),
      bankBin: json['bankBin']?.toString(),
      isActive: json['isActive'] == true,
    );
  }
}

class AdminPayoutDetailModel {
  final int payoutId;
  final int tutorId;
  final int tutorUserId;
  final String tutorName;
  final String tutorEmail;
  final double amount;
  final String status;
  final DateTime requestedAt;
  final DateTime? paidAt;

  final String? bankName;
  final String? accountNumber;
  final String? accountHolderName;
  final String? branchName;

  final String? bankBin;
  final String transferContent;
  final String? transferQrUrl;
  final String? transferQrNote;

  AdminPayoutDetailModel({
    required this.payoutId,
    required this.tutorId,
    required this.tutorUserId,
    required this.tutorName,
    required this.tutorEmail,
    required this.amount,
    required this.status,
    required this.requestedAt,
    this.paidAt,
    this.bankName,
    this.bankBin,
    this.accountNumber,
    this.accountHolderName,
    this.branchName,
    this.transferContent = '',
    this.transferQrUrl,
    this.transferQrNote,
  });

  factory AdminPayoutDetailModel.fromJson(Map<String, dynamic> json) {
    return AdminPayoutDetailModel(
      payoutId: _asInt(json['payoutId']),
      tutorId: _asInt(json['tutorId']),
      tutorUserId: _asInt(json['tutorUserId']),
      tutorName: json['tutorName']?.toString() ?? '',
      tutorEmail: json['tutorEmail']?.toString() ?? '',
      amount: _asDouble(json['amount']),
      status: json['status']?.toString() ?? '',
      requestedAt: _asDate(json['requestedAt']),
      paidAt: json['paidAt'] == null ? null : _asDate(json['paidAt']),
      bankName: json['bankName']?.toString(),
      accountNumber: json['accountNumber']?.toString(),
      accountHolderName: json['accountHolderName']?.toString(),
      branchName: json['branchName']?.toString(),
      bankBin: json['bankBin']?.toString(),
      transferContent: json['transferContent']?.toString() ?? '',
      transferQrUrl: json['transferQrUrl']?.toString(),
      transferQrNote: json['transferQrNote']?.toString(),
    );
  }
}

class ProfileModel {
  final int userId;
  final String name;
  final String email;
  final String? phone;
  final String role;

  final int? tutorId;
  final String? tutorBio;
  final bool? isVerified;
  final String? verificationStatus;

  final String? bankName;
  final String? bankBin;
  final String? accountNumber;
  final String? accountHolderName;
  final String? branchName;
  final String? avatarUrl;

  ProfileModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.tutorId,
    this.tutorBio,
    this.isVerified,
    this.verificationStatus,
    this.bankName,
    this.bankBin,
    this.accountNumber,
    this.accountHolderName,
    this.branchName,
    this.avatarUrl,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      userId: _asInt(json['userId']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      role: json['role']?.toString() ?? '',
      tutorId: json['tutorId'] == null ? null : _asInt(json['tutorId']),
      tutorBio: json['tutorBio']?.toString(),
      isVerified:
          json['isVerified'] == null ? null : json['isVerified'] == true,
      verificationStatus: json['verificationStatus']?.toString(),
      bankName: json['bankName']?.toString(),
      bankBin: json['bankBin']?.toString(),
      accountNumber: json['accountNumber']?.toString(),
      accountHolderName: json['accountHolderName']?.toString(),
      branchName: json['branchName']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }
}

class TutorReportModel {
  final int tutorReportId;
  final int reporterUserId;
  final String reporterName;
  final int tutorId;
  final int tutorUserId;
  final String tutorName;
  final int bookingId;
  final int availabilityId;
  final int? lessonId;
  final String? subjectName;
  final String category;
  final String title;
  final String description;
  final String status;
  final String? adminNote;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? tutorEmail;
  final String? tutorPhone;
  final bool? tutorIsActive;
  final bool? tutorIsVerified;
  final String? tutorVerificationStatus;
  final List<TutorReportProofImageModel> proofImages;

  TutorReportModel({
    required this.tutorReportId,
    required this.reporterUserId,
    required this.reporterName,
    required this.tutorId,
    required this.tutorUserId,
    required this.tutorName,
    required this.bookingId,
    required this.availabilityId,
    this.lessonId,
    this.subjectName,
    required this.category,
    required this.title,
    required this.description,
    required this.status,
    this.adminNote,
    required this.createdAt,
    this.reviewedAt,
    this.tutorEmail,
    this.tutorPhone,
    this.tutorIsActive,
    this.tutorIsVerified,
    this.tutorVerificationStatus,
    required this.proofImages,
  });

  factory TutorReportModel.fromJson(Map<String, dynamic> json) {
    return TutorReportModel(
      tutorReportId: _asInt(json['tutorReportId']),
      reporterUserId: _asInt(json['reporterUserId']),
      reporterName: json['reporterName']?.toString() ?? '',
      tutorId: _asInt(json['tutorId']),
      tutorUserId: _asInt(json['tutorUserId']),
      tutorName: json['tutorName']?.toString() ?? '',
      bookingId: _asInt(json['bookingId']),
      availabilityId: _asInt(json['availabilityId']),
      lessonId: json['lessonId'] == null ? null : _asInt(json['lessonId']),
      subjectName: json['subjectName']?.toString(),
      category: json['category']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      adminNote: json['adminNote']?.toString(),
      createdAt: _asDate(json['createdAt']),
      reviewedAt:
          json['reviewedAt'] == null ? null : _asDate(json['reviewedAt']),
      tutorEmail: json['tutorEmail']?.toString(),
      tutorPhone: json['tutorPhone']?.toString(),
      tutorIsActive: json['tutorIsActive'] as bool?,
      tutorIsVerified: json['tutorIsVerified'] as bool?,
      tutorVerificationStatus: json['tutorVerificationStatus']?.toString(),
      proofImages: (json['proofImages'] as List? ?? [])
          .map((e) => TutorReportProofImageModel.fromJson(_asMap(e)))
          .toList(),
    );
  }
}

class SupportReportModel {
  final int supportReportId;
  final int userId;
  final String userName;
  final String userEmail;
  final String role;
  final String category;
  final String title;
  final String description;
  final int? payoutId;
  final int? bookingId;
  final int? lessonId;
  final String status;
  final String? adminNote;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final List<SupportReportProofImageModel> proofImages;

  SupportReportModel({
    required this.supportReportId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.role,
    required this.category,
    required this.title,
    required this.description,
    this.payoutId,
    this.bookingId,
    this.lessonId,
    required this.status,
    this.adminNote,
    required this.createdAt,
    this.reviewedAt,
    required this.proofImages,
  });

  factory SupportReportModel.fromJson(Map<String, dynamic> json) {
    return SupportReportModel(
      supportReportId: _supportAsInt(json['supportReportId']),
      userId: _supportAsInt(json['userId']),
      userName: json['userName']?.toString() ?? '',
      userEmail: json['userEmail']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      payoutId: _supportAsNullableInt(json['payoutId']),
      bookingId: _supportAsNullableInt(json['bookingId']),
      lessonId: _supportAsNullableInt(json['lessonId']),
      status: json['status']?.toString() ?? '',
      adminNote: json['adminNote']?.toString(),
      createdAt: _supportAsDate(json['createdAt']),
      reviewedAt: json['reviewedAt'] == null
          ? null
          : _supportAsDate(json['reviewedAt']),
      proofImages: (json['proofImages'] as List? ?? [])
          .map(
            (item) => SupportReportProofImageModel.fromJson(
              _supportAsMap(item),
            ),
          )
          .toList(),
    );
  }
}

class SupportReportProofImageModel {
  final int supportReportProofImageId;
  final String imageUrl;

  SupportReportProofImageModel({
    required this.supportReportProofImageId,
    required this.imageUrl,
  });

  factory SupportReportProofImageModel.fromJson(Map<String, dynamic> json) {
    return SupportReportProofImageModel(
      supportReportProofImageId:
          _supportAsInt(json['supportReportProofImageId']),
      imageUrl: json['imageUrl']?.toString() ?? '',
    );
  }
}

Map<String, dynamic> _supportAsMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

int _supportAsInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _supportAsNullableInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();

  final text = value.toString().trim();
  if (text.isEmpty) return null;

  return int.tryParse(text);
}

DateTime _supportAsDate(Object? value) {
  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}

class TutorReportProofImageModel {
  final int tutorReportProofImageId;
  final String imageUrl;

  TutorReportProofImageModel({
    required this.tutorReportProofImageId,
    required this.imageUrl,
  });

  factory TutorReportProofImageModel.fromJson(Map<String, dynamic> json) {
    return TutorReportProofImageModel(
      tutorReportProofImageId: _asInt(json['tutorReportProofImageId']),
      imageUrl: json['imageUrl']?.toString() ?? '',
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime _asDate(dynamic value) {
  return DateTime.tryParse(value?.toString() ?? '') ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

String _timeString(dynamic value) {
  final raw = value?.toString() ?? '';
  if (raw.length >= 8) return raw.substring(0, 8);
  return raw;
}

String? _subjectName(Map<String, dynamic> json) {
  final direct = json['subjectName'];

  if (direct != null && direct.toString().trim().isNotEmpty) {
    return direct.toString();
  }

  final subject = json['subject'];

  if (subject is Map) {
    final name = subject['name'];

    if (name != null && name.toString().trim().isNotEmpty) {
      return name.toString();
    }
  }

  return null;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value == null) {
    return <String, dynamic>{};
  }

  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return <String, dynamic>{};
}

String? _avatarUrl(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}
