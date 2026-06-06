import 'package:flutter/foundation.dart';

import '../models/mvp_models.dart';
import '../services/api_service.dart';

class AppDataProvider extends ChangeNotifier {
  final ApiService api;

  bool loading = false;
  String? error;

  List<SubjectModel> subjects = [];

  List<AvailabilityModel> availabilities = [];
  List<AvailabilityModel> myAvailabilities = [];
  List<BookingModel> bookings = [];
  List<LessonModel> lessons = [];

  WalletModel? wallet;
  List<WalletTransactionModel> walletTransactions = [];
  List<PayoutModel> payouts = [];

  List<ConversationModel> conversations = [];
  final Map<int, List<MessageModel>> messages = {};
  final Map<int, LessonDetailModel> lessonDetails = {};

  AdminDashboardModel? adminDashboard;
  List<TutorVerificationModel> pendingTutors = [];
  List<PayoutModel> adminPayouts = [];

  TutorVerificationModel? tutorVerification;

  TutorVerificationModel? adminTutorDetail;
  AdminPayoutDetailModel? adminPayoutDetail;

  List<TutorVerificationModel> adminTutors = [];
  List<TutorReportModel> myReports = [];
  List<TutorReportModel> adminReports = [];
  TutorReportModel? adminReportDetail;

  // Add this field near the top with other fields
  final Map<int, String> _userNameCache = {};
  // Add this helper method
  String userName(int userId) => _userNameCache[userId] ?? 'User #$userId';

// Add this to cache a name
  void cacheUserName(int userId, String name) {
    _userNameCache[userId] = name;
    notifyListeners();
  }

  ProfileModel? profile;

  AppDataProvider({required this.api});

  String subjectNameById(
      int? subjectId, {
        String fallback = 'Unknown subject',
      }) {
    if (subjectId == null) {
      return fallback;
    }

    for (final subject in subjects) {
      if (subject.subjectId == subjectId) {
        return subject.name;
      }
    }

    return 'Subject #$subjectId';
  }

  String availabilitySubjectName(AvailabilityModel availability) {
    final directName = availability.subjectName;

    if (directName != null && directName.trim().isNotEmpty) {
      return directName;
    }

    return subjectNameById(availability.subjectId);
  }

  Future<void> loadSubjects() async {
    await _guard(() async {
      subjects = await api.getSubjects();
    });
  }

  Future<void> loadHome() async {
    await _guard(() async {
      subjects = await api.getSubjects();
      availabilities = await api.getAvailabilities();
    });
  }

  Future<BookingModel> book(int availabilityId) async {
    late BookingModel booking;

    await _guard(() async {
      booking = await api.createBooking(availabilityId);
      bookings = await api.getMyBookings();
      availabilities = await api.getAvailabilities();
    });

    return booking;
  }

  Future<void> loadBookings() async {
    await _guard(() async {
      subjects = await api.getSubjects();
      bookings = await api.getMyBookings();
    });
  }

  Future<PaymentModel> createPayment(int bookingId) async {
    late PaymentModel payment;

    await _guard(() async {
      payment = await api.createPayOsPayment(bookingId);
    });

    return payment;
  }

  Future<void> loadLessons() async {
    await _guard(() async {
      lessons = await api.getMyLessons();
    });
  }

  Future<void> markAttendance(int lessonId) async {
    await _guard(() async {
      await api.markAttendance(lessonId);
      lessons = await api.getMyLessons();
    });
  }

  Future<void> completeLesson(int lessonId) async {
    await _guard(() async {
      await api.completeLesson(lessonId);
      lessons = await api.getMyLessons();
    });
  }

  Future<void> loadWallet() async {
    await _guard(() async {
      wallet = await api.getWallet();
      walletTransactions = await api.getWalletTransactions();
      payouts = await api.getMyPayouts();
    });
  }

  Future<void> requestPayout(double amount) async {
    await _guard(() async {
      await api.requestPayout(amount);

      wallet = await api.getWallet();
      walletTransactions = await api.getWalletTransactions();
      payouts = await api.getMyPayouts();
    });
  }



  Future<void> loadConversations() async {
    await _guard(() async {
      conversations = await api.getConversations();

      // Cache own name
      if (profile != null) {
        _userNameCache[profile!.userId] = profile!.name;
      }

      // Fire-and-forget name loading for all participants
      final allUserIds = conversations
          .expand((c) => c.userIds)
          .toSet()
          .where((id) => !_userNameCache.containsKey(id));

      for (final id in allUserIds) {
        loadUserName(id); // no await — resolves in background
      }
    });
  }

  Future<void> loadUserName(int userId) async {
    if (_userNameCache.containsKey(userId)) return;
    try {
      final user = await api.getUserById(userId);
      // adjust the key to match your actual API response field
      final name = (user['fullName'] ?? user['name'] ?? '').toString().trim();
      if (name.isNotEmpty) {
        _userNameCache[userId] = name;
        notifyListeners();
      }
    } catch (_) {
      // silently fail — fallback stays as "User #id"
    }
  }

  Future<ConversationModel> startConversation(int otherUserId) async {
    late ConversationModel conversation;

    await _guard(() async {
      conversation = await api.startConversation(otherUserId);
      conversations = await api.getConversations();

      // Cache own name
      if (profile != null) {
        _userNameCache[profile!.userId] = profile!.name;
      }

      // Load name for the new participant if not cached yet
      if (!_userNameCache.containsKey(otherUserId)) {
        loadUserName(otherUserId); // no await
      }
    });

    return conversation;
  }

  Future<void> loadMessages(int conversationId) async {
    await _guard(() async {
      messages[conversationId] = await api.getMessages(conversationId);
    });
  }

  Future<void> sendMessage(int conversationId, String content) async {
    await _guard(() async {
      await api.sendMessage(conversationId, content);

      messages[conversationId] = await api.getMessages(conversationId);
      conversations = await api.getConversations();
    });
  }

  Future<void> loadMyAvailability() async {
    await _guard(() async {
      subjects = await api.getSubjects();
      myAvailabilities = await api.getMyAvailabilities();
    });
  }

  Future<void> createAvailability({
    required int subjectId,
    required String dayOfWeek,
    required String mode,
    required String level,
    required DateTime startCourseTime,
    required DateTime endCourseTime,
    required String startTime,
    required String endTime,
    required double pricePerSlot,
  }) async {
    await _guard(() async {
      await api.createAvailability(
        subjectId: subjectId,
        dayOfWeek: dayOfWeek,
        mode: mode,
        level: level,
        startCourseTime: startCourseTime,
        endCourseTime: endCourseTime,
        startTime: startTime,
        endTime: endTime,
        pricePerSlot: pricePerSlot,
      );

      subjects = await api.getSubjects();
      myAvailabilities = await api.getMyAvailabilities();
      availabilities = await api.getAvailabilities();
    });
  }

  Future<void> refreshAll() async {
    await _guard(() async {
      subjects = await api.getSubjects();
      availabilities = await api.getAvailabilities();
      bookings = await api.getMyBookings();
      lessons = await api.getMyLessons();
    });
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  Future<void> _guard(Future<void> Function() task) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      await task();
    } catch (e) {
      error = apiErrorMessage(e);
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<PaymentModel> syncPayment(int bookingId) async {
    late PaymentModel payment;

    await _guard(() async {
      payment = await api.syncPayment(bookingId);

      bookings = await api.getMyBookings();
      lessons = await api.getMyLessons();
    });

    return payment;
  }

  Future<void> cancelBooking(int bookingId) async {
    await _guard(() async {
      await api.cancelBooking(bookingId);

      bookings = await api.getMyBookings();
      lessons = await api.getMyLessons();
    });
  }

  Future<void> loadLessonDetail(int lessonId) async {
    await _guard(() async {
      lessonDetails[lessonId] = await api.getLessonDetail(lessonId);
    });
  }

  Future<void> setLessonMeetingLink({
    required int lessonId,
    required String meetingLink,
  }) async {
    await _guard(() async {
      lessonDetails[lessonId] = await api.setMeetingLink(
        lessonId: lessonId,
        meetingLink: meetingLink,
      );
    });
  }

  Future<void> completeLessonGroup(int lessonId) async {
    await _guard(() async {
      final detail = await api.completeLessonGroup(lessonId);

      lessonDetails[lessonId] = detail;
      lessons = await api.getMyLessons();
    });
  }

  Future<void> markStudentAttendance({
    required int mainLessonId,
    required int studentLessonId,
    required String status,
  }) async {
    await _guard(() async {
      await api.markAttendance(
        studentLessonId,
        status: status,
      );

      lessonDetails[mainLessonId] = await api.getLessonDetail(mainLessonId);
      lessons = await api.getMyLessons();
    });
  }

  Future<void> adminLoadDashboard() async {
    await _guard(() async {
      adminDashboard = await api.adminGetDashboard();
      subjects = await api.getSubjects();
      adminTutors = await api.adminGetTutors();
      pendingTutors = adminTutors
          .where((t) => t.verificationStatus.toLowerCase() == 'pending')
          .toList();
      adminPayouts = await api.adminGetPayouts();
      adminReports = await api.adminGetReports();
    });
  }

  Future<void> adminCreateSubject({
    required String name,
    required String description,
  }) async {
    await _guard(() async {
      await api.adminCreateSubject(
        name: name,
        description: description,
      );

      subjects = await api.getSubjects();
      adminDashboard = await api.adminGetDashboard();
    });
  }

  Future<void> adminApproveTutor(int tutorId) async {
    await _guard(() async {
      adminTutorDetail = await api.adminApproveTutor(tutorId);
      adminTutors = await api.adminGetTutors();
      pendingTutors = adminTutors
          .where((t) => t.verificationStatus.toLowerCase() == 'pending')
          .toList();
      adminDashboard = await api.adminGetDashboard();
    });
  }

  Future<void> adminRejectTutor({
    required int tutorId,
    String? reason,
  }) async {
    await _guard(() async {
      adminTutorDetail = await api.adminRejectTutor(
        tutorId: tutorId,
        reason: reason,
      );

      adminTutors = await api.adminGetTutors();
      pendingTutors = adminTutors
          .where((t) => t.verificationStatus.toLowerCase() == 'pending')
          .toList();
      adminDashboard = await api.adminGetDashboard();
    });
  }

  Future<void> adminUpdatePayout({
    required int payoutId,
    required String status,
  }) async {
    await _guard(() async {
      await api.adminUpdatePayout(
        payoutId: payoutId,
        status: status,
      );

      adminPayoutDetail = await api.adminGetPayoutDetail(payoutId);
      adminPayouts = await api.adminGetPayouts();
      adminDashboard = await api.adminGetDashboard();
    });
  }

  Future<void> loadMyTutorVerification() async {
    await _guard(() async {
      tutorVerification = await api.getMyTutorVerification();
    });
  }

  Future<void> submitTutorVerification({
    required String nationalIdNumber,
    required String cccdFrontPath,
    required String cccdBackPath,
    required String certificatePath,
    required String bankName,
    required String accountNumber,
    required String accountHolderName,
    String? branchName,
    String? bankBin,
  }) async {
    await _guard(() async {
      tutorVerification = await api.submitTutorVerification(
        nationalIdNumber: nationalIdNumber,
        cccdFrontPath: cccdFrontPath,
        cccdBackPath: cccdBackPath,
        certificatePath: certificatePath,
        bankName: bankName,
        accountNumber: accountNumber,
        accountHolderName: accountHolderName,
        branchName: branchName,
        bankBin: bankBin,
      );
    });
  }

  Future<void> adminLoadPendingTutors() async {
    await _guard(() async {
      pendingTutors = await api.adminGetPendingTutors();
    });
  }

  Future<void> adminLoadTutorDetail(int tutorId) async {
    await _guard(() async {
      adminTutorDetail = await api.adminGetTutorVerification(tutorId);
    });
  }

  Future<void> adminLoadPayoutDetail(int payoutId) async {
    await _guard(() async {
      adminPayoutDetail = await api.adminGetPayoutDetail(payoutId);
    });
  }

  Future<void> adminLoadTutors() async {
    await _guard(() async {
      adminTutors = await api.adminGetTutors();
    });
  }

  Future<void> toggleAvailabilityStatus({
    required int availabilityId,
    required String status,
  }) async {
    await _guard(() async {
      await api.updateAvailabilityStatus(
        availabilityId: availabilityId,
        status: status,
      );

      myAvailabilities = await api.getMyAvailabilities();
    });
  }

  Future<void> loadProfile() async {
    await _guard(() async {
      profile = await api.getMyProfile();
      // cache own name so "You" fallback works correctly
      if (profile != null) {
        _userNameCache[profile!.userId] = profile!.name;
      }
    });
  }

  Future<void> updateProfile({
    required String name,
    String? phone,
    String? tutorBio,
  }) async {
    await _guard(() async {
      profile = await api.updateMyProfile(
        name: name,
        phone: phone,
        tutorBio: tutorBio,
      );
    });
  }

  Future<void> updateTutorBankAccount({
    required String bankName,
    String? bankBin,
    required String accountNumber,
    required String accountHolderName,
    String? branchName,
  }) async {
    await _guard(() async {
      profile = await api.updateTutorBankAccount(
        bankName: bankName,
        bankBin: bankBin,
        accountNumber: accountNumber,
        accountHolderName: accountHolderName,
        branchName: branchName,
      );
    });
  }

  Future<bool> hasSeenTutorApprovalNotice(int tutorId) async {
    return api.hasSeenTutorApprovalNotice(tutorId);
  }

  Future<void> markTutorApprovalNoticeSeen(int tutorId) async {
    await api.markTutorApprovalNoticeSeen(tutorId);
  }

  Future<void> createTutorReport({
    required int bookingId,
    int? lessonId,
    required String category,
    required String title,
    required String description,
    required List<String> proofImagePaths,
  }) async {
    await _guard(() async {
      await api.createTutorReport(
        bookingId: bookingId,
        lessonId: lessonId,
        category: category,
        title: title,
        description: description,
        proofImagePaths: proofImagePaths,
      );

      myReports = await api.getMyReports();
    });
  }

  Future<void> loadMyReports() async {
    await _guard(() async {
      myReports = await api.getMyReports();
    });
  }

  Future<void> adminLoadReports({String? status}) async {
    await _guard(() async {
      adminReports = await api.adminGetReports(status: status);
    });
  }

  Future<void> adminLoadReportDetail(int reportId) async {
    await _guard(() async {
      adminReportDetail = await api.adminGetReport(reportId);
    });
  }

  Future<void> adminUpdateReportStatus({
    required int reportId,
    required String status,
    String? adminNote,
  }) async {
    await _guard(() async {
      adminReportDetail = await api.adminUpdateReportStatus(
        reportId: reportId,
        status: status,
        adminNote: adminNote,
      );

      adminReports = await api.adminGetReports();
    });
  }

  Future<void> adminUpdateTutorAccountStatus({
    required int tutorId,
    required bool isActive,
  }) async {
    await _guard(() async {
      adminTutorDetail = await api.adminUpdateTutorAccountStatus(
        tutorId: tutorId,
        isActive: isActive,
      );

      adminTutors = await api.adminGetTutors();
      pendingTutors = adminTutors
          .where((t) => t.verificationStatus.toLowerCase() == 'pending')
          .toList();
    });
  }

}