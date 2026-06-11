import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mvp_models.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'EDUNEST_API_BASE_URL',
    defaultValue: 'https://edunest-backend-8e6z.onrender.com',
  );
  static const String appVersion = String.fromEnvironment(
    'EDUNEST_APP_VERSION',
    defaultValue: '0.2.0+2',
  );
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';

  final SharedPreferences prefs;
  late final Dio dio;

  VoidCallback? onUnauthorized;
  bool _unauthorizedHandled = false;

  ApiService({required this.prefs}) {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: const {
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = prefs.getString(tokenKey);

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            options.headers.remove('Authorization');
          }

          handler.next(options);
        },
        onError: (error, handler) {
          final statusCode = error.response?.statusCode;
          final path = error.requestOptions.path;

          final isAuthEndpoint = path.contains('/api/auth/login') ||
              path.contains('/api/auth/register') ||
              path.contains('/api/auth/verify-email') ||
              path.contains('/api/auth/resend-code');

          if (statusCode == 401 && !isAuthEndpoint) {
            final currentToken = prefs.getString(tokenKey);

            if (currentToken != null &&
                currentToken.isNotEmpty &&
                !_unauthorizedHandled) {
              _unauthorizedHandled = true;
              onUnauthorized?.call();
            }
          }

          handler.next(error);
        },
      ),
    );
  }

  String? get token => prefs.getString(tokenKey);

  String? get refreshTokenValue => prefs.getString(refreshTokenKey);

  bool get isLoggedIn {
    final value = token;
    return value != null && value.isNotEmpty;
  }

  Future<void> setToken(String? value) async {
    if (value == null || value.isEmpty) {
      await prefs.remove(tokenKey);
      dio.options.headers.remove('Authorization');
    } else {
      await prefs.setString(tokenKey, value);
      dio.options.headers['Authorization'] = 'Bearer $value';
      _unauthorizedHandled = false;
    }
  }

  Future<void> setRefreshToken(String? value) async {
    if (value == null || value.isEmpty) {
      await prefs.remove(refreshTokenKey);
    } else {
      await prefs.setString(refreshTokenKey, value);
    }
  }

  Future<void> clearTokens() async {
    await prefs.remove(tokenKey);
    await prefs.remove(refreshTokenKey);
    dio.options.headers.remove('Authorization');
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await dio.post(
      '/api/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    final data = _asMap(res.data);

    await setToken(data['accessToken']?.toString());
    await setRefreshToken(data['refreshToken']?.toString());

    return data;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String phone,
    String? school,
    String? bio,
    String? address,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'phone': phone,
      'school': school,
      'bio': bio,
      'address': address,
    };

    body.removeWhere((key, value) {
      if (value == null) return true;
      if (value is String && value.trim().isEmpty) return true;
      return false;
    });

    final res = await dio.post(
      '/api/auth/register',
      data: body,
    );

    return _asMap(res.data);
  }

  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    final res = await dio.post(
      '/api/auth/verify-email',
      data: {
        'email': email,
        'code': code,
      },
    );

    return _asMap(res.data);
  }

  Future<Map<String, dynamic>> resendVerificationCode({
    required String email,
  }) async {
    final res = await dio.post(
      '/api/auth/resend-code',
      data: {
        'email': email,
      },
    );

    return _asMap(res.data);
  }

  Future<List<AvailabilityModel>> getAvailabilities() async {
    final res = await dio.get('/api/availability');

    return _list(res.data).map((e) => AvailabilityModel.fromJson(e)).toList();
  }

  Future<List<AvailabilityModel>> getAvailabilitiesByTutor(int tutorId) async {
    final res = await dio.get('/api/availability/tutor/$tutorId');

    return _list(res.data).map((e) => AvailabilityModel.fromJson(e)).toList();
  }

  Future<TutorPublicModel> getTutorById(int tutorId) async {
    final res = await dio.get('/api/tutor/$tutorId');

    return TutorPublicModel.fromJson(_asMap(res.data));
  }

  Future<List<FavoriteTutorModel>> getFavoriteTutors() async {
    final res = await _tryRequests([
      () => dio.get('/api/favorite-tutor/me'),
      () => dio.get('/api/favorite/tutor/me'),
      () => dio.get('/api/favorite-tutors/me'),
      () => dio.get('/api/tutor/favorite'),
    ]);

    return _list(res.data).map((e) => FavoriteTutorModel.fromJson(e)).toList();
  }

  Future<FavoriteTutorModel> saveFavoriteTutor(int tutorId) async {
    final res = await _tryRequests([
      () => dio.post('/api/favorite-tutor/$tutorId'),
      () => dio.post(
            '/api/favorite-tutor',
            data: {
              'tutorId': tutorId,
            },
          ),
      () => dio.post('/api/favorite/tutor/$tutorId'),
      () => dio.post('/api/tutor/$tutorId/favorite'),
    ]);

    return FavoriteTutorModel.fromJson(_asMap(res.data));
  }

  Future<void> unsaveFavoriteTutor(int tutorId) async {
    await _tryRequests([
      () => dio.delete('/api/favorite-tutor/$tutorId'),
      () => dio.delete(
            '/api/favorite-tutor',
            data: {
              'tutorId': tutorId,
            },
          ),
      () => dio.delete('/api/favorite/tutor/$tutorId'),
      () => dio.delete('/api/tutor/$tutorId/favorite'),
    ]);
  }

  Future<List<TutorReviewModel>> getTutorReviews(int tutorId) async {
    final res = await _tryRequests([
      () => dio.get('/api/review/tutor/$tutorId'),
      () => dio.get('/api/tutor/$tutorId/review'),
      () => dio.get('/api/tutor/$tutorId/reviews'),
      () => dio.get('/api/tutor-review/tutor/$tutorId'),
    ]);

    return _list(res.data).map((e) => TutorReviewModel.fromJson(e)).toList();
  }

  Future<List<TutorReviewModel>> getMyTutorReviews() async {
    final res = await _tryRequests([
      () => dio.get('/api/review/me'),
      () => dio.get('/api/tutor-review/me'),
      () => dio.get('/api/reviews/me'),
    ]);

    return _list(res.data).map((e) => TutorReviewModel.fromJson(e)).toList();
  }

  Future<TutorReviewModel> createTutorReview({
    required int bookingId,
    required int tutorId,
    required int rating,
    required String comment,
  }) async {
    final body = <String, dynamic>{
      'bookingId': bookingId,
      'tutorId': tutorId,
      'rating': rating,
      'comment': comment.trim(),
    };

    final res = await _tryRequests([
      () => dio.post('/api/review', data: body),
      () => dio.post('/api/tutor-review', data: body),
      () => dio.post('/api/booking/$bookingId/review', data: body),
      () => dio.post('/api/tutor/$tutorId/review', data: body),
    ]);

    return TutorReviewModel.fromJson(_asMap(res.data));
  }

  Future<List<AvailabilityModel>> getMyAvailabilities() async {
    final res = await dio.get('/api/availability/me');

    return _list(res.data).map((e) => AvailabilityModel.fromJson(e)).toList();
  }

  Future<AvailabilityModel> createAvailability({
    required int subjectId,
    required List<String> daysOfWeek,
    required String mode,
    String? offlineAreas,
    required String level,
    required DateTime startCourseTime,
    required DateTime endCourseTime,
    required String startTime,
    required String endTime,
    required double pricePerSlot,
  }) async {
    final normalizedDays = daysOfWeek
        .map((day) => day.trim())
        .where((day) => day.isNotEmpty)
        .toList();

    final res = await dio.post(
      '/api/availability',
      data: {
        'subjectId': subjectId,
        'dayOfWeek': normalizedDays.join(','),
        'daysOfWeek': normalizedDays,
        'mode': mode,
        'offlineAreas': offlineAreas?.trim(),
        'level': level,
        'startCourseTime': _dateOnlyIso(startCourseTime),
        'endCourseTime': _dateOnlyIso(endCourseTime),
        'startTime': _normalizeTime(startTime),
        'endTime': _normalizeTime(endTime),
        'pricePerSlot': pricePerSlot,
      },
    );

    return AvailabilityModel.fromJson(_asMap(res.data));
  }

  Future<BookingModel> createBooking(
    int availabilityId, {
    String? note,
  }) async {
    final body = <String, dynamic>{
      'availabilityId': availabilityId,
      'note': note,
    };

    body.removeWhere((key, value) {
      if (value == null) return true;
      if (value is String && value.trim().isEmpty) return true;
      return false;
    });

    final res = await dio.post(
      '/api/booking',
      data: body,
    );

    return BookingModel.fromJson(_asMap(res.data));
  }

  Future<List<BookingModel>> getMyBookings() async {
    final res = await dio.get('/api/booking/me');

    return _list(res.data).map((e) => BookingModel.fromJson(e)).toList();
  }

  Future<PaymentModel> createPayOsPayment(int bookingId) async {
    final res = await dio.post('/api/payment/booking/$bookingId/payos');

    return PaymentModel.fromJson(_asMap(res.data));
  }

  Future<List<LessonModel>> getMyLessons() async {
    final res = await dio.get('/api/lesson/me');

    return _list(res.data).map((e) => LessonModel.fromJson(e)).toList();
  }

  Future<BookingModel> cancelBooking(int bookingId) async {
    final res = await dio.post('/api/booking/$bookingId/cancel');

    return BookingModel.fromJson(_asMap(res.data));
  }

  Future<LessonDetailModel> getLessonDetail(int lessonId) async {
    final res = await dio.get('/api/lesson/$lessonId/detail');

    return LessonDetailModel.fromJson(_asMap(res.data));
  }

  Future<List<HomeworkModel>> getLessonHomeworks(int lessonId) async {
    final res = await dio.get('/api/homework/lesson/$lessonId');

    return _list(res.data).map((e) => HomeworkModel.fromJson(e)).toList();
  }

  Future<HomeworkModel> createHomework({
    required int lessonId,
    required Map<String, dynamic> body,
  }) async {
    final res = await dio.post(
      '/api/homework/lesson/$lessonId',
      data: body,
    );

    return HomeworkModel.fromJson(_asMap(res.data));
  }

  Future<HomeworkModel> updateHomework({
    required int homeworkId,
    required Map<String, dynamic> body,
  }) async {
    final res = await dio.put(
      '/api/homework/$homeworkId',
      data: body,
    );

    return HomeworkModel.fromJson(_asMap(res.data));
  }

  Future<void> deleteHomework(int homeworkId) async {
    await dio.delete('/api/homework/$homeworkId');
  }

  Future<HomeworkSubmissionModel> submitHomework({
    required int homeworkId,
    required List<Map<String, dynamic>> multipleChoiceAnswers,
    required List<Map<String, dynamic>> essayAnswers,
  }) async {
    final res = await dio.post(
      '/api/homework/$homeworkId/submit',
      data: {
        'multipleChoiceAnswers': multipleChoiceAnswers,
        'essayAnswers': essayAnswers,
      },
    );

    return HomeworkSubmissionModel.fromJson(_asMap(res.data));
  }

  Future<HomeworkSubmissionModel> gradeEssaySubmission({
    required int homeworkId,
    required int submissionId,
    required List<Map<String, dynamic>> essayGrades,
    String? feedback,
  }) async {
    final res = await dio.patch(
      '/api/homework/$homeworkId/submissions/$submissionId/grade',
      data: {
        'essayGrades': essayGrades,
        if (feedback != null && feedback.trim().isNotEmpty)
          'feedback': feedback.trim(),
      },
    );

    return HomeworkSubmissionModel.fromJson(_asMap(res.data));
  }

  Future<List<CourseMaterialSectionModel>> getCourseMaterials(
    int availabilityId,
  ) async {
    late final Response<dynamic> res;

    try {
      res = await _tryRequests([
        () => dio.get('/api/material/availability/$availabilityId'),
        () => dio.get('/api/materials/availability/$availabilityId'),
        () => dio.get('/api/course-materials/availability/$availabilityId'),
        () => dio.get(
              '/api/material',
              queryParameters: {'availabilityId': availabilityId},
            ),
      ]);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return <CourseMaterialSectionModel>[];
      }

      rethrow;
    }

    return _materialSectionsFromResponse(
      res.data,
      availabilityId: availabilityId,
    );
  }

  Future<CourseMaterialSectionModel> createMaterialSection({
    required int availabilityId,
    required String title,
    String? description,
  }) async {
    final body = {
      'title': title.trim(),
      'description': description?.trim(),
    }..removeWhere((_, value) => value == null || value.toString().isEmpty);

    final res = await _tryRequests([
      () => dio.post(
            '/api/material/availability/$availabilityId/sections',
            data: body,
          ),
      () => dio.post(
            '/api/materials/availability/$availabilityId/sections',
            data: body,
          ),
      () => dio.post(
            '/api/course-materials/availability/$availabilityId/sections',
            data: body,
          ),
    ]);

    return CourseMaterialSectionModel.fromJson(_asMap(res.data));
  }

  Future<CourseMaterialSectionModel> updateMaterialSection({
    required int sectionId,
    required String title,
    String? description,
  }) async {
    final body = {
      'title': title.trim(),
      'description': description?.trim(),
    }..removeWhere((_, value) => value == null || value.toString().isEmpty);

    final res = await _tryRequests([
      () => dio.put('/api/material/sections/$sectionId', data: body),
      () => dio.put('/api/materials/sections/$sectionId', data: body),
      () => dio.put('/api/course-materials/sections/$sectionId', data: body),
    ]);

    return CourseMaterialSectionModel.fromJson(_asMap(res.data));
  }

  Future<void> deleteMaterialSection(int sectionId) async {
    await _tryRequests([
      () => dio.delete('/api/material/sections/$sectionId'),
      () => dio.delete('/api/materials/sections/$sectionId'),
      () => dio.delete('/api/course-materials/sections/$sectionId'),
    ]);
  }

  Future<CourseMaterialItemModel> createMaterialItem({
    required int availabilityId,
    required int sectionId,
    required String title,
    String? description,
    String? linkUrl,
    String? filePath,
  }) async {
    final hasFile = filePath != null && filePath.trim().isNotEmpty;
    Future<FormData> data() async => FormData.fromMap({
          'availabilityId': availabilityId,
          'sectionId': sectionId,
          'title': title.trim(),
          if (description != null && description.trim().isNotEmpty)
            'description': description.trim(),
          if (linkUrl != null && linkUrl.trim().isNotEmpty)
            'fileUrl': linkUrl.trim(),
          if (linkUrl != null && linkUrl.trim().isNotEmpty)
            'linkUrl': linkUrl.trim(),
          if (hasFile) 'file': await MultipartFile.fromFile(filePath.trim()),
        });

    final res = await _tryRequests([
      () async => dio.post(
            '/api/material/sections/$sectionId/items',
            data: await data(),
            options: Options(contentType: 'multipart/form-data'),
          ),
      () async => dio.post(
            '/api/materials/sections/$sectionId/items',
            data: await data(),
            options: Options(contentType: 'multipart/form-data'),
          ),
      () async => dio.post(
            '/api/course-materials/sections/$sectionId/items',
            data: await data(),
            options: Options(contentType: 'multipart/form-data'),
          ),
      () async => dio.post(
            '/api/material/availability/$availabilityId',
            data: await data(),
            options: Options(contentType: 'multipart/form-data'),
          ),
    ]);

    return CourseMaterialItemModel.fromJson(_asMap(res.data));
  }

  Future<CourseMaterialItemModel> updateMaterialItem({
    required int materialId,
    required String title,
    String? description,
    String? linkUrl,
    String? filePath,
    int? sectionId,
  }) async {
    final hasFile = filePath != null && filePath.trim().isNotEmpty;
    Future<FormData> data() async => FormData.fromMap({
          'title': title.trim(),
          if (sectionId != null) 'sectionId': sectionId,
          if (description != null && description.trim().isNotEmpty)
            'description': description.trim(),
          if (linkUrl != null && linkUrl.trim().isNotEmpty)
            'fileUrl': linkUrl.trim(),
          if (linkUrl != null && linkUrl.trim().isNotEmpty)
            'linkUrl': linkUrl.trim(),
          if (hasFile) 'file': await MultipartFile.fromFile(filePath.trim()),
        });

    final res = await _tryRequests([
      () async => dio.put(
            '/api/material/items/$materialId',
            data: await data(),
            options: Options(contentType: 'multipart/form-data'),
          ),
      () async => dio.put(
            '/api/materials/items/$materialId',
            data: await data(),
            options: Options(contentType: 'multipart/form-data'),
          ),
      () async => dio.put(
            '/api/course-materials/items/$materialId',
            data: await data(),
            options: Options(contentType: 'multipart/form-data'),
          ),
      () async => dio.put(
            '/api/material/$materialId',
            data: await data(),
            options: Options(contentType: 'multipart/form-data'),
          ),
    ]);

    return CourseMaterialItemModel.fromJson(_asMap(res.data));
  }

  Future<void> deleteMaterialItem(int materialId) async {
    await _tryRequests([
      () => dio.delete('/api/material/items/$materialId'),
      () => dio.delete('/api/materials/items/$materialId'),
      () => dio.delete('/api/course-materials/items/$materialId'),
      () => dio.delete('/api/material/$materialId'),
    ]);
  }

  Future<LessonDetailModel> setMeetingLink({
    required int lessonId,
    required String meetingLink,
  }) async {
    final res = await dio.post(
      '/api/lesson/$lessonId/meeting-link',
      data: {
        'meetingLink': meetingLink,
      },
    );

    return LessonDetailModel.fromJson(_asMap(res.data));
  }

  Future<LessonDetailModel> completeLessonGroup(int lessonId) async {
    final res = await dio.post('/api/lesson/$lessonId/complete-group');

    return LessonDetailModel.fromJson(_asMap(res.data));
  }

  Future<LessonModel> markAttendance(
    int lessonId, {
    String status = 'Present',
    String? note,
  }) async {
    final body = <String, dynamic>{
      'status': status,
      'note': note,
    };

    body.removeWhere((key, value) {
      if (value == null) return true;
      if (value is String && value.trim().isEmpty) return true;
      return false;
    });

    final res = await dio.post(
      '/api/lesson/$lessonId/attendance',
      data: body,
    );

    return LessonModel.fromJson(_asMap(res.data));
  }

  Future<LessonModel> completeLesson(
    int lessonId, {
    String? note,
  }) async {
    final body = <String, dynamic>{
      'note': note,
    };

    body.removeWhere((key, value) {
      if (value == null) return true;
      if (value is String && value.trim().isEmpty) return true;
      return false;
    });

    final res = await dio.post(
      '/api/lesson/$lessonId/complete',
      data: body,
    );

    return LessonModel.fromJson(_asMap(res.data));
  }

  Future<WalletModel> getWallet() async {
    final res = await dio.get('/api/wallet/me');

    return WalletModel.fromJson(_asMap(res.data));
  }

  Future<List<WalletTransactionModel>> getWalletTransactions() async {
    final res = await dio.get('/api/wallet/transaction');

    return _list(res.data)
        .map((e) => WalletTransactionModel.fromJson(e))
        .toList();
  }

  Future<List<PayoutModel>> getMyPayouts() async {
    final res = await dio.get('/api/payout/me');

    return _list(res.data).map((e) => PayoutModel.fromJson(e)).toList();
  }

  Future<PayoutModel> requestPayout(double amount) async {
    final res = await dio.post(
      '/api/payout',
      data: {
        'amount': amount,
      },
    );

    return PayoutModel.fromJson(_asMap(res.data));
  }

  Future<ConversationModel> startConversation(int otherUserId) async {
    final res = await dio.post(
      '/api/chat/conversation',
      data: {
        'otherUserId': otherUserId,
      },
    );

    return ConversationModel.fromJson(_asMap(res.data));
  }

  Future<ConversationModel> startConversationByEmail(String email) async {
    final res = await dio.post(
      '/api/chat/conversation',
      data: {
        'otherUserEmail': email.trim(),
      },
    );

    return ConversationModel.fromJson(_asMap(res.data));
  }

  Future<List<ConversationModel>> getConversations() async {
    final res = await dio.get('/api/chat/conversation');

    return _list(res.data).map((e) => ConversationModel.fromJson(e)).toList();
  }

  Future<List<MessageModel>> getMessages(int conversationId) async {
    final res = await dio.get(
      '/api/chat/conversation/$conversationId/message',
    );

    return _list(res.data).map((e) => MessageModel.fromJson(e)).toList();
  }

  Future<MessageModel> sendMessage(
    int conversationId,
    String content,
  ) async {
    final res = await dio.post(
      '/api/chat/conversation/$conversationId/message',
      data: {
        'content': content,
      },
    );

    return MessageModel.fromJson(_asMap(res.data));
  }

  Future<List<SubjectModel>> getSubjects() async {
    final res = await dio.get('/api/subject');

    return _list(res.data).map((e) => SubjectModel.fromJson(e)).toList();
  }

  Future<PaymentModel> syncPayment(int bookingId) async {
    final res = await dio.post('/api/payment/booking/$bookingId/sync');

    return PaymentModel.fromJson(_asMap(res.data));
  }

  Future<void> trackInstall() async {
    var deviceId = prefs.getString('device_install_id');

    if (deviceId == null || deviceId.isEmpty) {
      deviceId = 'android-${DateTime.now().microsecondsSinceEpoch}';
      await prefs.setString('device_install_id', deviceId);
    }

    final alreadyTracked = prefs.getBool('install_tracked') ?? false;

    if (alreadyTracked) return;

    try {
      await dio.post(
        '/api/admin/app/install',
        data: {
          'deviceId': deviceId,
          'platform': 'android',
          'appVersion': appVersion,
        },
      );

      await prefs.setBool('install_tracked', true);
    } catch (_) {
      // Do not block app startup.
      // It will retry on next app open.
    }
  }

  Future<void> trackDownload() async {
    try {
      await dio.post(
        '/api/admin/app/download',
        data: {
          'platform': 'android',
          'appVersion': appVersion,
        },
      );
    } catch (_) {
      // Ignore tracking error.
    }
  }

  Future<AdminDashboardModel> adminGetDashboard() async {
    final res = await dio.get('/api/admin/dashboard');
    return AdminDashboardModel.fromJson(_asMap(res.data));
  }

  Future<List<TutorVerificationModel>> adminGetPendingTutors() async {
    final res = await dio.get('/api/admin/tutor/pending');

    return _list(res.data)
        .map((e) => TutorVerificationModel.fromJson(e))
        .toList();
  }

  Future<TutorVerificationModel> adminApproveTutor(int tutorId) async {
    final res = await dio.post('/api/admin/tutor/$tutorId/approve');
    return TutorVerificationModel.fromJson(_asMap(res.data));
  }

  Future<TutorVerificationModel> adminRejectTutor({
    required int tutorId,
    String? reason,
  }) async {
    final res = await dio.post(
      '/api/admin/tutor/$tutorId/reject',
      data: {
        'reason': reason,
      },
    );

    return TutorVerificationModel.fromJson(_asMap(res.data));
  }

  Future<SubjectModel> adminCreateSubject({
    required String name,
    required String description,
  }) async {
    final res = await dio.post(
      '/api/admin/subject',
      data: {
        'name': name,
        'description': description,
      },
    );

    return SubjectModel.fromJson(_asMap(res.data));
  }

  Future<List<PayoutModel>> adminGetPayouts() async {
    final res = await dio.get('/api/admin/payout');

    final list = _asList(res.data);

    return list.map((e) => PayoutModel.fromJson(_asMap(e))).toList();
  }

  Future<PayoutModel> adminApprovePayoutWithPayOSChi(int payoutId) async {
    final res = await dio.patch(
      '/api/admin/payouts/$payoutId/approve-payos-chi',
    );

    return PayoutModel.fromJson(_asMap(res.data));
  }

  Future<PayoutModel> adminUpdatePayoutStatus({
    required int payoutId,
    required String status,
  }) async {
    final res = await dio.patch(
      '/api/admin/payout/$payoutId',
      data: {
        'status': status,
      },
    );

    return PayoutModel.fromJson(_asMap(res.data));
  }

  Future<PayoutModel> adminUpdatePayout({
    required int payoutId,
    required String status,
  }) async {
    final res = await dio.patch(
      '/api/admin/payout/$payoutId',
      data: {
        'status': status,
      },
    );

    return PayoutModel.fromJson(_asMap(res.data));
  }

  Future<List<TutorReportModel>> getTutorReports({String? status}) async {
    final res = await dio.get(
      '/api/report/tutor/me',
      queryParameters: {
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
      },
    );

    return _list(res.data).map((e) => TutorReportModel.fromJson(e)).toList();
  }

  Future<SupportReportModel> createSupportReport({
    required String category,
    required String title,
    required String description,
    int? payoutId,
    int? bookingId,
    int? lessonId,
    required List<String> proofImagePaths,
  }) async {
    final formData = FormData.fromMap({
      'category': category,
      'title': title,
      'description': description,
      if (payoutId != null) 'payoutId': payoutId,
      if (bookingId != null) 'bookingId': bookingId,
      if (lessonId != null) 'lessonId': lessonId,
      'proofImages': [
        for (final path in proofImagePaths) await MultipartFile.fromFile(path),
      ],
    });

    final res = await dio.post(
      '/api/support-report',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    return SupportReportModel.fromJson(_asMap(res.data));
  }

  Future<List<SupportReportModel>> getMySupportReports() async {
    final res = await dio.get('/api/support-report/me');

    return _list(res.data).map((e) => SupportReportModel.fromJson(e)).toList();
  }

  Future<List<SupportReportModel>> adminGetSupportReports({
    String? role,
    String? status,
  }) async {
    final res = await dio.get(
      '/api/support-report/admin',
      queryParameters: {
        if (role != null && role.trim().isNotEmpty) 'role': role.trim(),
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
      },
    );

    return _list(res.data).map((e) => SupportReportModel.fromJson(e)).toList();
  }

  Future<SupportReportModel> adminUpdateSupportReportStatus({
    required int supportReportId,
    required String status,
    String? adminNote,
  }) async {
    final res = await dio.patch(
      '/api/support-report/admin/$supportReportId/status',
      data: {
        'status': status,
        if (adminNote != null && adminNote.trim().isNotEmpty)
          'adminNote': adminNote.trim(),
      },
    );

    return SupportReportModel.fromJson(_asMap(res.data));
  }

  Future<SupportReportModel> adminGetSupportReportDetail(
    int supportReportId,
  ) async {
    final res = await dio.get(
      '/api/support-report/admin/$supportReportId',
    );

    return SupportReportModel.fromJson(_asMap(res.data));
  }

  Future<String?> uploadAvatar(String imagePath) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(imagePath),
    });

    final res = await dio.put(
      '/api/profile/avatar',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final map = _asMap(res.data);

    return map['avatarUrl']?.toString();
  }

  Future<void> deleteAvatar() async {
    await dio.delete('/api/profile/avatar');
  }

  Future<ProfileModel> getProfile() async {
    final res = await dio.get('/api/profile/me');

    return ProfileModel.fromJson(_asMap(res.data));
  }

  Future<TutorVerificationModel> getMyTutorVerification() async {
    final res = await dio.get('/api/tutor/verification/me');
    return TutorVerificationModel.fromJson(_asMap(res.data));
  }

  Future<TutorVerificationModel> submitTutorVerification({
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
    final formData = FormData.fromMap({
      'nationalIdNumber': nationalIdNumber,
      'cccdFrontImage': await MultipartFile.fromFile(cccdFrontPath),
      'cccdBackImage': await MultipartFile.fromFile(cccdBackPath),
      'certificateImage': await MultipartFile.fromFile(certificatePath),
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountHolderName': accountHolderName,
      if (branchName != null && branchName.trim().isNotEmpty)
        'branchName': branchName.trim(),
      if (bankBin != null && bankBin.trim().isNotEmpty)
        'bankBin': bankBin.trim(),
    });

    final res = await dio.post(
      '/api/tutor/verification',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );

    return TutorVerificationModel.fromJson(_asMap(res.data));
  }

  Future<TutorVerificationModel> adminGetTutorVerification(int tutorId) async {
    final res = await dio.get('/api/admin/tutor/$tutorId/verification');
    return TutorVerificationModel.fromJson(_asMap(res.data));
  }

  Future<AdminPayoutDetailModel> adminGetPayoutDetail(int payoutId) async {
    final res = await dio.get('/api/admin/payout/$payoutId');
    return AdminPayoutDetailModel.fromJson(_asMap(res.data));
  }

  Future<List<TutorVerificationModel>> adminGetTutors() async {
    final res = await dio.get('/api/admin/tutor');

    return _list(res.data)
        .map((e) => TutorVerificationModel.fromJson(e))
        .toList();
  }

  Future<AvailabilityModel> updateAvailabilityStatus({
    required int availabilityId,
    required String status,
  }) async {
    final res = await dio.patch(
      '/api/availability/$availabilityId/status',
      data: {
        'status': status,
      },
    );

    return AvailabilityModel.fromJson(_asMap(res.data));
  }

  Future<ProfileModel> getMyProfile() async {
    final res = await dio.get('/api/profile/me');

    return ProfileModel.fromJson(_asMap(res.data));
  }

  Future<ProfileModel> updateMyProfile({
    required String name,
    String? phone,
    String? tutorBio,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'phone': phone,
      'tutorBio': tutorBio,
    };

    body.removeWhere((key, value) {
      if (value == null) return true;
      if (value is String && value.trim().isEmpty) return true;
      return false;
    });

    final res = await dio.put(
      '/api/profile/me',
      data: body,
    );

    return ProfileModel.fromJson(_asMap(res.data));
  }

  Future<ProfileModel> updateTutorBankAccount({
    required String bankName,
    String? bankBin,
    required String accountNumber,
    required String accountHolderName,
    String? branchName,
  }) async {
    final body = <String, dynamic>{
      'bankName': bankName,
      'bankBin': bankBin,
      'accountNumber': accountNumber,
      'accountHolderName': accountHolderName,
      'branchName': branchName,
    };

    body.removeWhere((key, value) {
      if (value == null) return true;
      if (value is String && value.trim().isEmpty) return true;
      return false;
    });

    final res = await dio.put(
      '/api/profile/tutor-bank-account',
      data: body,
    );

    return ProfileModel.fromJson(_asMap(res.data));
  }

  static String _tutorApprovalSeenKey(int tutorId) {
    return 'tutor_approval_seen_$tutorId';
  }

  Future<bool> hasSeenTutorApprovalNotice(int tutorId) async {
    return prefs.getBool(_tutorApprovalSeenKey(tutorId)) ?? false;
  }

  Future<void> markTutorApprovalNoticeSeen(int tutorId) async {
    await prefs.setBool(_tutorApprovalSeenKey(tutorId), true);
  }

  Future<TutorReportModel> createTutorReport({
    required int bookingId,
    int? lessonId,
    required String category,
    required String title,
    required String description,
    required List<String> proofImagePaths,
  }) async {
    final formData = FormData.fromMap({
      'bookingId': bookingId,
      if (lessonId != null) 'lessonId': lessonId,
      'category': category,
      'title': title,
      'description': description,
      'proofImages': [
        for (final path in proofImagePaths) await MultipartFile.fromFile(path),
      ],
    });

    final res = await dio.post(
      '/api/report',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    return TutorReportModel.fromJson(_asMap(res.data));
  }

  Future<List<TutorReportModel>> getMyReports() async {
    final res = await dio.get('/api/report/me');

    return _list(res.data).map((e) => TutorReportModel.fromJson(e)).toList();
  }

  Future<List<TutorReportModel>> adminGetReports({String? status}) async {
    final res = await dio.get(
      '/api/report/admin',
      queryParameters: {
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
      },
    );

    return _list(res.data).map((e) => TutorReportModel.fromJson(e)).toList();
  }

  Future<TutorReportModel> adminGetReport(int reportId) async {
    final res = await dio.get('/api/report/admin/$reportId');

    return TutorReportModel.fromJson(_asMap(res.data));
  }

  Future<TutorReportModel> adminUpdateReportStatus({
    required int reportId,
    required String status,
    String? adminNote,
  }) async {
    final body = <String, dynamic>{
      'status': status,
      'adminNote': adminNote,
    };

    body.removeWhere((key, value) {
      if (value == null) return true;
      if (value is String && value.trim().isEmpty) return true;
      return false;
    });

    final res = await dio.patch(
      '/api/report/admin/$reportId/status',
      data: body,
    );

    return TutorReportModel.fromJson(_asMap(res.data));
  }

  Future<TutorVerificationModel> adminUpdateTutorAccountStatus({
    required int tutorId,
    required bool isActive,
  }) async {
    final res = await dio.patch(
      '/api/admin/tutor/$tutorId/account-status',
      data: {
        'isActive': isActive,
      },
    );

    return TutorVerificationModel.fromJson(_asMap(res.data));
  }

  Future<Map<String, dynamic>> getUserById(int userId) async {
    final response = await dio.get('/api/User/$userId');
    return response.data as Map<String, dynamic>;
  }

  List<CourseMaterialSectionModel> _materialSectionsFromResponse(
    dynamic data, {
    required int availabilityId,
  }) {
    final map = _asMap(data);
    final rawSections =
        map['sections'] ?? map['Sections'] ?? map['data'] ?? map['items'];

    if (rawSections is List) {
      final rows = rawSections.map((item) => _asMap(item)).toList();
      final sectionLike = rows.any((row) {
        return row.containsKey('items') ||
            row.containsKey('materials') ||
            row.containsKey('sectionId') ||
            row.containsKey('materialSectionId') ||
            row.containsKey('courseMaterialSectionId');
      });

      if (sectionLike) {
        return rows
            .map((row) => CourseMaterialSectionModel.fromJson(row))
            .toList()
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      }
    }

    final flatItems = _list(data)
        .map((item) => CourseMaterialItemModel.fromJson(item))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (flatItems.isEmpty) return <CourseMaterialSectionModel>[];

    return [
      CourseMaterialSectionModel.flat(
        availabilityId: availabilityId,
        items: flatItems,
      ),
    ];
  }

  Future<Response<dynamic>> _tryRequests(
    List<Future<Response<dynamic>> Function()> requests,
  ) async {
    DioException? fallbackError;

    for (final request in requests) {
      try {
        return await request();
      } on DioException catch (error) {
        if (!_canTryFallback(error)) {
          rethrow;
        }

        fallbackError = error;
      }
    }

    if (fallbackError != null) {
      throw fallbackError;
    }

    throw Exception('No API request was configured.');
  }

  bool _canTryFallback(DioException error) {
    final statusCode = error.response?.statusCode;
    return statusCode == 404 || statusCode == 405;
  }

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data == null) {
      return <String, dynamic>{};
    }

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    if (data is String) {
      return {
        'message': data,
      };
    }

    return {
      'data': data,
    };
  }

  static List<Map<String, dynamic>> _list(dynamic data) {
    if (data == null) {
      return <Map<String, dynamic>>[];
    }

    if (data is List) {
      return data.map((e) => _asMap(e)).toList();
    }

    if (data is Map) {
      final map = _asMap(data);

      final items = map['data'] ?? map['items'] ?? map['result'];

      if (items is List) {
        return items.map((e) => _asMap(e)).toList();
      }

      return <Map<String, dynamic>>[map];
    }

    return <Map<String, dynamic>>[];
  }

  static String _normalizeTime(String value) {
    final text = value.trim();

    if (RegExp(r'^\d{2}:\d{2}:\d{2}$').hasMatch(text)) {
      return text;
    }

    if (RegExp(r'^\d{2}:\d{2}$').hasMatch(text)) {
      return '$text:00';
    }

    return text;
  }
}

String apiErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;

    if (data is Map) {
      final validationMessage = _validationErrorMessage(data['errors']);
      if (validationMessage != null) {
        final message = data['message']?.toString();
        return message == null || message.trim().isEmpty
            ? validationMessage
            : '$message $validationMessage';
      }

      if (data['message'] != null) {
        return data['message'].toString();
      }

      if (data['title'] != null) {
        return data['title'].toString();
      }

      return data.toString();
    }

    if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    final statusCode = error.response?.statusCode;

    if (statusCode != null) {
      return 'Request failed with status code $statusCode';
    }

    return error.message ?? 'Network error';
  }

  return error.toString();
}

String? _validationErrorMessage(dynamic errors) {
  if (errors == null) return null;

  if (errors is Map) {
    final messages = <String>[];

    for (final entry in errors.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      final detail = value is List ? value.join(', ') : value.toString();

      if (detail.trim().isNotEmpty) {
        messages.add('$key: $detail');
      }
    }

    return messages.isEmpty ? null : messages.join(' ');
  }

  if (errors is List) {
    final text = errors.map((item) => item.toString()).join(' ');
    return text.trim().isEmpty ? null : text;
  }

  final text = errors.toString().trim();
  return text.isEmpty ? null : text;
}

String _dateOnlyIso(DateTime value) {
  final dateOnly = DateTime(value.year, value.month, value.day);
  return dateOnly.toIso8601String();
}

List<dynamic> _asList(dynamic data) {
  if (data is List) {
    return data;
  }

  if (data is Map<String, dynamic>) {
    final possibleKeys = [
      'data',
      'items',
      'result',
      'results',
      r'$values',
    ];

    for (final key in possibleKeys) {
      final value = data[key];

      if (value is List) {
        return value;
      }

      if (value is Map<String, dynamic> && value[r'$values'] is List) {
        return value[r'$values'] as List;
      }
    }
  }

  return [];
}
