class SubjectModel {
  final int subjectId;
  final String name;
  final String description;
  final String objective;
  final String learningGoals;
  final String expectedResults;
  final String requiredTopics;
  final String commonDifficulties;

  SubjectModel({
    required this.subjectId,
    required this.name,
    required this.description,
    this.objective = '',
    this.learningGoals = '',
    this.expectedResults = '',
    this.requiredTopics = '',
    this.commonDifficulties = '',
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      subjectId: _asInt(json['subjectId'] ?? json['id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      objective: json['objective']?.toString() ?? '',
      learningGoals: json['learningGoals']?.toString() ?? '',
      expectedResults: json['expectedResults']?.toString() ?? '',
      requiredTopics: json['requiredTopics']?.toString() ?? '',
      commonDifficulties: json['commonDifficulties']?.toString() ?? '',
    );
  }
}

class TeachingGuideSectionModel {
  final String title;
  final List<String> items;

  TeachingGuideSectionModel({required this.title, required this.items});

  factory TeachingGuideSectionModel.fromJson(Map<String, dynamic> json) {
    return TeachingGuideSectionModel(
      title: json['title']?.toString() ?? '',
      items: _asStringList(json['items']),
    );
  }
}

class TeachingPreparationGuideModel {
  final int subjectId;
  final String subjectName;
  final String lessonFocus;
  final String objective;
  final List<TeachingGuideSectionModel> sections;

  TeachingPreparationGuideModel({
    required this.subjectId,
    required this.subjectName,
    required this.lessonFocus,
    required this.objective,
    required this.sections,
  });

  factory TeachingPreparationGuideModel.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'] as Iterable? ?? const [];

    return TeachingPreparationGuideModel(
      subjectId: _asInt(json['subjectId']),
      subjectName: json['subjectName']?.toString() ?? '',
      lessonFocus: json['lessonFocus']?.toString() ?? '',
      objective: json['objective']?.toString() ?? '',
      sections: rawSections
          .whereType<Map>()
          .map((item) => TeachingGuideSectionModel.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
    );
  }
}

class AvailabilityModel {
  final int availabilityId;
  final int tutorId;
  final int? subjectId;
  final String dayOfWeek;
  final String mode;
  final String? offlineAreas;
  final String? description;
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
    required this.offlineAreas,
    required this.description,
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
      dayOfWeek: _dayOfWeekText(
        json['daysOfWeek'] ??
            json['DaysOfWeek'] ??
            json['dayOfWeek'] ??
            json['DayOfWeek'],
      ),
      mode: json['mode']?.toString() ?? '',
      offlineAreas: json['offlineAreas']?.toString(),
      description: json['description']?.toString(),
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

class TutorPublicModel {
  final int tutorId;
  final int userId;
  final String name;
  final String email;
  final String phone;
  final String bio;
  final double revenue;
  final double rating;
  final bool isVerified;

  TutorPublicModel({
    required this.tutorId,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.bio,
    required this.revenue,
    required this.rating,
    required this.isVerified,
  });

  factory TutorPublicModel.fromJson(Map<String, dynamic> json) {
    return TutorPublicModel(
      tutorId: _asInt(json['tutorId'] ?? json['TutorId']),
      userId: _asInt(json['userId'] ?? json['UserId']),
      name: json['name']?.toString() ?? json['Name']?.toString() ?? '',
      email: json['email']?.toString() ?? json['Email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? json['Phone']?.toString() ?? '',
      bio: json['bio']?.toString() ?? json['Bio']?.toString() ?? '',
      revenue: _asDouble(json['revenue'] ?? json['Revenue']),
      rating: _asDouble(json['rating'] ?? json['Rating']),
      isVerified: json['isVerified'] == true || json['IsVerified'] == true,
    );
  }
}

class FavoriteTutorModel {
  final int favoriteTutorId;
  final int tutorId;
  final int userId;
  final String name;
  final String email;
  final String phone;
  final String bio;
  final double rating;
  final bool isVerified;
  final String? avatarUrl;

  FavoriteTutorModel({
    required this.favoriteTutorId,
    required this.tutorId,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.bio,
    required this.rating,
    required this.isVerified,
    this.avatarUrl,
  });

  factory FavoriteTutorModel.fromJson(Map<String, dynamic> json) {
    final tutor = _asMap(json['tutor'] ?? json['Tutor']);
    final user = _asMap(tutor['user'] ?? tutor['User']);
    final source = tutor.isEmpty ? json : tutor;

    return FavoriteTutorModel(
      favoriteTutorId: _asInt(
        json['favoriteTutorId'] ??
            json['FavoriteTutorId'] ??
            json['id'] ??
            json['Id'],
      ),
      tutorId: _asInt(
        source['tutorId'] ??
            source['TutorId'] ??
            json['tutorId'] ??
            json['TutorId'],
      ),
      userId: _asInt(
        source['userId'] ??
            source['UserId'] ??
            user['userId'] ??
            user['UserId'],
      ),
      name: source['name']?.toString() ??
          source['Name']?.toString() ??
          user['name']?.toString() ??
          user['Name']?.toString() ??
          json['tutorName']?.toString() ??
          json['TutorName']?.toString() ??
          '',
      email: source['email']?.toString() ??
          source['Email']?.toString() ??
          user['email']?.toString() ??
          user['Email']?.toString() ??
          '',
      phone: source['phone']?.toString() ??
          source['Phone']?.toString() ??
          user['phone']?.toString() ??
          user['Phone']?.toString() ??
          '',
      bio: source['bio']?.toString() ??
          source['Bio']?.toString() ??
          json['bio']?.toString() ??
          json['Bio']?.toString() ??
          '',
      rating: _asDouble(source['rating'] ?? source['Rating'] ?? json['rating']),
      isVerified: source['isVerified'] == true ||
          source['IsVerified'] == true ||
          json['isVerified'] == true ||
          json['IsVerified'] == true,
      avatarUrl: _avatarUrl(
        source['avatarUrl'] ??
            source['AvatarUrl'] ??
            user['avatarUrl'] ??
            user['AvatarUrl'] ??
            json['tutorAvatarUrl'] ??
            json['avatarUrl'],
      ),
    );
  }
}

class TutorReviewModel {
  final int reviewId;
  final int bookingId;
  final int tutorId;
  final int userId;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String reviewerName;

  TutorReviewModel({
    required this.reviewId,
    required this.bookingId,
    required this.tutorId,
    required this.userId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.reviewerName,
  });

  factory TutorReviewModel.fromJson(Map<String, dynamic> json) {
    return TutorReviewModel(
      reviewId: _asInt(json['reviewId'] ?? json['ReviewId'] ?? json['id']),
      bookingId: _asInt(json['bookingId'] ?? json['BookingId']),
      tutorId: _asInt(json['tutorId'] ?? json['TutorId']),
      userId: _asInt(json['userId'] ?? json['UserId']),
      rating: _asInt(json['rating'] ?? json['Rating']),
      comment: json['comment']?.toString() ??
          json['Comment']?.toString() ??
          json['content']?.toString() ??
          '',
      createdAt: _asDate(json['createdAt'] ?? json['CreatedAt']),
      reviewerName: json['reviewerName']?.toString() ??
          json['ReviewerName']?.toString() ??
          json['userName']?.toString() ??
          json['UserName']?.toString() ??
          '',
    );
  }
}

class BookingModel {
  final int bookingId;
  final int availabilityId;
  final int userId;
  final int tutorId;
  final String? tutorName;
  final int? subjectId;
  final String? availabilityDayOfWeek;
  final DateTime? availabilityStartCourseTime;
  final DateTime? availabilityEndCourseTime;
  final String? availabilityStartTime;
  final String? availabilityEndTime;
  final double priceAtBooking;
  final String status;
  final DateTime createdAt;

  BookingModel({
    required this.bookingId,
    required this.availabilityId,
    required this.userId,
    required this.tutorId,
    this.tutorName,
    required this.subjectId,
    this.availabilityDayOfWeek,
    this.availabilityStartCourseTime,
    this.availabilityEndCourseTime,
    this.availabilityStartTime,
    this.availabilityEndTime,
    required this.priceAtBooking,
    required this.status,
    required this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final tutorId = _asInt(json['tutorId'] ?? json['TutorId']);
    final tutorName = _bookingTutorName(json, tutorId);

    return BookingModel(
      bookingId: _asInt(json['bookingId'] ?? json['BookingId']),
      availabilityId: _asInt(json['availabilityId'] ?? json['AvailabilityId']),
      userId: _asInt(json['userId'] ?? json['UserId']),
      tutorId: tutorId,
      tutorName: tutorName,
      subjectId: _bookingSubjectId(json),
      availabilityDayOfWeek: _blankToNull(
        json['dayOfWeek'] ?? json['DayOfWeek'],
      ),
      availabilityStartCourseTime: _asNullableDate(
        json['startCourseTime'] ?? json['StartCourseTime'],
      ),
      availabilityEndCourseTime: _asNullableDate(
        json['endCourseTime'] ?? json['EndCourseTime'],
      ),
      availabilityStartTime: _blankToNull(
        json['startTime'] ?? json['StartTime'],
      ),
      availabilityEndTime: _blankToNull(json['endTime'] ?? json['EndTime']),
      priceAtBooking: _asDouble(
        json['priceAtBooking'] ?? json['PriceAtBooking'],
      ),
      status: (json['status'] ?? json['Status'])?.toString() ?? '',
      createdAt: _asDate(json['createdAt'] ?? json['CreatedAt']),
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
  final int availabilitySlot;
  final int tutorId;
  final int tutorUserId;
  final String tutorName;
  final int? subjectId;
  final String? subjectName;
  final String? tutorAvatarUrl;
  final String? studentName;

  LessonModel({
    required this.lessonId,
    required this.bookingId,
    required this.scheduleTime,
    required this.duration,
    required this.status,
    required this.meetingLink,
    required this.availabilityId,
    required this.availabilitySlot,
    required this.tutorId,
    required this.tutorUserId,
    required this.tutorName,
    required this.subjectId,
    required this.subjectName,
    this.tutorAvatarUrl,
    this.studentName,
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
      availabilitySlot: _asInt(
        json['availabilitySlot'] ??
            json['AvailabilitySlot'] ??
            json['slot'] ??
            json['Slot'] ??
            json['availability']?['slot'] ??
            json['Availability']?['Slot'],
      ),
      tutorId: _asInt(json['tutorId']),
      tutorUserId: _asInt(json['tutorUserId']),
      tutorName:
          json['tutorName']?.toString() ?? 'Tutor #${_asInt(json['tutorId'])}',
      subjectId: json['subjectId'] == null ? null : _asInt(json['subjectId']),
      subjectName: json['subjectName']?.toString(),
      tutorAvatarUrl: json['tutorAvatarUrl']?.toString(),
      studentName:
          json['studentName']?.toString() ?? json['StudentName']?.toString(),
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

  final String payoutMethod;

  final DateTime requestedAt;
  final DateTime? approvedAt;
  final DateTime? paidAt;

  final String? payOSChiReferenceId;
  final String? payOSChiBatchId;
  final String? payOSChiPayoutItemId;
  final String? payOSChiApprovalState;
  final String? payOSChiTransactionState;
  final String? payOSChiFailureReason;

  final String? tutorBankName;
  final String? tutorBankBin;
  final String? tutorAccountNumber;
  final String? tutorAccountHolderName;
  final String? tutorBankBranch;

  PayoutModel({
    required this.payoutId,
    required this.tutorId,
    required this.amount,
    required this.status,
    required this.payoutMethod,
    required this.requestedAt,
    required this.approvedAt,
    required this.paidAt,
    required this.payOSChiReferenceId,
    required this.payOSChiBatchId,
    required this.payOSChiPayoutItemId,
    required this.payOSChiApprovalState,
    required this.payOSChiTransactionState,
    required this.payOSChiFailureReason,
    required this.tutorBankName,
    required this.tutorBankBin,
    required this.tutorAccountNumber,
    required this.tutorAccountHolderName,
    required this.tutorBankBranch,
  });

  factory PayoutModel.fromJson(Map<String, dynamic> json) {
    return PayoutModel(
      payoutId: _asInt(json['payoutId'] ?? json['PayoutId']),
      tutorId: _asInt(json['tutorId'] ?? json['TutorId']),
      amount: _asDouble(json['amount'] ?? json['Amount']),
      status: json['status']?.toString() ?? json['Status']?.toString() ?? '',
      payoutMethod: json['payoutMethod']?.toString() ??
          json['PayoutMethod']?.toString() ??
          'ManualQr',
      requestedAt: _asDate(json['requestedAt'] ?? json['RequestedAt']),
      approvedAt: _asDateNullable(json['approvedAt'] ?? json['ApprovedAt']),
      paidAt: _asDateNullable(json['paidAt'] ?? json['PaidAt']),
      payOSChiReferenceId: json['payOSChiReferenceId']?.toString() ??
          json['PayOSChiReferenceId']?.toString(),
      payOSChiBatchId: json['payOSChiBatchId']?.toString() ??
          json['PayOSChiBatchId']?.toString(),
      payOSChiPayoutItemId: json['payOSChiPayoutItemId']?.toString() ??
          json['PayOSChiPayoutItemId']?.toString(),
      payOSChiApprovalState: json['payOSChiApprovalState']?.toString() ??
          json['PayOSChiApprovalState']?.toString(),
      payOSChiTransactionState: json['payOSChiTransactionState']?.toString() ??
          json['PayOSChiTransactionState']?.toString(),
      payOSChiFailureReason: json['payOSChiFailureReason']?.toString() ??
          json['PayOSChiFailureReason']?.toString(),
      tutorBankName: json['tutorBankName']?.toString() ??
          json['TutorBankName']?.toString(),
      tutorBankBin:
          json['tutorBankBin']?.toString() ?? json['TutorBankBin']?.toString(),
      tutorAccountNumber: json['tutorAccountNumber']?.toString() ??
          json['TutorAccountNumber']?.toString(),
      tutorAccountHolderName: json['tutorAccountHolderName']?.toString() ??
          json['TutorAccountHolderName']?.toString(),
      tutorBankBranch: json['tutorBankBranch']?.toString() ??
          json['TutorBankBranch']?.toString(),
    );
  }
}

DateTime? _asDateNullable(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  if (text.trim().isEmpty) return null;
  return DateTime.tryParse(text);
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

class HomeworkModel {
  final int homeworkId;
  final int bookingId;
  final int? lessonId;
  final String type;
  final String title;
  final String? description;
  final DateTime dueDate;
  final DateTime uploadedAt;
  final double totalPoints;
  final List<HomeworkQuestionModel> questions;
  final List<HomeworkEssayModel> essays;
  final HomeworkSubmissionModel? mySubmission;
  final List<HomeworkSubmissionModel> submissions;

  HomeworkModel({
    required this.homeworkId,
    required this.bookingId,
    required this.lessonId,
    required this.type,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.uploadedAt,
    required this.totalPoints,
    required this.questions,
    required this.essays,
    required this.mySubmission,
    required this.submissions,
  });

  bool get isMultipleChoice => type.toLowerCase() == 'multiplechoice';
  bool get isEssay => type.toLowerCase() == 'essay';

  HomeworkModel copyWith({
    HomeworkSubmissionModel? mySubmission,
    List<HomeworkSubmissionModel>? submissions,
  }) {
    return HomeworkModel(
      homeworkId: homeworkId,
      bookingId: bookingId,
      lessonId: lessonId,
      type: type,
      title: title,
      description: description,
      dueDate: dueDate,
      uploadedAt: uploadedAt,
      totalPoints: totalPoints,
      questions: questions,
      essays: essays,
      mySubmission: mySubmission ?? this.mySubmission,
      submissions: submissions ?? this.submissions,
    );
  }

  factory HomeworkModel.fromJson(Map<String, dynamic> json) {
    return HomeworkModel(
      homeworkId: _asInt(json['homeworkId']),
      bookingId: _asInt(json['bookingId']),
      lessonId: json['lessonId'] == null ? null : _asInt(json['lessonId']),
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      dueDate: _asDate(json['dueDate']),
      uploadedAt: _asDate(json['uploadedAt']),
      totalPoints: _asDouble(json['totalPoints']),
      questions: (json['questions'] as List? ?? [])
          .map((e) => HomeworkQuestionModel.fromJson(_asMap(e)))
          .toList(),
      essays: (json['essays'] as List? ?? [])
          .map((e) => HomeworkEssayModel.fromJson(_asMap(e)))
          .toList(),
      mySubmission: json['mySubmission'] == null
          ? null
          : HomeworkSubmissionModel.fromJson(_asMap(json['mySubmission'])),
      submissions: (json['submissions'] as List? ?? [])
          .map((e) => HomeworkSubmissionModel.fromJson(_asMap(e)))
          .toList(),
    );
  }
}

class HomeworkQuestionModel {
  final int multipleChoiceQuestionId;
  final String questionText;
  final double point;
  final List<HomeworkOptionModel> options;

  HomeworkQuestionModel({
    required this.multipleChoiceQuestionId,
    required this.questionText,
    required this.point,
    required this.options,
  });

  factory HomeworkQuestionModel.fromJson(Map<String, dynamic> json) {
    return HomeworkQuestionModel(
      multipleChoiceQuestionId: _asInt(json['multipleChoiceQuestionId']),
      questionText: json['questionText']?.toString() ?? '',
      point: _asDouble(json['point']),
      options: (json['options'] as List? ?? [])
          .map((e) => HomeworkOptionModel.fromJson(_asMap(e)))
          .toList(),
    );
  }
}

class HomeworkOptionModel {
  final int questionOptionId;
  final String content;
  final bool? isCorrect;

  HomeworkOptionModel({
    required this.questionOptionId,
    required this.content,
    required this.isCorrect,
  });

  factory HomeworkOptionModel.fromJson(Map<String, dynamic> json) {
    return HomeworkOptionModel(
      questionOptionId: _asInt(json['questionOptionId']),
      content: json['content']?.toString() ?? '',
      isCorrect: json['isCorrect'] as bool?,
    );
  }
}

class HomeworkEssayModel {
  final int essayId;
  final String questionText;
  final double points;

  HomeworkEssayModel({
    required this.essayId,
    required this.questionText,
    required this.points,
  });

  factory HomeworkEssayModel.fromJson(Map<String, dynamic> json) {
    return HomeworkEssayModel(
      essayId: _asInt(json['essayId']),
      questionText: json['questionText']?.toString() ?? '',
      points: _asDouble(json['points']),
    );
  }
}

class HomeworkSubmissionModel {
  final int submissionId;
  final int homeworkId;
  final int studentId;
  final String studentName;
  final DateTime submittedAt;
  final DateTime? gradedAt;
  final double totalScore;
  final double maxScore;
  final bool isGraded;
  final String? feedback;
  final List<MultipleChoiceAnswerModel> multipleChoiceAnswers;
  final List<EssayAnswerModel> essayAnswers;

  HomeworkSubmissionModel({
    required this.submissionId,
    required this.homeworkId,
    required this.studentId,
    required this.studentName,
    required this.submittedAt,
    required this.gradedAt,
    required this.totalScore,
    required this.maxScore,
    required this.isGraded,
    required this.feedback,
    required this.multipleChoiceAnswers,
    required this.essayAnswers,
  });

  factory HomeworkSubmissionModel.fromJson(Map<String, dynamic> json) {
    return HomeworkSubmissionModel(
      submissionId: _asInt(json['submissionId']),
      homeworkId: _asInt(json['homeworkId']),
      studentId: _asInt(json['studentId']),
      studentName: json['studentName']?.toString() ?? '',
      submittedAt: _asDate(json['submittedAt']),
      gradedAt: _asDateNullable(json['gradedAt']),
      totalScore: _asDouble(json['totalScore']),
      maxScore: _asDouble(json['maxScore']),
      isGraded: json['isGraded'] == true,
      feedback: json['feedback']?.toString(),
      multipleChoiceAnswers: (json['multipleChoiceAnswers'] as List? ?? [])
          .map((e) => MultipleChoiceAnswerModel.fromJson(_asMap(e)))
          .toList(),
      essayAnswers: (json['essayAnswers'] as List? ?? [])
          .map((e) => EssayAnswerModel.fromJson(_asMap(e)))
          .toList(),
    );
  }
}

class MultipleChoiceAnswerModel {
  final int multipleChoiceQuestionAnswerId;
  final int multipleChoiceQuestionId;
  final int questionOptionId;
  final String selectedOption;
  final bool isCorrect;
  final double score;

  MultipleChoiceAnswerModel({
    required this.multipleChoiceQuestionAnswerId,
    required this.multipleChoiceQuestionId,
    required this.questionOptionId,
    required this.selectedOption,
    required this.isCorrect,
    required this.score,
  });

  factory MultipleChoiceAnswerModel.fromJson(Map<String, dynamic> json) {
    return MultipleChoiceAnswerModel(
      multipleChoiceQuestionAnswerId:
          _asInt(json['multipleChoiceQuestionAnswerId']),
      multipleChoiceQuestionId: _asInt(json['multipleChoiceQuestionId']),
      questionOptionId: _asInt(json['questionOptionId']),
      selectedOption: json['selectedOption']?.toString() ?? '',
      isCorrect: json['isCorrect'] == true,
      score: _asDouble(json['score']),
    );
  }
}

class EssayAnswerModel {
  final int essayAnswerId;
  final int essayId;
  final String answerText;
  final double score;
  final String? feedback;

  EssayAnswerModel({
    required this.essayAnswerId,
    required this.essayId,
    required this.answerText,
    required this.score,
    required this.feedback,
  });

  factory EssayAnswerModel.fromJson(Map<String, dynamic> json) {
    return EssayAnswerModel(
      essayAnswerId: _asInt(json['essayAnswerId']),
      essayId: _asInt(json['essayId']),
      answerText: json['answerText']?.toString() ?? '',
      score: _asDouble(json['score']),
      feedback: json['feedback']?.toString(),
    );
  }
}

class CourseMaterialSectionModel {
  final int sectionId;
  final int availabilityId;
  final String title;
  final String? description;
  final int displayOrder;
  final DateTime createdAt;
  final List<CourseMaterialItemModel> items;

  CourseMaterialSectionModel({
    required this.sectionId,
    required this.availabilityId,
    required this.title,
    required this.description,
    required this.displayOrder,
    required this.createdAt,
    required this.items,
  });

  factory CourseMaterialSectionModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['materials'] ?? json['Materials'];

    return CourseMaterialSectionModel(
      sectionId: _asInt(
        json['sectionId'] ??
            json['materialSectionId'] ??
            json['courseMaterialSectionId'] ??
            json['id'],
      ),
      availabilityId: _asInt(json['availabilityId']),
      title: json['title']?.toString() ??
          json['sectionTitle']?.toString() ??
          'Materials',
      description: _blankToNull(
        json['description'] ?? json['sectionDescription'],
      ),
      displayOrder: _asInt(json['displayOrder'] ?? json['order']),
      createdAt: _asDate(json['createdAt']),
      items: _asObjectList(rawItems)
          .map((item) => CourseMaterialItemModel.fromJson(item))
          .toList(),
    );
  }

  factory CourseMaterialSectionModel.flat({
    required int availabilityId,
    required List<CourseMaterialItemModel> items,
  }) {
    return CourseMaterialSectionModel(
      sectionId: 0,
      availabilityId: availabilityId,
      title: 'Materials',
      description: null,
      displayOrder: 0,
      createdAt: items.isEmpty ? DateTime.now() : items.first.createdAt,
      items: items,
    );
  }
}

class CourseMaterialItemModel {
  final int materialId;
  final int? sectionId;
  final int availabilityId;
  final String title;
  final String? description;
  final String? fileUrl;
  final String? fileName;
  final String? contentType;
  final int? fileSize;
  final String materialType;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CourseMaterialItemModel({
    required this.materialId,
    required this.sectionId,
    required this.availabilityId,
    required this.title,
    required this.description,
    required this.fileUrl,
    required this.fileName,
    required this.contentType,
    required this.fileSize,
    required this.materialType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CourseMaterialItemModel.fromJson(Map<String, dynamic> json) {
    final url = _blankToNull(
      json['fileUrl'] ??
          json['FileUrl'] ??
          json['url'] ??
          json['Url'] ??
          json['downloadUrl'] ??
          json['DownloadUrl'] ??
          json['externalUrl'] ??
          json['ExternalUrl'] ??
          json['linkUrl'],
    );

    return CourseMaterialItemModel(
      materialId: _asInt(
        json['materialId'] ??
            json['MaterialId'] ??
            json['courseMaterialId'] ??
            json['CourseMaterialId'] ??
            json['id'] ??
            json['Id'],
      ),
      sectionId: _asNullableInt(
        json['sectionId'] ??
            json['SectionId'] ??
            json['materialSectionId'] ??
            json['MaterialSectionId'] ??
            json['courseMaterialSectionId'],
      ),
      availabilityId: _asInt(json['availabilityId'] ?? json['AvailabilityId']),
      title: json['title']?.toString() ??
          json['Title']?.toString() ??
          'Untitled material',
      description: _blankToNull(json['description'] ?? json['Description']),
      fileUrl: url,
      fileName: _blankToNull(
        json['fileName'] ?? json['FileName'] ?? json['originalFileName'],
      ),
      contentType: _blankToNull(
        json['contentType'] ?? json['ContentType'] ?? json['mimeType'],
      ),
      fileSize: _asNullableInt(
        json['fileSize'] ?? json['FileSize'] ?? json['sizeInBytes'],
      ),
      materialType: json['materialType']?.toString() ??
          json['MaterialType']?.toString() ??
          json['type']?.toString() ??
          _inferMaterialType(url),
      createdAt:
          _asDate(json['createdAt'] ?? json['CreatedAt'] ?? json['uploadedAt']),
      updatedAt: (json['updatedAt'] ?? json['UpdatedAt']) == null
          ? null
          : _asDate(json['updatedAt'] ?? json['UpdatedAt']),
    );
  }

  bool get canOpen => fileUrl != null && fileUrl!.trim().isNotEmpty;
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
  final List<String> certificateImageUrls;
  final String? transcriptDocumentUrl;

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
    this.certificateImageUrls = const [],
    this.transcriptDocumentUrl,
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
      certificateImageUrls: _asStringList(json['certificateImageUrls']),
      transcriptDocumentUrl: json['transcriptDocumentUrl']?.toString(),
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

List<String> _asStringList(dynamic value) {
  if (value is Iterable) {
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }

  final text = value?.toString().trim() ?? '';

  return text.isEmpty ? const [] : [text];
}

class AdminPayoutDetailModel {
  final int payoutId;
  final int tutorId;
  final int tutorUserId;

  final String tutorName;
  final String tutorEmail;

  final double amount;
  final String status;
  final String payoutMethod;

  final DateTime requestedAt;
  final DateTime? approvedAt;
  final DateTime? paidAt;

  final String? bankName;
  final String? bankBin;
  final String? accountNumber;
  final String? accountHolderName;
  final String? branchName;

  final String transferContent;
  final String? transferQrUrl;
  final String? transferQrNote;

  final String? payOSChiReferenceId;
  final String? payOSChiBatchId;
  final String? payOSChiPayoutItemId;
  final String? payOSChiApprovalState;
  final String? payOSChiTransactionState;
  final String? payOSChiFailureReason;

  AdminPayoutDetailModel({
    required this.payoutId,
    required this.tutorId,
    required this.tutorUserId,
    required this.tutorName,
    required this.tutorEmail,
    required this.amount,
    required this.status,
    required this.payoutMethod,
    required this.requestedAt,
    required this.approvedAt,
    required this.paidAt,
    required this.bankName,
    required this.bankBin,
    required this.accountNumber,
    required this.accountHolderName,
    required this.branchName,
    required this.transferContent,
    required this.transferQrUrl,
    required this.transferQrNote,
    required this.payOSChiReferenceId,
    required this.payOSChiBatchId,
    required this.payOSChiPayoutItemId,
    required this.payOSChiApprovalState,
    required this.payOSChiTransactionState,
    required this.payOSChiFailureReason,
  });

  factory AdminPayoutDetailModel.fromJson(Map<String, dynamic> json) {
    return AdminPayoutDetailModel(
      payoutId: _asInt(json['payoutId'] ?? json['PayoutId']),
      tutorId: _asInt(json['tutorId'] ?? json['TutorId']),
      tutorUserId: _asInt(json['tutorUserId'] ?? json['TutorUserId']),
      tutorName:
          json['tutorName']?.toString() ?? json['TutorName']?.toString() ?? '',
      tutorEmail: json['tutorEmail']?.toString() ??
          json['TutorEmail']?.toString() ??
          '',
      amount: _asDouble(json['amount'] ?? json['Amount']),
      status: json['status']?.toString() ?? json['Status']?.toString() ?? '',
      payoutMethod: json['payoutMethod']?.toString() ??
          json['PayoutMethod']?.toString() ??
          'ManualQr',
      requestedAt: _asDate(json['requestedAt'] ?? json['RequestedAt']),
      approvedAt: _asDateNullable(json['approvedAt'] ?? json['ApprovedAt']),
      paidAt: _asDateNullable(json['paidAt'] ?? json['PaidAt']),
      bankName: json['bankName']?.toString() ?? json['BankName']?.toString(),
      bankBin: json['bankBin']?.toString() ?? json['BankBin']?.toString(),
      accountNumber: json['accountNumber']?.toString() ??
          json['AccountNumber']?.toString(),
      accountHolderName: json['accountHolderName']?.toString() ??
          json['AccountHolderName']?.toString(),
      branchName:
          json['branchName']?.toString() ?? json['BranchName']?.toString(),
      transferContent: json['transferContent']?.toString() ??
          json['TransferContent']?.toString() ??
          '',
      transferQrUrl: json['transferQrUrl']?.toString() ??
          json['TransferQrUrl']?.toString(),
      transferQrNote: json['transferQrNote']?.toString() ??
          json['TransferQrNote']?.toString(),
      payOSChiReferenceId: json['payOSChiReferenceId']?.toString() ??
          json['PayOSChiReferenceId']?.toString(),
      payOSChiBatchId: json['payOSChiBatchId']?.toString() ??
          json['PayOSChiBatchId']?.toString(),
      payOSChiPayoutItemId: json['payOSChiPayoutItemId']?.toString() ??
          json['PayOSChiPayoutItemId']?.toString(),
      payOSChiApprovalState: json['payOSChiApprovalState']?.toString() ??
          json['PayOSChiApprovalState']?.toString(),
      payOSChiTransactionState: json['payOSChiTransactionState']?.toString() ??
          json['PayOSChiTransactionState']?.toString(),
      payOSChiFailureReason: json['payOSChiFailureReason']?.toString() ??
          json['PayOSChiFailureReason']?.toString(),
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

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();

  final text = value.toString().trim();
  if (text.isEmpty) return null;

  return int.tryParse(text);
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

DateTime? _asNullableDate(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : DateTime.tryParse(text);
}

String _timeString(dynamic value) {
  final raw = value?.toString() ?? '';
  if (raw.length >= 8) return raw.substring(0, 8);
  return raw;
}

String _dayOfWeekText(dynamic value) {
  if (value is List) {
    return value
        .map((day) => day.toString().trim())
        .where((day) => day.isNotEmpty)
        .join(', ');
  }

  return value
          ?.toString()
          .split(',')
          .map((day) => day.trim())
          .where((day) => day.isNotEmpty)
          .join(', ') ??
      '';
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

int? _bookingSubjectId(Map<String, dynamic> json) {
  final direct = json['subjectId'] ?? json['SubjectId'];

  if (direct != null) {
    return _asInt(direct);
  }

  final availability = _asMap(json['availability'] ?? json['Availability']);
  final nested = availability['subjectId'] ?? availability['SubjectId'];

  return nested == null ? null : _asInt(nested);
}

String _bookingTutorName(Map<String, dynamic> json, int tutorId) {
  final candidates = [
    json['tutorName'],
    json['TutorName'],
    _asMap(json['tutor'] ?? json['Tutor'])['tutorName'],
    _asMap(json['tutor'] ?? json['Tutor'])['TutorName'],
    _asMap(json['tutor'] ?? json['Tutor'])['name'],
    _asMap(json['tutor'] ?? json['Tutor'])['Name'],
    _asMap(_asMap(json['tutor'] ?? json['Tutor'])['user'])['name'],
    _asMap(_asMap(json['tutor'] ?? json['Tutor'])['User'])['Name'],
    _asMap(_asMap(json['availability'] ?? json['Availability'])['tutor'])[
            'user'] is Map
        ? _asMap(_asMap(
                _asMap(json['availability'] ?? json['Availability'])['tutor'])[
            'user'])['name']
        : null,
    _asMap(_asMap(json['Availability'])['Tutor'])['User'] is Map
        ? _asMap(_asMap(_asMap(json['Availability'])['Tutor'])['User'])['Name']
        : null,
  ];

  for (final candidate in candidates) {
    final value = candidate?.toString().trim() ?? '';

    if (value.isNotEmpty) {
      return value;
    }
  }

  return 'Tutor #$tutorId';
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

List<Map<String, dynamic>> _asObjectList(dynamic value) {
  if (value is List) {
    return value.map((item) => _asMap(item)).toList();
  }

  if (value is Map) {
    final map = _asMap(value);
    final items = map['data'] ?? map['items'] ?? map['materials'];

    if (items is List) {
      return items.map((item) => _asMap(item)).toList();
    }
  }

  return <Map<String, dynamic>>[];
}

String? _blankToNull(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

String _inferMaterialType(String? url) {
  final text = url?.toLowerCase() ?? '';

  if (text.endsWith('.pdf')) return 'Pdf';
  if (text.endsWith('.png') ||
      text.endsWith('.jpg') ||
      text.endsWith('.jpeg') ||
      text.endsWith('.webp')) {
    return 'Image';
  }
  if (text.endsWith('.mp4') || text.endsWith('.mov') || text.endsWith('.avi')) {
    return 'Video';
  }
  if (text.startsWith('http')) return 'Link';

  return 'File';
}

String? _avatarUrl(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}
