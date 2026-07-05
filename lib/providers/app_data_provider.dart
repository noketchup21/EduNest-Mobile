import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

import 'package:image_picker/image_picker.dart';

import '../models/mvp_models.dart';
import '../services/api_service.dart';

class AppDataProvider extends ChangeNotifier {
  static const restrictedChatWarning =
      'For your safety, keep communication and payment inside EduNest.';

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
  final Map<int, List<HomeworkModel>> lessonHomeworks = {};
  final Map<int, DateTime> _lessonHomeworksLoadedAt = {};
  static const Duration _homeworkCacheDuration = Duration(seconds: 45);
  DateTime? _homeworkDashboardLoadedAt;
  Future<void>? _homeworkDashboardLoad;
  final Map<int, Future<void>> _homeworkCourseLoads = {};
  final Map<int, List<CourseMaterialSectionModel>> courseMaterials = {};
  final Map<int, DateTime> _courseMaterialsLoadedAt = {};
  final Map<int, Future<void>> _courseMaterialLoads = {};
  static const Duration _courseMaterialsCacheDuration = Duration(seconds: 45);

  AdminDashboardModel? adminDashboard;
  List<TutorVerificationModel> pendingTutors = [];
  List<PayoutModel> adminPayouts = [];

  TutorVerificationModel? tutorVerification;
  TeachingPreparationGuideModel? teachingPreparationGuide;
  TutorPublicModel? selectedTutor;
  List<AvailabilityModel> selectedTutorAvailabilities = [];
  List<FavoriteTutorModel> favoriteTutors = [];
  final Map<int, List<TutorReviewModel>> tutorReviews = {};
  List<TutorReviewModel> myTutorReviews = [];

  TutorVerificationModel? adminTutorDetail;
  AdminPayoutDetailModel? adminPayoutDetail;

  List<TutorVerificationModel> adminTutors = [];
  List<TutorReportModel> myReports = [];
  List<TutorReportModel> adminReports = [];
  TutorReportModel? adminReportDetail;
  List<TutorReportModel> tutorReports = [];

  List<SupportReportModel> supportReports = [];
  List<SupportReportModel> adminSupportReports = [];
  SupportReportModel? adminSupportReportDetail;

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

  void clearSessionData() {
    loading = false;
    error = null;

    availabilities = [];
    myAvailabilities = [];
    bookings = [];
    lessons = [];

    wallet = null;
    walletTransactions = [];
    payouts = [];

    conversations = [];
    messages.clear();
    lessonDetails.clear();
    lessonHomeworks.clear();
    _lessonHomeworksLoadedAt.clear();
    _homeworkDashboardLoadedAt = null;
    _homeworkDashboardLoad = null;
    _homeworkCourseLoads.clear();
    courseMaterials.clear();
    _courseMaterialsLoadedAt.clear();
    _courseMaterialLoads.clear();

    adminDashboard = null;
    pendingTutors = [];
    adminPayouts = [];

    tutorVerification = null;
    teachingPreparationGuide = null;
    selectedTutor = null;
    selectedTutorAvailabilities = [];
    favoriteTutors = [];
    tutorReviews.clear();
    myTutorReviews = [];

    adminTutorDetail = null;
    adminPayoutDetail = null;
    adminTutors = [];
    myReports = [];
    adminReports = [];
    adminReportDetail = null;
    tutorReports = [];

    supportReports = [];
    adminSupportReports = [];
    adminSupportReportDetail = null;

    _userNameCache.clear();
    profile = null;

    notifyListeners();
  }

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

  Future<void> generateTeachingPreparationGuide({
    required int subjectId,
    String? lessonFocus,
  }) async {
    await _guard(() async {
      teachingPreparationGuide = await api.generateTeachingPreparationGuide(
        subjectId: subjectId,
        lessonFocus: lessonFocus,
      );
    });
  }

  Future<void> loadHome() async {
    await _guard(() async {
      subjects = await api.getSubjects();
      availabilities = await api.getAvailabilities();
      await _tryLoadFavoriteTutors();
    });
  }

  Future<void> loadTutorDetail(int tutorId) async {
    await _guard(() async {
      final results = await Future.wait([
        api.getTutorById(tutorId),
        api.getAvailabilitiesByTutor(tutorId),
      ]);

      selectedTutor = results[0] as TutorPublicModel;
      selectedTutorAvailabilities = results[1] as List<AvailabilityModel>;
      await _tryLoadFavoriteTutors();
      await _tryLoadTutorReviews(tutorId);

      for (final availability in selectedTutorAvailabilities) {
        final index = availabilities.indexWhere(
          (item) => item.availabilityId == availability.availabilityId,
        );

        if (index >= 0) {
          availabilities[index] = availability;
        } else {
          availabilities.add(availability);
        }
      }
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
      availabilities = await api.getAvailabilities();
      await _tryLoadMyTutorReviews();
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
      await _tryLoadMyTutorReviews();
    });
  }

  Future<void> loadHomeworkDashboard({bool force = false}) {
    if (!force && _homeworkDashboardLoad != null) {
      return _homeworkDashboardLoad!;
    }

    if (!force && lessons.isNotEmpty && _isFresh(_homeworkDashboardLoadedAt)) {
      return Future.value();
    }

    final load = _guard(() async {
      lessons = await api.getMyLessons();
      final lessonIds = lessons.map((lesson) => lesson.lessonId).toSet();

      lessonHomeworks.removeWhere(
        (lessonId, _) => !lessonIds.contains(lessonId),
      );

      await _tryLoadMyTutorReviews();
      _homeworkDashboardLoadedAt = DateTime.now();
    });

    _homeworkDashboardLoad = load;

    return load.whenComplete(() {
      if (_homeworkDashboardLoad == load) {
        _homeworkDashboardLoad = null;
      }
    });
  }

  Future<void> loadHomeworkCourse(
    int availabilityId, {
    bool force = false,
  }) {
    if (!force && _homeworkCourseLoads[availabilityId] != null) {
      return _homeworkCourseLoads[availabilityId]!;
    }

    final load = _guard(() async {
      if (lessons.isEmpty || force) {
        lessons = await api.getMyLessons();
      }

      final courseLessons = lessons
          .where((lesson) => lesson.availabilityId == availabilityId)
          .toList();

      for (final lesson in courseLessons) {
        await _loadLessonHomeworksRaw(lesson.lessonId, force: force);
      }
    });

    _homeworkCourseLoads[availabilityId] = load;

    return load.whenComplete(() {
      if (_homeworkCourseLoads[availabilityId] == load) {
        _homeworkCourseLoads.remove(availabilityId);
      }
    });
  }

  Future<void> loadCourseMaterials(
    int availabilityId, {
    bool force = false,
  }) {
    if (!force && _courseMaterialLoads[availabilityId] != null) {
      return _courseMaterialLoads[availabilityId]!;
    }

    if (!force &&
        courseMaterials.containsKey(availabilityId) &&
        _isFresh(
          _courseMaterialsLoadedAt[availabilityId],
          duration: _courseMaterialsCacheDuration,
        )) {
      return Future.value();
    }

    final load = _guard(() async {
      courseMaterials[availabilityId] =
          await api.getCourseMaterials(availabilityId);
      _courseMaterialsLoadedAt[availabilityId] = DateTime.now();
    });

    _courseMaterialLoads[availabilityId] = load;

    return load.whenComplete(() {
      if (_courseMaterialLoads[availabilityId] == load) {
        _courseMaterialLoads.remove(availabilityId);
      }
    });
  }

  Future<void> createMaterialSection({
    required int availabilityId,
    required String title,
    String? description,
  }) async {
    await _guard(() async {
      await api.createMaterialSection(
        availabilityId: availabilityId,
        title: title,
        description: description,
      );
      courseMaterials[availabilityId] =
          await api.getCourseMaterials(availabilityId);
      _courseMaterialsLoadedAt[availabilityId] = DateTime.now();
    });
  }

  Future<void> updateMaterialSection({
    required int availabilityId,
    required int sectionId,
    required String title,
    String? description,
  }) async {
    await _guard(() async {
      await api.updateMaterialSection(
        sectionId: sectionId,
        title: title,
        description: description,
      );
      courseMaterials[availabilityId] =
          await api.getCourseMaterials(availabilityId);
      _courseMaterialsLoadedAt[availabilityId] = DateTime.now();
    });
  }

  Future<void> deleteMaterialSection({
    required int availabilityId,
    required int sectionId,
  }) async {
    await _guard(() async {
      await api.deleteMaterialSection(sectionId);
      courseMaterials[availabilityId] =
          await api.getCourseMaterials(availabilityId);
      _courseMaterialsLoadedAt[availabilityId] = DateTime.now();
    });
  }

  Future<void> createMaterialItem({
    required int availabilityId,
    required int sectionId,
    required String title,
    String? description,
    String? linkUrl,
    PlatformFile? file,
  }) async {
    await _guard(() async {
      await api.createMaterialItem(
        availabilityId: availabilityId,
        sectionId: sectionId,
        title: title,
        description: description,
        linkUrl: linkUrl,
        file: file,
      );
      courseMaterials[availabilityId] =
          await api.getCourseMaterials(availabilityId);
      _courseMaterialsLoadedAt[availabilityId] = DateTime.now();
    });
  }

  Future<void> updateMaterialItem({
    required int availabilityId,
    required int materialId,
    required String title,
    String? description,
    String? linkUrl,
    PlatformFile? file,
    int? sectionId,
  }) async {
    await _guard(() async {
      final updated = await api.updateMaterialItem(
        materialId: materialId,
        title: title,
        description: description,
        linkUrl: linkUrl,
        file: file,
        sectionId: sectionId,
      );
      _replaceMaterialItem(availabilityId, updated);
      courseMaterials[availabilityId] =
          await api.getCourseMaterials(availabilityId);
      _replaceMaterialItem(availabilityId, updated);
      _courseMaterialsLoadedAt[availabilityId] = DateTime.now();
    });
  }

  Future<void> deleteMaterialItem({
    required int availabilityId,
    required int materialId,
  }) async {
    await _guard(() async {
      await api.deleteMaterialItem(materialId);
      courseMaterials[availabilityId] =
          await api.getCourseMaterials(availabilityId);
      _courseMaterialsLoadedAt[availabilityId] = DateTime.now();
    });
  }

  void _replaceMaterialItem(
    int availabilityId,
    CourseMaterialItemModel updated,
  ) {
    final sections = courseMaterials[availabilityId];
    if (sections == null) return;

    courseMaterials[availabilityId] = sections.map((section) {
      final items = section.items.map((item) {
        return item.materialId == updated.materialId ? updated : item;
      }).toList();

      return CourseMaterialSectionModel(
        sectionId: section.sectionId,
        availabilityId: section.availabilityId,
        title: section.title,
        description: section.description,
        displayOrder: section.displayOrder,
        createdAt: section.createdAt,
        items: items,
      );
    }).toList();
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

  Future<bool> shouldBlockRestrictedChatMessage({
    required ConversationModel? conversation,
    required String content,
  }) async {
    final text = content.trim();

    if (conversation == null || text.isEmpty) return false;
    if (!_containsRestrictedChatContent(text)) return false;

    try {
      await _ensureChatRestrictionContext();
    } catch (_) {
      return false;
    }

    final tutorId = _tutorIdForConversation(conversation);

    if (tutorId == null) {
      return false;
    }

    return !bookings.any(
      (booking) =>
          booking.tutorId == tutorId && _isBookedChatStatus(booking.status),
    );
  }

  void showRestrictedChatWarning() {
    error = restrictedChatWarning;
    notifyListeners();
  }

  Future<void> _ensureChatRestrictionContext() async {
    var changed = false;

    bookings = await api.getMyBookings();
    changed = true;

    if (availabilities.isEmpty) {
      availabilities = await api.getAvailabilities();
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  static bool _isBookedChatStatus(String status) {
    final normalized = status.trim().toLowerCase();

    return normalized.isNotEmpty &&
        normalized != 'cancelled' &&
        normalized != 'canceled' &&
        normalized != 'expired' &&
        normalized != 'rejected';
  }

  int? _tutorIdForConversation(ConversationModel conversation) {
    for (final availability in availabilities) {
      if (availability.tutorUserId == conversation.otherUserId) {
        return availability.tutorId;
      }
    }

    return null;
  }

  static bool _containsRestrictedChatContent(String content) {
    final text = content.trim();
    final lower = text.toLowerCase();

    final patterns = [
      RegExp(
        r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b((https?:\/\/|www\.)\S+|[A-Z0-9-]+\.(com|vn|net|org|io|me|app|edu|info)\b\S*)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:^|[^\d])(?:\+?84|0)(?:[\s.\-()]?\d){8,10}(?:$|[^\d])',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(zalo|facebook|fb|messenger|m\.me|telegram|whatsapp|gmail|email|e-mail|qr|vietqr|bank|banking|stk|so\s*tai\s*khoan|tai\s*khoan\s*ngan\s*hang|chuyen\s*khoan|ngan\s*hang|momo|vietcombank|vcb|techcombank|tcb|mbbank|mb\s*bank|acb|bidv|vietinbank|vpbank|tpbank)\b',
        caseSensitive: false,
      ),
    ];

    if (patterns.any((pattern) => pattern.hasMatch(text))) {
      return true;
    }

    final hasLongNumber =
        RegExp(r'(?:^|[^\d])(?:\d[\s.\-]*){8,20}(?:$|[^\d])').hasMatch(text);

    if (!hasLongNumber) {
      return false;
    }

    return lower.contains('account') ||
        lower.contains('bank') ||
        lower.contains('stk') ||
        lower.contains('tai khoan') ||
        lower.contains('ngan hang') ||
        lower.contains('chuyen khoan');
  }

  Future<void> loadMyAvailability() async {
    await _guard(() async {
      subjects = await api.getSubjects();
      myAvailabilities = await api.getMyAvailabilities();
    });
  }

  Future<void> createAvailability({
    required int subjectId,
    required List<String> daysOfWeek,
    required String mode,
    String? offlineAreas,
    String? description,
    required DateTime startCourseTime,
    required DateTime endCourseTime,
    required String startTime,
    required String endTime,
    required double pricePerSlot,
  }) async {
    await _guard(() async {
      await api.createAvailability(
        subjectId: subjectId,
        daysOfWeek: daysOfWeek,
        mode: mode,
        offlineAreas: offlineAreas,
        description: description,
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
      await _tryLoadFavoriteTutors();
      await _tryLoadMyTutorReviews();
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

  bool isFavoriteTutor(int tutorId) {
    return favoriteTutors.any((favorite) => favorite.tutorId == tutorId);
  }

  bool hasReviewedBooking(int bookingId) {
    return myTutorReviews.any((review) => review.bookingId == bookingId);
  }

  Future<void> loadFavoriteTutors() async {
    await _guard(() async {
      favoriteTutors = await api.getFavoriteTutors();
    });
  }

  Future<void> toggleFavoriteTutor({
    required int tutorId,
    required String name,
    int userId = 0,
    String? avatarUrl,
  }) async {
    await _guard(() async {
      if (isFavoriteTutor(tutorId)) {
        await api.unsaveFavoriteTutor(tutorId);
        favoriteTutors.removeWhere((favorite) => favorite.tutorId == tutorId);
        return;
      }

      final favorite = await api.saveFavoriteTutor(tutorId);

      favoriteTutors.removeWhere((item) => item.tutorId == tutorId);
      favoriteTutors.insert(
        0,
        favorite.tutorId == 0
            ? FavoriteTutorModel(
                favoriteTutorId: 0,
                tutorId: tutorId,
                userId: userId,
                name: name,
                email: '',
                phone: '',
                bio: '',
                rating: 0,
                isVerified: false,
                avatarUrl: avatarUrl,
              )
            : favorite,
      );
    });
  }

  Future<void> loadTutorReviews(int tutorId) async {
    await _guard(() async {
      tutorReviews[tutorId] = await api.getTutorReviews(tutorId);
    });
  }

  Future<void> createTutorReview({
    required int bookingId,
    required int tutorId,
    required int rating,
    required String comment,
  }) async {
    await _guard(() async {
      final review = await api.createTutorReview(
        bookingId: bookingId,
        tutorId: tutorId,
        rating: rating,
        comment: comment,
      );

      myTutorReviews.removeWhere((item) => item.bookingId == bookingId);
      myTutorReviews.insert(0, review);

      final reviews = tutorReviews[tutorId] ?? <TutorReviewModel>[];
      reviews.removeWhere((item) => item.reviewId == review.reviewId);
      tutorReviews[tutorId] = [review, ...reviews];

      if (selectedTutor?.tutorId == tutorId) {
        selectedTutor = await api.getTutorById(tutorId);
      }
    });
  }

  Future<void> _tryLoadFavoriteTutors() async {
    try {
      favoriteTutors = await api.getFavoriteTutors();
    } catch (_) {}
  }

  Future<void> _tryLoadTutorReviews(int tutorId) async {
    try {
      tutorReviews[tutorId] = await api.getTutorReviews(tutorId);
    } catch (_) {}
  }

  Future<void> _tryLoadMyTutorReviews() async {
    try {
      myTutorReviews = await api.getMyTutorReviews();
    } catch (_) {}
  }

  Future<PaymentModel> syncPayment(int bookingId) async {
    late PaymentModel payment;

    await _guard(() async {
      payment = await api.syncPayment(bookingId);

      bookings = await api.getMyBookings();
      lessons = await api.getMyLessons();
      availabilities = await api.getAvailabilities();
      await _tryLoadMyTutorReviews();
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

  Future<void> loadLessonHomeworks(
    int lessonId, {
    bool force = false,
  }) async {
    await _guard(() async {
      await _loadLessonHomeworksRaw(lessonId, force: force);
    });
  }

  Future<void> createHomework({
    required int lessonId,
    required Map<String, dynamic> body,
  }) async {
    await _guard(() async {
      await api.createHomework(lessonId: lessonId, body: body);
      await _loadLessonHomeworksRaw(lessonId, force: true);
    });
  }

  Future<void> updateHomework({
    required int lessonId,
    required int homeworkId,
    required Map<String, dynamic> body,
  }) async {
    await _guard(() async {
      await api.updateHomework(homeworkId: homeworkId, body: body);
      await _loadLessonHomeworksRaw(lessonId, force: true);
    });
  }

  Future<void> deleteHomework({
    required int lessonId,
    required int homeworkId,
  }) async {
    await _guard(() async {
      await api.deleteHomework(homeworkId);
      await _loadLessonHomeworksRaw(lessonId, force: true);
    });
  }

  Future<void> submitHomework({
    required int lessonId,
    required int homeworkId,
    required List<Map<String, dynamic>> multipleChoiceAnswers,
    required List<Map<String, dynamic>> essayAnswers,
  }) async {
    await _guard(() async {
      final submission = await api.submitHomework(
        homeworkId: homeworkId,
        multipleChoiceAnswers: multipleChoiceAnswers,
        essayAnswers: essayAnswers,
      );
      await _loadLessonHomeworksRaw(lessonId, force: true);
      _applyMyHomeworkSubmission(
        homeworkId: homeworkId,
        submission: submission,
      );
    });
  }

  Future<void> gradeEssaySubmission({
    required int lessonId,
    required int homeworkId,
    required int submissionId,
    required List<Map<String, dynamic>> essayGrades,
    String? feedback,
  }) async {
    await _guard(() async {
      final gradedSubmission = await api.gradeEssaySubmission(
        homeworkId: homeworkId,
        submissionId: submissionId,
        essayGrades: essayGrades,
        feedback: feedback,
      );
      await _loadLessonHomeworksRaw(lessonId, force: true);
      _applyGradedHomeworkSubmission(
        homeworkId: homeworkId,
        submission: gradedSubmission,
      );
    });
  }

  void _applyMyHomeworkSubmission({
    required int homeworkId,
    required HomeworkSubmissionModel submission,
  }) {
    _updateCachedHomeworkCopies(
      homeworkId: homeworkId,
      update: (homework) => homework.copyWith(mySubmission: submission),
    );
  }

  void _applyGradedHomeworkSubmission({
    required int homeworkId,
    required HomeworkSubmissionModel submission,
  }) {
    _updateCachedHomeworkCopies(
      homeworkId: homeworkId,
      update: (homework) {
        final submissions = [...homework.submissions];
        final submissionIndex = submissions.indexWhere(
          (item) => item.submissionId == submission.submissionId,
        );

        if (submissionIndex >= 0) {
          submissions[submissionIndex] = submission;
        } else {
          submissions.insert(0, submission);
        }

        final mySubmission =
            homework.mySubmission?.submissionId == submission.submissionId
                ? submission
                : homework.mySubmission;

        return homework.copyWith(
          mySubmission: mySubmission,
          submissions: submissions,
        );
      },
    );
  }

  void _updateCachedHomeworkCopies({
    required int homeworkId,
    required HomeworkModel Function(HomeworkModel homework) update,
  }) {
    for (final entry in lessonHomeworks.entries) {
      final homeworks = entry.value;

      for (var index = 0; index < homeworks.length; index += 1) {
        if (homeworks[index].homeworkId == homeworkId) {
          homeworks[index] = update(homeworks[index]);
        }
      }
    }
  }

  Future<void> _loadLessonHomeworksRaw(
    int lessonId, {
    bool force = false,
  }) async {
    if (!force && _isFresh(_lessonHomeworksLoadedAt[lessonId])) {
      return;
    }

    lessonHomeworks[lessonId] = await api.getLessonHomeworks(lessonId);
    _lessonHomeworksLoadedAt[lessonId] = DateTime.now();
  }

  bool _isFresh(
    DateTime? loadedAt, {
    Duration duration = _homeworkCacheDuration,
  }) {
    if (loadedAt == null) return false;
    return DateTime.now().difference(loadedAt) < duration;
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
    String? objective,
    String? learningGoals,
    String? expectedResults,
    String? requiredTopics,
    String? commonDifficulties,
  }) async {
    await _guard(() async {
      await api.adminCreateSubject(
        name: name,
        description: description,
        objective: objective,
        learningGoals: learningGoals,
        expectedResults: expectedResults,
        requiredTopics: requiredTopics,
        commonDifficulties: commonDifficulties,
      );

      subjects = await api.getSubjects();
      adminDashboard = await api.adminGetDashboard();
    });
  }

  Future<void> adminUpdateSubject({
    required int subjectId,
    required String name,
    required String description,
    String? objective,
    String? learningGoals,
    String? expectedResults,
    String? requiredTopics,
    String? commonDifficulties,
  }) async {
    await _guard(() async {
      await api.adminUpdateSubject(
        subjectId: subjectId,
        name: name,
        description: description,
        objective: objective,
        learningGoals: learningGoals,
        expectedResults: expectedResults,
        requiredTopics: requiredTopics,
        commonDifficulties: commonDifficulties,
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
    required XFile cccdFrontImage,
    required XFile cccdBackImage,
    required List<XFile> certificateImages,
    PlatformFile? transcriptDocument,
    required String bankName,
    required String accountNumber,
    required String accountHolderName,
    String? branchName,
    String? bankBin,
  }) async {
    await _guard(() async {
      tutorVerification = await api.submitTutorVerification(
        nationalIdNumber: nationalIdNumber,
        cccdFrontImage: cccdFrontImage,
        cccdBackImage: cccdBackImage,
        certificateImages: certificateImages,
        transcriptDocument: transcriptDocument,
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

  Future<void> loadTutorReports({String? status}) async {
    await _guard(() async {
      tutorReports = await api.getTutorReports(status: status);
    });
  }

  Future<void> createSupportReport({
    required String category,
    required String title,
    required String description,
    int? payoutId,
    int? bookingId,
    int? lessonId,
    required List<String> proofImagePaths,
  }) async {
    await _guard(() async {
      await api.createSupportReport(
        category: category,
        title: title,
        description: description,
        payoutId: payoutId,
        bookingId: bookingId,
        lessonId: lessonId,
        proofImagePaths: proofImagePaths,
      );

      supportReports = await api.getMySupportReports();
    });
  }

  Future<void> loadMySupportReports() async {
    await _guard(() async {
      supportReports = await api.getMySupportReports();
    });
  }

  Future<void> adminLoadSupportReports({
    String? role,
    String? status,
  }) async {
    await _guard(() async {
      adminSupportReports = await api.adminGetSupportReports(
        role: role,
        status: status,
      );
    });
  }

  Future<void> adminLoadSupportReportDetail(int supportReportId) async {
    await _guard(() async {
      adminSupportReportDetail =
          await api.adminGetSupportReportDetail(supportReportId);
    });
  }

  Future<void> adminUpdateSupportReportStatus({
    required int supportReportId,
    required String status,
    String? adminNote,
  }) async {
    await _guard(() async {
      adminSupportReportDetail = await api.adminUpdateSupportReportStatus(
        supportReportId: supportReportId,
        status: status,
        adminNote: adminNote,
      );

      adminSupportReports = await api.adminGetSupportReports();
    });
  }

  Future<void> uploadAvatar(String imagePath) async {
    await _guard(() async {
      await api.uploadAvatar(imagePath);
      profile = await api.getProfile();
    });
  }

  Future<void> deleteAvatar() async {
    await _guard(() async {
      await api.deleteAvatar();
      profile = await api.getProfile();
    });
  }

  Future<ConversationModel> startConversationByEmail(String email) async {
    late ConversationModel conversation;

    await _guard(() async {
      conversation = await api.startConversationByEmail(email);

      final index = conversations.indexWhere(
        (c) => c.conversationId == conversation.conversationId,
      );

      if (index >= 0) {
        conversations[index] = conversation;
      } else {
        conversations.insert(0, conversation);
      }
    });

    return conversation;
  }

  Future<void> loadAdminPayouts() async {
    await _guard(() async {
      adminPayouts = await api.adminGetPayouts();
    });
  }

  Future<void> adminApprovePayoutWithPayOSChi(int payoutId) async {
    await _guard(() async {
      final updated = await api.adminApprovePayoutWithPayOSChi(payoutId);

      _upsertAdminPayout(updated);
      adminPayoutDetail = await api.adminGetPayoutDetail(payoutId);
      adminPayouts = await api.adminGetPayouts();
      adminDashboard = await api.adminGetDashboard();
    });
  }

  Future<void> adminMarkPayoutPaidManual(int payoutId) async {
    await _guard(() async {
      final updated = await api.adminUpdatePayoutStatus(
        payoutId: payoutId,
        status: 'Paid',
      );

      _upsertAdminPayout(updated);
      adminPayoutDetail = await api.adminGetPayoutDetail(payoutId);
      adminPayouts = await api.adminGetPayouts();
      adminDashboard = await api.adminGetDashboard();
    });
  }

  Future<void> adminMarkPayoutFailed(int payoutId) async {
    await _guard(() async {
      final updated = await api.adminUpdatePayoutStatus(
        payoutId: payoutId,
        status: 'Failed',
      );

      _upsertAdminPayout(updated);
      adminPayoutDetail = await api.adminGetPayoutDetail(payoutId);
      adminPayouts = await api.adminGetPayouts();
      adminDashboard = await api.adminGetDashboard();
    });
  }

  void _upsertAdminPayout(PayoutModel payout) {
    final index = adminPayouts.indexWhere(
      (item) => item.payoutId == payout.payoutId,
    );

    if (index >= 0) {
      adminPayouts[index] = payout;
    } else {
      adminPayouts.insert(0, payout);
    }
  }
}
