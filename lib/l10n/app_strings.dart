import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'app_language_provider.dart';

class AppStrings {
  final String languageCode;

  const AppStrings(this.languageCode);

  bool get isVi => languageCode == 'vi';

  static AppStrings of(BuildContext context, {bool listen = true}) {
    final provider = listen
        ? context.watch<AppLanguageProvider>()
        : context.read<AppLanguageProvider>();
    return AppStrings(provider.languageCode);
  }

  String get appName => 'EduNest';
  String get admin => isVi ? 'Quản trị' : 'Admin';
  String get home => isVi ? 'Trang chủ' : 'Home';
  String get booking => isVi ? 'Đặt lịch' : 'Booking';
  String get course => isVi ? 'Khóa học' : 'Course';
  String get chat => isVi ? 'Trò chuyện' : 'Chat';
  String get wallet => isVi ? 'Ví' : 'Wallet';
  String get profile => isVi ? 'Hồ sơ' : 'Profile';
  String get lesson => isVi ? 'Buổi học' : 'Lesson';
  String get homework => isVi ? 'Bài tập' : 'Homework';
  String get materials => isVi ? 'Tài liệu' : 'Materials';
  String get section => isVi ? 'Phần' : 'Section';
  String get noMaterialCoursesTutor => isVi
      ? 'Chưa có khóa học nào để thêm tài liệu.'
      : 'No courses are available for materials yet.';
  String get noMaterialCoursesLearner => isVi
      ? 'Chưa có khóa học đã đăng ký.'
      : 'No enrolled courses are available yet.';
  String get noCoursesAvailableYet =>
      isVi ? 'Chưa có khóa học.' : 'No courses available yet.';
  String get noHomeworkHere =>
      isVi ? 'Chưa có bài tập trong mục này.' : 'No homework here yet.';
  String get courseTools => isVi ? 'Công cụ khóa học' : 'Course tools';
  String get language => isVi ? 'Ngôn ngữ' : 'Language';
  String get refresh => isVi ? 'Làm mới' : 'Refresh';
  String get vietnamese => isVi ? 'Tiếng Việt' : 'Vietnamese';
  String get english => isVi ? 'Tiếng Anh' : 'English';
  String get login => isVi ? 'Đăng nhập' : 'Login';
  String get signUp => isVi ? 'Đăng ký' : 'Sign up';
  String get welcomeBack => isVi ? 'Chào mừng trở lại' : 'Welcome back';
  String get chooseYourRole =>
      isVi ? 'Chọn vai trò của bạn' : 'Choose your role';
  String get tutor => isVi ? 'Gia sư' : 'Tutor';
  String get parentStudent =>
      isVi ? 'Phụ huynh / Học sinh' : 'Parent / Student';
  String get teach => isVi ? 'Giảng dạy' : 'Teach';
  String get learn => isVi ? 'Học tập' : 'Learn';
  String get email => 'Email';
  String get password => isVi ? 'Mật khẩu' : 'Password';
  String get hidePassword => isVi ? 'Ẩn mật khẩu' : 'Hide password';
  String get showPassword => isVi ? 'Hiện mật khẩu' : 'Show password';
  String get emailRequired =>
      isVi ? 'Vui lòng nhập email' : 'Email is required';
  String get passwordRequired =>
      isVi ? 'Vui lòng nhập mật khẩu' : 'Password is required';
  String get invalidEmail => isVi ? 'Email không hợp lệ' : 'Invalid email';
  String get passwordTooShort => isVi
      ? 'Mật khẩu phải có ít nhất 6 ký tự'
      : 'Password must be at least 6 characters';
  String get requiredField => isVi ? 'Bắt buộc' : 'Required';
  String get createAccount => isVi ? 'Tạo tài khoản' : 'Create account';
  String get registerAs => isVi ? 'Đăng ký với vai trò' : 'Register as';
  String get parent => isVi ? 'Phụ huynh' : 'Parent';
  String get student => isVi ? 'Học sinh' : 'Student';
  String get fullName => isVi ? 'Họ và tên' : 'Full name';
  String get phone => isVi ? 'Số điện thoại' : 'Phone';
  String get tutorBio => isVi ? 'Giới thiệu gia sư' : 'Tutor bio';
  String get shortIntro => isVi ? 'Giới thiệu ngắn' : 'Short intro';
  String get school => isVi ? 'Trường học' : 'School';
  String get address => isVi ? 'Địa chỉ' : 'Address';
  String get verifyYourEmail =>
      isVi ? 'Vui lòng xác minh email của bạn.' : 'Please verify your email.';
  String get verify => isVi ? 'Xác minh' : 'Verify';
  String get checkYourEmail =>
      isVi ? 'Kiểm tra email của bạn' : 'Check your email';
  String get verificationCode => isVi ? 'Mã xác minh' : 'Verification code';
  String get code => isVi ? 'Mã' : 'Code';
  String get verificationCodeRequired =>
      isVi ? 'Vui lòng nhập mã xác minh' : 'Verification code is required';
  String get emailVerified => isVi
      ? 'Email đã được xác minh. Vui lòng đăng nhập.'
      : 'Email verified successfully. Please login.';
  String get verificationCodeResent => isVi
      ? 'Đã gửi lại mã xác minh. Vui lòng kiểm tra email.'
      : 'Verification code resent. Check your email.';
  String get resendCode => isVi ? 'Gửi lại mã' : 'Resend code';
  String get myCourses => isVi ? 'Khóa học của tôi' : 'My Courses';
  String get exploreTutors => isVi ? 'Tìm gia sư' : 'Explore Tutors';
  String get favoriteTutors => isVi ? 'Gia sư yêu thích' : 'Favorite tutors';
  String get noCoursesAvailable =>
      isVi ? 'Chưa có khóa học' : 'No Courses Available';
  String get startSharingKnowledge => isVi
      ? 'Hãy bắt đầu chia sẻ kiến thức với học sinh ngay hôm nay.'
      : 'Start sharing your knowledge with students today.';
  String get active => isVi ? 'Đang mở' : 'Active';
  String get hidden => isVi ? 'Đã ẩn' : 'Hidden';
  String get lessonsLower => isVi ? 'buổi học' : 'lessons';
  String get totalTuition => isVi ? 'Tổng học phí' : 'Total Tuition';
  String get hide => isVi ? 'Ẩn' : 'Hide';
  String get publish => isVi ? 'Đăng' : 'Publish';
  String get hideCourseTitle => isVi ? 'Ẩn khóa học?' : 'Hide Course?';
  String get publishCourseTitle => isVi ? 'Đăng khóa học?' : 'Publish Course?';
  String get hideCourseMessage => isVi
      ? 'Học sinh sẽ không thể tìm hoặc đặt khóa học này nữa.'
      : 'Students will no longer be able to find or book this course.';
  String get publishCourseMessage => isVi
      ? 'Học sinh sẽ có thể tìm và đăng ký khóa học này.'
      : 'Students will be able to find and book this course open for registration.';
  String get cancel => isVi ? 'Hủy' : 'Cancel';
  String get courseStatusUpdated => isVi
      ? 'Đã cập nhật trạng thái khóa học'
      : 'Course status updated successfully';
  String get noTutorsAvailable => isVi
      ? 'Hiện chưa có gia sư khả dụng.'
      : 'No tutors are currently available.';
  String activeCoursesOpen(int count) =>
      isVi ? '$count khóa học đang mở' : '$count active courses open';
  String get unsaveTutor => isVi ? 'Bỏ lưu gia sư' : 'Unsave tutor';
  String get saveTutor => isVi ? 'Lưu gia sư' : 'Save tutor';
  String get viewTutorProfile =>
      isVi ? 'Xem hồ sơ gia sư' : 'View tutor profile';
  String get tutorSaved => isVi ? 'Đã lưu gia sư' : 'Tutor saved';
  String get tutorRemoved => isVi
      ? 'Đã xóa gia sư khỏi danh sách yêu thích'
      : 'Tutor removed from favorites';
  String get fullTuitionPackage =>
      isVi ? 'Trọn gói học phí' : 'Full Tuition Package';
  String get enrollNow => isVi ? 'Đăng ký ngay' : 'Enroll Now';
  String get enrolledSuccessfully => isVi
      ? 'Đã đăng ký lớp học thành công!'
      : 'Enrolled in class successfully!';
  String get personalProfile => isVi ? 'Hồ sơ cá nhân' : 'Personal Profile';
  String get logOut => isVi ? 'Đăng xuất' : 'Log Out';
  String get personalInformation =>
      isVi ? 'Thông tin cá nhân' : 'Personal Information';
  String get emailAddress => isVi ? 'Địa chỉ email' : 'Email Address';
  String get phoneNumber => isVi ? 'Số điện thoại' : 'Phone Number';
  String get biographyTutor => isVi
      ? 'Tiểu sử / Giới thiệu (Gia sư)'
      : 'Biography / Introduction (Tutor)';
  String get saveChanges => isVi ? 'Lưu thay đổi' : 'Save Changes';
  String get profileUpdated =>
      isVi ? 'Đã cập nhật hồ sơ' : 'Profile updated successfully';
  String get bankAccountUpdated => isVi
      ? 'Đã cập nhật tài khoản ngân hàng'
      : 'Bank account updated successfully';
  String get avatarUpdated =>
      isVi ? 'Đã cập nhật ảnh đại diện' : 'Avatar updated successfully';
  String couldNotUploadAvatar(Object error) => isVi
      ? 'Không thể tải ảnh đại diện: $error'
      : 'Could not upload avatar: $error';
  String get noAvatarToDelete =>
      isVi ? 'Không có ảnh đại diện để xóa' : 'No avatar to delete';
  String get deleteAvatarTitle => isVi ? 'Xóa ảnh đại diện?' : 'Delete avatar?';
  String get deleteAvatarMessage => isVi
      ? 'Ảnh hồ sơ của bạn sẽ bị xóa.'
      : 'Your profile image will be removed.';
  String get delete => isVi ? 'Xóa' : 'Delete';
  String get avatarDeleted => isVi ? 'Đã xóa ảnh đại diện' : 'Avatar deleted';
  String get uploadUpdateAvatar =>
      isVi ? 'Tải lên / Cập nhật ảnh đại diện' : 'Upload / Update avatar';
  String get deleteAvatar => isVi ? 'Xóa ảnh đại diện' : 'Delete avatar';
  String get languagePreference =>
      isVi ? 'Tùy chọn ngôn ngữ' : 'Language preference';
  String get chooseAppLanguage => isVi
      ? 'Chọn ngôn ngữ hiển thị của ứng dụng.'
      : 'Choose the display language for the app.';
  String get bankAccountDetails =>
      isVi ? 'Thông tin tài khoản ngân hàng' : 'Bank Account Details';
  String get bankBinInfo => isVi
      ? 'Bank BIN cần cho tự động chi trả, chuyển khoản VietQR và xác minh tài khoản ngân hàng.'
      : 'Bank BIN is required for automatic payout, VietQR transfer, and bank account validation.';
  String get bankName => isVi ? 'Tên ngân hàng' : 'Bank Name';
  String get bankBin => 'Bank BIN';
  String get accountNumber => isVi ? 'Số tài khoản' : 'Account Number';
  String get accountHolderName =>
      isVi ? 'Tên chủ tài khoản' : 'Account Holder Name';
  String get bankBranchOptional =>
      isVi ? 'Chi nhánh ngân hàng (Tùy chọn)' : 'Bank Branch (Optional)';
  String get saveBankInformation =>
      isVi ? 'Lưu thông tin ngân hàng' : 'Save Bank Information';
  String get reportsAboutMe => isVi ? 'Báo cáo về tôi' : 'Reports About Me';
  String get reportsAboutMeSubtitle => isVi
      ? 'Xem báo cáo về các buổi dạy của bạn và tiến độ xử lý của quản trị viên.'
      : 'View reports submitted about your tutoring sessions and admin progress.';
  String get reportIssueToAdmin =>
      isVi ? 'Báo cáo sự cố cho quản trị viên' : 'Report an Issue to Admin';
  String get reportIssueToAdminSubtitle => isVi
      ? 'Thiếu thanh toán, chi trả chậm, lỗi ví, lỗi ứng dụng, vấn đề đặt lịch...'
      : 'Missing payment, slow payout, wallet issue, app bug, booking problem...';
  String get myAdminSupportReports =>
      isVi ? 'Báo cáo hỗ trợ của tôi' : 'My Admin Support Reports';
  String get myAdminSupportReportsSubtitle => isVi
      ? 'Xem tiến độ và ghi chú của quản trị viên cho các sự cố đã gửi.'
      : 'View progress and admin notes for your submitted issues.';
  String get myReports => isVi ? 'Báo cáo của tôi' : 'My Reports';
  String get myReportsSubtitle => isVi
      ? 'Theo dõi báo cáo gia sư bạn đã gửi và tiến độ xử lý.'
      : 'Track tutor reports you submitted and view admin progress.';
  String get termsOfService => isVi ? 'Điều khoản dịch vụ' : 'Terms of Service';
  String get termsOfServiceSubtitle => isVi
      ? 'Đọc quy định của EduNest về thanh toán, báo cáo, ví, gia sư và tài khoản.'
      : 'Read EduNest rules for payments, reports, wallet, tutors, and account policies.';

  String get myBookings => isVi ? 'Lịch đặt của tôi' : 'My Bookings';
  String get noBookingsFound => isVi ? 'Chưa có lịch đặt' : 'No Bookings Found';
  String get bookingsEmptyMessage => isVi
      ? 'Các lớp đã đăng ký hoặc buổi học đã lên lịch sẽ xuất hiện tại đây.'
      : 'Your registered classes or scheduled sessions will appear here.';
  String get bookingId => isVi ? 'Mã đặt lịch' : 'Booking ID';
  String get tutorId => isVi ? 'Mã gia sư' : 'Tutor ID';
  String get availabilityId => isVi ? 'Mã lịch dạy' : 'Availability ID';
  String get tuitionFee => isVi ? 'Học phí' : 'Tuition Fee';
  String get payNow => isVi ? 'Thanh toán ngay' : 'Pay Now';
  String get paid => isVi ? 'Đã thanh toán' : 'Paid';
  String get completed => isVi ? 'Hoàn tất' : 'Completed';
  String get cancelled => isVi ? 'Đã hủy' : 'Cancelled';
  String get expired => isVi ? 'Hết hạn' : 'Expired';
  String get failed => isVi ? 'Thất bại' : 'Failed';
  String get unavailable => isVi ? 'Không khả dụng' : 'Unavailable';
  String get pending => isVi ? 'Đang chờ' : 'Pending';
  String get confirmed => isVi ? 'Đã xác nhận' : 'Confirmed';
  String get cancelBooking => isVi ? 'Hủy đặt lịch' : 'Cancel Booking';
  String get reportTutor => isVi ? 'Báo cáo gia sư' : 'Report Tutor';
  String get reviewed => isVi ? 'Đã đánh giá' : 'Reviewed';
  String get reviewTutor => isVi ? 'Đánh giá gia sư' : 'Review Tutor';
  String get reviewSubmitted => isVi ? 'Đã gửi đánh giá' : 'Review submitted';
  String get cancelBookingTitle =>
      isVi ? 'Hủy yêu cầu đặt lịch?' : 'Cancel Booking Request?';
  String get cancelBookingMessage => isVi
      ? 'Thao tác này sẽ hủy yêu cầu đặt lịch đang chờ. Bạn có thể đặt lại khung giờ này sau nếu cần.'
      : 'This action will cancel the pending booking request. You can book this slot again later if needed.';
  String get keepBooking => isVi ? 'Giữ đặt lịch' : 'Keep Booking';
  String get confirmCancel => isVi ? 'Xác nhận hủy' : 'Confirm Cancel';
  String get bookingCancelled => isVi
      ? 'Đã hủy yêu cầu đặt lịch'
      : 'Booking request cancelled successfully';

  String get lessonsTitle => isVi ? 'Buổi học' : 'Lessons';
  String get myTeachingLessons =>
      isVi ? 'Buổi dạy của tôi' : 'My teaching lessons';
  String get myLearningLessons =>
      isVi ? 'Buổi học của tôi' : 'My learning lessons';
  String get noLessonsYet => isVi
      ? 'Chưa có buổi học. Hãy thanh toán lịch đặt trước.'
      : 'No lessons yet. Pay a booking first.';
  String get attendanceReminder =>
      isVi ? 'Nhắc điểm danh' : 'Attendance reminder';
  String get attendanceReminderMessage => isVi
      ? 'Các buổi học này đã kết thúc nhưng chưa hoàn tất. Mở trang chi tiết, điểm danh, rồi hoàn tất buổi học.'
      : 'These lessons have ended but are not completed yet. Open the detail page, take attendance, then complete the lesson.';
  String get open => isVi ? 'Mở' : 'Open';
  String get nextLesson => isVi ? 'Buổi học kế tiếp' : 'Next lesson';
  String get openLessonDetail =>
      isVi ? 'Mở chi tiết buổi học' : 'Open lesson detail';
  String get openDetail => isVi ? 'Mở chi tiết' : 'Open detail';
  String get endedTakeAttendance => isVi
      ? 'Đã kết thúc. Hãy điểm danh và hoàn tất buổi học này.'
      : 'Ended. Take attendance and complete this lesson.';
  String get lessonStartedCompletionLater => isVi
      ? 'Buổi học đã bắt đầu. Có thể hoàn tất sau thời gian kết thúc.'
      : 'Lesson started. Completion unlocks after end time.';
  String get startsLater => isVi ? 'Bắt đầu sau' : 'Starts later';
  String get couldNotOpenMeeting =>
      isVi ? 'Không thể mở liên kết buổi học' : 'Could not open meeting link';
  String get invalidMeetingLink =>
      isVi ? 'Liên kết buổi học không hợp lệ' : 'Invalid meeting link';
  String get openMeeting => isVi ? 'Mở buổi học' : 'Open meeting';
  String get meetingLinkNotAdded =>
      isVi ? 'Chưa có liên kết buổi học' : 'Meeting link not added yet';
  String tutorName(String name) => isVi ? 'Gia sư: $name' : 'Tutor: $name';
  String students(int count) =>
      isVi ? '$count học sinh' : '$count student${count == 1 ? '' : 's'}';
  String lessonsN(int count) =>
      isVi ? '$count buổi học' : '$count lesson${count == 1 ? '' : 's'}';
  String materialsN(int count) =>
      isVi ? '$count tài liệu' : '$count material${count == 1 ? '' : 's'}';
  String points(Object value) => isVi ? '$value điểm' : '$value pts';
  String dueAt(String value) => isVi ? 'Hạn nộp $value' : 'Due $value';
  String submittedAt(String value) =>
      isVi ? 'Đã nộp $value' : 'Submitted $value';
  String lessonWithTutor(String value, String tutorName) =>
      isVi ? 'Buổi học $value với $tutorName' : '$value lesson with $tutorName';
  String sessionsN(int count) =>
      isVi ? '$count phiên' : '$count session${count == 1 ? '' : 's'}';
  String coursesN(int count) =>
      isVi ? '$count khóa học' : '$count course${count == 1 ? '' : 's'}';
  String studentRows(int count) =>
      isVi ? '$count dòng học sinh' : '$count student rows';
  String availabilityNumber(Object id) =>
      isVi ? 'Lịch dạy #$id' : 'Availability #$id';
  String bookingDuration(Object bookingId, Object minutes) => isVi
      ? 'Đặt lịch #$bookingId - $minutes phút'
      : 'Booking #$bookingId - $minutes min';
  String moreSessionsNeedAttention(int count) => isVi
      ? '+$count phiên khác cần chú ý.'
      : '+$count more session${count == 1 ? '' : 's'} need attention.';
  String deleteSectionMessage(String title) => isVi
      ? 'Xóa "$title" và tất cả tài liệu bên trong?'
      : 'Delete "$title" and all materials inside it?';
  String deleteMaterialMessage(String title) =>
      isVi ? 'Xóa "$title"?' : 'Delete "$title"?';

  String get myWallet => isVi ? 'Ví của tôi' : 'My Wallet';
  String get walletTutorOnly => isVi
      ? 'Tính năng ví chỉ khả dụng cho tài khoản Gia sư.'
      : 'The Wallet feature is only available for Tutor accounts.';
  String get availableBalance => isVi ? 'Số dư khả dụng' : 'Available Balance';
  String get pendingClearance =>
      isVi ? 'Đang chờ xử lý: ' : 'Pending Clearance: ';
  String get payoutRequest => isVi ? 'Yêu cầu rút tiền' : 'Payout Request';
  String get amountToWithdraw =>
      isVi ? 'Số tiền muốn rút' : 'Amount to Withdraw';
  String minimumAmount(String amount) =>
      isVi ? 'Tối thiểu: $amount' : 'Minimum: $amount';
  String get sendingRequest =>
      isVi ? 'Đang gửi yêu cầu...' : 'Sending Request...';
  String get submitPayoutRequest =>
      isVi ? 'Gửi yêu cầu rút tiền' : 'Submit Payout Request';
  String get transactionHistory =>
      isVi ? 'Lịch sử giao dịch' : 'Transaction History';
  String get payoutHistory => isVi ? 'Lịch sử rút tiền' : 'Payout History';
  String get noTransactionsYet =>
      isVi ? 'Chưa có giao dịch' : 'No transactions yet';
  String get noPayoutRequestsYet =>
      isVi ? 'Chưa có yêu cầu rút tiền' : 'No payout requests yet';
  String minimumPayoutAmount(String amount) => isVi
      ? 'Số tiền rút tối thiểu là $amount'
      : 'The minimum payout amount is $amount';
  String get payoutExceedsBalance => isVi
      ? 'Số tiền yêu cầu vượt quá số dư khả dụng.'
      : 'The amount requested exceeds your available balance.';
  String get payoutSubmitted => isVi
      ? 'Đã gửi yêu cầu rút tiền'
      : 'Payout request submitted successfully';
  String payoutRequestNumber(Object id) =>
      isVi ? 'Yêu cầu #$id' : 'Request #$id';
  String rangeOf(int start, int end, int total) =>
      isVi ? '$start-$end trên $total' : '$start-$end of $total';

  String get userEmail => isVi ? 'Email người dùng' : 'User email';
  String get enterValidUserEmail =>
      isVi ? 'Nhập email người dùng hợp lệ' : 'Enter a valid user email';
  String get start => isVi ? 'Bắt đầu' : 'Start';
  String conversationNumber(int id) =>
      isVi ? 'Cuộc trò chuyện #$id' : 'Conversation #$id';
  String get noMessagesYet => isVi ? 'Chưa có tin nhắn.' : 'No messages yet.';
  String get startConversation =>
      isVi ? 'Bắt đầu cuộc trò chuyện' : 'Start the conversation';
  String get you => isVi ? 'Bạn' : 'You';
  String get messageHint => isVi ? 'Nhập tin nhắn...' : 'Type a message...';
  String get restrictedChatWarning => isVi
      ? 'Để an toàn, hãy giữ liên lạc và thanh toán trong EduNest.'
      : 'For your safety, keep communication and payment inside EduNest.';

  String get bankBinHint => isVi ? 'Ví dụ: 970422' : 'Example: 970422';
  String get bankBinHelper => isVi
      ? 'Cần cho tự động chi trả và mã QR chuyển khoản nhanh.'
      : 'Required for automatic payout and quick transfer QR.';
  String get viewBankBinList =>
      isVi ? 'Xem danh sách Bank BIN' : 'View bank BIN list';
  String get bankBinRequired =>
      isVi ? 'Vui lòng nhập Bank BIN' : 'Bank BIN is required';
  String get validVietnamBankBin => isVi
      ? 'Vui lòng chọn Bank BIN Việt Nam hợp lệ'
      : 'Please select a valid Vietnamese bank BIN';
  String get searchBank => isVi ? 'Tìm ngân hàng' : 'Search bank';
  String get searchBankHint =>
      isVi ? 'Tìm theo tên, mã hoặc BIN' : 'Search by name, code, or BIN';
  String get selectRealBankBin => isVi
      ? 'Chọn BIN của tài khoản ngân hàng thật của gia sư. Không dùng BIN ví điện tử/ứng dụng thanh toán.'
      : 'Select the BIN of the tutor real bank account. Do not use wallet/payment app BINs.';

  String reviewTutorName(String name) =>
      isVi ? 'Đánh giá $name' : 'Review $name';
  String bookingNumber(int id) => isVi ? 'Đặt lịch #$id' : 'Booking #$id';
  String starTooltip(int value) => isVi ? '$value sao' : '$value star';
  String get comment => isVi ? 'Bình luận' : 'Comment';
  String get reviewHint => isVi
      ? 'Chia sẻ điều tốt hoặc điều có thể cải thiện'
      : 'Share what worked well or what could improve';
  String get sending => isVi ? 'Đang gửi...' : 'Sending...';
  String get submit => isVi ? 'Gửi' : 'Submit';
  String get thisFieldRequired =>
      isVi ? 'Vui lòng nhập trường này' : 'This field is required';

  String role(String role) {
    switch (role.toLowerCase()) {
      case 'tutor':
        return isVi ? 'GIA SƯ' : 'TUTOR';
      case 'learner':
        return isVi ? 'NGƯỜI HỌC' : 'LEARNER';
      case 'admin':
        return isVi ? 'QUẢN TRỊ' : 'ADMIN';
      default:
        return role.isEmpty
            ? (isVi ? 'NGƯỜI DÙNG' : 'USER')
            : role.toUpperCase();
    }
  }

  String authFlowTitle(bool isTutor) => isTutor ? tutor : parentStudent;

  String text(String source) {
    if (!isVi) return source;

    return _viPhrases[source] ?? source;
  }

  String status(String value) {
    switch (value.trim().toLowerCase()) {
      case 'pending':
        return pending;
      case 'paid':
        return paid;
      case 'confirmed':
        return confirmed;
      case 'completed':
      case 'complete':
        return completed;
      case 'cancelled':
      case 'canceled':
        return cancelled;
      case 'expired':
        return expired;
      case 'failed':
        return failed;
      case 'active':
        return active;
      case 'inactive':
      case 'hidden':
        return hidden;
      case 'approved':
        return isVi ? 'Đã duyệt' : 'Approved';
      case 'processing':
        return isVi ? 'Đang xử lý' : 'Processing';
      case 'manualqrrequired':
      case 'manual qr required':
        return isVi ? 'Cần QR/thủ công' : 'Manual QR required';
      case 'notsubmitted':
      case 'not submitted':
        return isVi ? 'Chưa nộp' : 'Not submitted';
      case 'reviewing':
        return isVi ? 'Đang xem xét' : 'Reviewing';
      case 'resolved':
        return isVi ? 'Đã xử lý' : 'Resolved';
      case 'rejected':
        return isVi ? 'Bị từ chối' : 'Rejected';
      case 'present':
        return isVi ? 'Có mặt' : 'Present';
      case 'absent':
        return isVi ? 'Vắng mặt' : 'Absent';
      case 'late':
        return isVi ? 'Đi trễ' : 'Late';
      case 'notstarted':
      case 'not started':
        return isVi ? 'Chưa bắt đầu' : 'Not started';
      default:
        return value;
    }
  }

  String mode(String value) {
    switch (value.trim().toLowerCase()) {
      case 'online':
        return isVi ? 'Trực tuyến' : 'Online';
      case 'offline':
        return isVi ? 'Trực tiếp' : 'Offline';
      case 'hybrid':
        return isVi ? 'Kết hợp' : 'Hybrid';
      default:
        return value;
    }
  }

  String level(String value) {
    switch (value.trim().toLowerCase()) {
      case 'beginner':
        return isVi ? 'Cơ bản' : 'Beginner';
      case 'intermediate':
        return isVi ? 'Trung cấp' : 'Intermediate';
      case 'advanced':
        return isVi ? 'Nâng cao' : 'Advanced';
      default:
        return value;
    }
  }
}

const Map<String, String> _viPhrases = {
  'Create availability': 'Tạo lịch dạy',
  'You can now create teaching availability.':
      'Bây giờ bạn có thể tạo lịch dạy.',
  'Choose a subject': 'Chọn môn học',
  'Please choose a subject': 'Vui lòng chọn môn học',
  'No subjects loaded. Refresh': 'Chưa tải môn học. Làm mới',
  'Choose at least one day': 'Chọn ít nhất một ngày',
  'Days of week': 'Ngày trong tuần',
  'Monday': 'Thứ hai',
  'Tuesday': 'Thứ ba',
  'Wednesday': 'Thứ tư',
  'Thursday': 'Thứ năm',
  'Friday': 'Thứ sáu',
  'Saturday': 'Thứ bảy',
  'Sunday': 'Chủ nhật',
  'Offline tutoring areas': 'Khu vực dạy trực tiếp',
  'Example: District 1, District 3, Binh Thanh':
      'Ví dụ: Quận 1, Quận 3, Bình Thạnh',
  'Enter the areas you are willing to tutor':
      'Nhập khu vực bạn có thể dạy trực tiếp',
  'Level': 'Trình độ',
  'Mode': 'Hình thức',
  'Start course date': 'Ngày bắt đầu khóa học',
  'End course date': 'Ngày kết thúc khóa học',
  'Start time': 'Giờ bắt đầu',
  'End time': 'Giờ kết thúc',
  'Price per lesson': 'Giá mỗi buổi học',
  'Example: 200000': 'Ví dụ: 200000',
  'Course price preview': 'Xem trước học phí khóa học',
  'My availability': 'Lịch dạy của tôi',
  'No availability yet': 'Chưa có lịch dạy',
  'Create your first teaching schedule above.':
      'Tạo lịch dạy đầu tiên của bạn ở phía trên.',
  'Waiting for admin approval': 'Đang chờ quản trị viên duyệt',
  'Your documents have been submitted. You cannot create availability until admin approves your tutor profile.':
      'Hồ sơ của bạn đã được gửi. Bạn chưa thể tạo lịch dạy cho đến khi quản trị viên duyệt hồ sơ gia sư.',
  'Verification rejected': 'Xác minh bị từ chối',
  'Your verification was rejected. Please update your documents and submit again.':
      'Hồ sơ xác minh của bạn bị từ chối. Vui lòng cập nhật tài liệu và gửi lại.',
  'Tutor verification required': 'Cần xác minh gia sư',
  'Please submit your CCCD, certificate or university document, and bank information before creating availability.':
      'Vui lòng gửi CCCD, chứng chỉ hoặc tài liệu trường học, và thông tin ngân hàng trước khi tạo lịch dạy.',
  'Open verification form': 'Mở biểu mẫu xác minh',
  'Your verification was rejected': 'Xác minh của bạn đã bị từ chối',
  'Please check your documents and submit again.':
      'Vui lòng kiểm tra giấy tờ và gửi lại.',
  'CCCD front image': 'Ảnh mặt trước CCCD',
  'Upload the front side of your CCCD.': 'Tải lên mặt trước CCCD của bạn.',
  'CCCD back image': 'Ảnh mặt sau CCCD',
  'Upload the back side of your CCCD.': 'Tải lên mặt sau CCCD của bạn.',
  'Upload degree, certificate, or enrollment document.':
      'Tải lên bằng cấp, chứng chỉ hoặc giấy xác nhận nhập học.',
  'Upload Certificates': 'Tải lên chứng chỉ',
  'Certificate of Enrollment or Academic Transcript':
      'Giấy xác nhận đang học hoặc bảng điểm học tập',
  'Maximum 5 images': 'Tối đa 5 ảnh',
  'Maximum 5 certificate images.': 'Tối đa 5 ảnh chứng chỉ.',
  '{count} image(s) selected': 'Đã chọn {count} ảnh',
  'Add images': 'Thêm ảnh',
  'Remove': 'Xóa',
  'Branch name optional': 'Tên chi nhánh (tùy chọn)',
  'Submit verification': 'Gửi xác minh',
  'Please upload CCCD front, CCCD back, and certificate.':
      'Vui lòng tải lên mặt trước CCCD, mặt sau CCCD và chứng chỉ.',
  'Please upload CCCD front, CCCD back, and at least one certificate.':
      'Vui lòng tải lên mặt trước CCCD, mặt sau CCCD và ít nhất một chứng chỉ.',
  'Verification submitted. Please wait for admin approval.':
      'Đã gửi xác minh. Vui lòng chờ quản trị viên duyệt.',
  'Your tutor profile is approved. You can create availability.':
      'Hồ sơ gia sư của bạn đã được duyệt. Bạn có thể tạo lịch dạy.',
  'Your documents are submitted. Please wait for admin review.':
      'Giấy tờ của bạn đã được gửi. Vui lòng chờ quản trị viên xem xét.',
  'Please update your documents and submit again.':
      'Vui lòng cập nhật giấy tờ và gửi lại.',
  'Verification required': 'Cần xác minh',
  'Submit your CCCD, certificate, and bank information before creating availability.':
      'Gửi CCCD, chứng chỉ và thông tin ngân hàng trước khi tạo lịch dạy.',
  'You cannot create availability until your tutor profile is approved.':
      'Bạn chưa thể tạo lịch dạy cho đến khi hồ sơ gia sư được duyệt.',
  'Go to home': 'Về trang chủ',
  'Change': 'Đổi',
  'Pick': 'Chọn',
  'Unable to load existing image': 'Không thể tải ảnh hiện có',
  'Refresh approval status': 'Làm mới trạng thái duyệt',
  'Invalid course date. Use yyyy-MM-dd':
      'Ngày khóa học không hợp lệ. Dùng yyyy-MM-dd',
  'Start date must be before end date': 'Ngày bắt đầu phải trước ngày kết thúc',
  'Invalid time. Use HH:mm:ss': 'Giờ không hợp lệ. Dùng HH:mm:ss',
  'Start time must be before end time': 'Giờ bắt đầu phải trước giờ kết thúc',
  'No lesson found for selected days in this date range':
      'Không có buổi học nào trong khoảng ngày đã chọn',
  'Invalid price per lesson': 'Giá mỗi buổi học không hợp lệ',
  'Availability created': 'Đã tạo lịch dạy',
  'Areas': 'Khu vực',
  'minutes': 'phút',
  'Lesson detail': 'Chi tiết buổi học',
  'Students': 'Học sinh',
  'Homework is managed separately': 'Bài tập được quản lý riêng',
  'Create assignments and grade submissions in the Homework tab.':
      'Tạo bài tập và chấm bài nộp trong tab Bài tập.',
  'No homework yet. Add an assignment for this session.':
      'Chưa có bài tập. Hãy thêm bài cho buổi học này.',
  'No homework assigned for this session yet.':
      'Buổi học này chưa được giao bài tập.',
  'Submit homework': 'Nộp bài tập',
  'Meeting link saved': 'Đã lưu liên kết buổi học',
  'Marked as': 'Đã đánh dấu là',
  'Google Meet link': 'Liên kết Google Meet',
  'Meeting link': 'Liên kết buổi học',
  'Paste Google Meet link here': 'Dán liên kết Google Meet tại đây',
  'No meeting link yet': 'Chưa có liên kết buổi học',
  'Save link': 'Lưu liên kết',
  'Saving...': 'Đang lưu...',
  'Present': 'Có mặt',
  'Absent': 'Vắng mặt',
  'Late': 'Đi trễ',
  'Mark': 'Đánh dấu',
  'Locked': 'Đã khóa',
  'Not started': 'Chưa bắt đầu',
  'Attendance and completion actions are now locked.':
      'Điểm danh và hoàn tất buổi học hiện đã bị khóa.',
  'Complete lesson unavailable': 'Chưa thể hoàn tất buổi học',
  'You can complete this lesson after the lesson end time.':
      'Bạn có thể hoàn tất buổi học sau thời gian kết thúc.',
  'Completing...': 'Đang hoàn tất...',
  'Complete lesson': 'Hoàn tất buổi học',
  'Materials': 'Tài liệu',
  'Manage course materials': 'Quản lý tài liệu khóa học',
  'Course materials': 'Tài liệu khóa học',
  'Organize files and links by section for each class.':
      'Sắp xếp tệp và liên kết theo từng phần cho mỗi lớp.',
  'Open shared files and links from your enrolled classes.':
      'Mở tệp và liên kết được chia sẻ từ các lớp bạn đã đăng ký.',
  'Class': 'Lớp',
  'No material sections in this course yet.':
      'Khóa học này chưa có phần tài liệu.',
  'No materials have been shared for this course yet.':
      'Chưa có tài liệu nào được chia sẻ cho khóa học này.',
  'No materials in this section yet.': 'Phần này chưa có tài liệu.',
  'Add material': 'Thêm tài liệu',
  'Edit material': 'Sửa tài liệu',
  'Delete material': 'Xóa tài liệu',
  'Edit section': 'Sửa phần',
  'Delete section': 'Xóa phần',
  'Add section': 'Thêm phần',
  'Title': 'Tiêu đề',
  'Description optional': 'Mô tả (tùy chọn)',
  'Link or existing file URL': 'Liên kết hoặc URL tệp hiện có',
  'Choose file': 'Chọn tệp',
  'Save': 'Lưu',
  'Edit': 'Sửa',
  'Open': 'Mở',
  'Material file must be 10MB or smaller.':
      'Tệp tài liệu phải nhỏ hơn hoặc bằng 10MB.',
  'Section added': 'Đã thêm phần',
  'Section updated': 'Đã cập nhật phần',
  'Section deleted': 'Đã xóa phần',
  'Material added': 'Đã thêm tài liệu',
  'Material updated': 'Đã cập nhật tài liệu',
  'Material deleted': 'Đã xóa tài liệu',
  'This default section cannot be deleted.': 'Không thể xóa phần mặc định này.',
  'This default section can be edited after backend sections are enabled.':
      'Có thể sửa phần mặc định này sau khi backend bật quản lý phần.',
  'No file or link is available for this material.':
      'Tài liệu này chưa có tệp hoặc liên kết.',
  'Could not open this material.': 'Không thể mở tài liệu này.',
  'Delete section?': 'Xóa phần?',
  'Delete material?': 'Xóa tài liệu?',
  'Homework': 'Bài tập',
  'Lessons': 'Buổi học',
  'All': 'Tất cả',
  'To do': 'Cần làm',
  'Due soon': 'Sắp hết hạn',
  'Submitted': 'Đã nộp',
  'Graded': 'Đã chấm',
  'No homework here yet.': 'Chưa có bài tập trong mục này.',
  'No lesson is available for homework yet.':
      'Chưa có buổi học nào để tạo bài tập.',
  'Homework cannot be added to an ended lesson':
      'Không thể thêm bài tập vào buổi học đã kết thúc',
  'Homework created': 'Đã tạo bài tập',
  'Homework cannot be edited after a submission is received':
      'Không thể sửa bài tập sau khi đã có bài nộp',
  'Homework updated': 'Đã cập nhật bài tập',
  'Delete homework?': 'Xóa bài tập?',
  'Homework deleted': 'Đã xóa bài tập',
  'Submission graded': 'Đã chấm bài nộp',
  'Create homework': 'Tạo bài tập',
  'Edit homework': 'Sửa bài tập',
  'Question': 'Câu hỏi',
  'Answer': 'Câu trả lời',
  'Feedback': 'Phản hồi',
  'Grade': 'Điểm',
  'Due date': 'Hạn nộp',
  'Multiple choice': 'Trắc nghiệm',
  'Essay': 'Tự luận',
  'Pending': 'Đang chờ',
  'Overdue': 'Quá hạn',
  'Open lesson': 'Mở buổi học',
  'Do homework': 'Làm bài tập',
  'View result': 'Xem kết quả',
  'Previous page': 'Trang trước',
  'Next page': 'Trang sau',
  'Result available': 'Đã có kết quả',
  'Auto scored': 'Tự động chấm',
  'No homework assigned in this course yet.':
      'Khóa học này chưa có bài tập được giao.',
  'No homework in this view.': 'Không có bài tập trong chế độ xem này.',
  'This homework is past its due date.': 'Bài tập này đã quá hạn nộp.',
  'This homework is close to its due date.': 'Bài tập này sắp đến hạn nộp.',
  'Add': 'Thêm',
  'Assigned': 'Đã giao',
  'To grade': 'Cần chấm',
  'No lessons are available for homework yet.':
      'Chưa có buổi học nào để giao bài tập.',
  'No homework in this course yet.': 'Khóa học này chưa có bài tập.',
  'Delete homework and its submissions?': 'Xóa bài tập này và tất cả bài nộp?',
  'submissions': 'bài nộp',
  'to grade': 'cần chấm',
  'No essay prompts': 'Chưa có đề tự luận',
  'No questions': 'Chưa có câu hỏi',
  'essay prompts': 'đề tự luận',
  'questions': 'câu hỏi',
  'No submissions yet': 'Chưa có bài nộp',
  'Student submissions': 'Bài nộp của học sinh',
  'Add homework': 'Thêm bài tập',
  'Description': 'Mô tả',
  'Type': 'Loại',
  'Create': 'Tạo',
  'Question text': 'Nội dung câu hỏi',
  'Points': 'Điểm',
  'Remove question': 'Xóa câu hỏi',
  'Option': 'Lựa chọn',
  'Remove option': 'Xóa lựa chọn',
  'Add option': 'Thêm lựa chọn',
  'Add question': 'Thêm câu hỏi',
  'Remove essay': 'Xóa đề tự luận',
  'Essay prompt': 'Đề bài tự luận',
  'Add essay': 'Thêm đề tự luận',
  'Score': 'Điểm',
  'Overall feedback': 'Nhận xét chung',
  'Save grade': 'Lưu điểm',
  'View detail': 'Xem chi tiết',
  'Edit locked after submission': 'Đã khóa sửa sau khi có bài nộp',
  'Homework submitted': 'Đã nộp bài tập',
  'Submitting...': 'Đang nộp...',
  'Back': 'Quay lại',
  'Homework not found for this lesson.':
      'Không tìm thấy bài tập cho buổi học này.',
  'Parent accounts can view homework and results. Student accounts submit homework.':
      'Tài khoản phụ huynh có thể xem bài tập và kết quả. Tài khoản học sinh dùng để nộp bài.',
  'Write your answer': 'Viết câu trả lời của bạn',
  'Essay result': 'Kết quả tự luận',
  'Essay submitted': 'Đã nộp bài tự luận',
  'Waiting for tutor grading': 'Đang chờ gia sư chấm bài',
  'Tutor feedback': 'Nhận xét của gia sư',
  'Essay answers': 'Câu trả lời tự luận',
  'Essay response': 'Câu trả lời tự luận',
  'possible': 'tối đa',
  'Question feedback': 'Nhận xét cho câu hỏi',
  'Waiting for tutor feedback': 'Đang chờ nhận xét từ gia sư',
  'Tutor Profile': 'Hồ sơ gia sư',
  'Available courses': 'Khóa học hiện có',
  'Verified tutor': 'Gia sư đã xác minh',
  'New tutor': 'Gia sư mới',
  'Tutor reviews': 'Đánh giá gia sư',
  'No written reviews yet.': 'Chưa có đánh giá bằng chữ.',
  'About': 'Giới thiệu',
  'This tutor has not added an introduction yet.':
      'Gia sư này chưa thêm phần giới thiệu.',
  'Full tuition package': 'Trọn gói học phí',
  'Enroll': 'Đăng ký',
  'This tutor has no active courses right now.':
      'Gia sư này hiện chưa có khóa học đang mở.',
  'Admin': 'Quản trị',
  'Admin Dashboard': 'Bảng điều khiển quản trị',
  'Dashboard': 'Bảng điều khiển',
  'Pending Tutors': 'Gia sư chờ duyệt',
  'Reports': 'Báo cáo',
  'Support Reports': 'Báo cáo hỗ trợ',
  'Search support reports': 'Tìm báo cáo hỗ trợ',
  'Payouts': 'Chi trả',
  'Subjects': 'Môn học',
  'Tutors': 'Gia sư',
  'Learners': 'Người học',
  'Learner': 'Người học',
  'Users': 'Người dùng',
  'Search': 'Tìm kiếm',
  'Status': 'Trạng thái',
  'Category': 'Danh mục',
  'Update Status': 'Cập nhật trạng thái',
  'Update support report': 'Cập nhật báo cáo hỗ trợ',
  'Update Support Report': 'Cập nhật báo cáo hỗ trợ',
  'Admin note': 'Ghi chú quản trị',
  'Reviewing': 'Đang xem xét',
  'Resolved': 'Đã xử lý',
  'Rejected': 'Bị từ chối',
  'Approved': 'Đã duyệt',
  'Active': 'Đang hoạt động',
  'Deactivated': 'Đã vô hiệu hóa',
  'Approve tutor': 'Duyệt gia sư',
  'Approve tutor?': 'Duyệt gia sư?',
  'Reject tutor': 'Từ chối gia sư',
  'Approve': 'Duyệt',
  'Reject': 'Từ chối',
  'Tutor approved': 'Đã duyệt gia sư',
  'Tutor rejected': 'Đã từ chối gia sư',
  'Activate': 'Kích hoạt',
  'Deactivate': 'Vô hiệu hóa',
  'Activate tutor?': 'Kích hoạt gia sư?',
  'Deactivate tutor?': 'Vô hiệu hóa gia sư?',
  'Tutor activated': 'Đã kích hoạt gia sư',
  'Tutor active': 'Gia sư đang hoạt động',
  'Tutor deactivated': 'Đã vô hiệu hóa gia sư',
  'Tutor information': 'Thông tin gia sư',
  'Bank information': 'Thông tin ngân hàng',
  'Submitted documents': 'Tài liệu đã nộp',
  'Tap an image to inspect it in detail': 'Nhấn vào ảnh để xem chi tiết',
  'CCCD front': 'Mặt trước CCCD',
  'CCCD back': 'Mặt sau CCCD',
  'Certificate / university document': 'Chứng chỉ / tài liệu trường học',
  'Missing': 'Thiếu',
  'Report details': 'Chi tiết báo cáo',
  'Proof images': 'Ảnh bằng chứng',
  'Submit': 'Gửi',
  'Report submitted': 'Đã gửi báo cáo',
  'Maximum 5 proof images allowed': 'Tối đa 5 ảnh bằng chứng',
  'Please upload at least one proof image':
      'Vui lòng tải lên ít nhất một ảnh bằng chứng',
  'No support reports found.': 'Không tìm thấy báo cáo hỗ trợ.',
  'Support report updated': 'Đã cập nhật báo cáo hỗ trợ',
  'Tutor': 'Gia sư',
  'Parent': 'Phụ huynh',
  'Student': 'Học sinh',
  'Role': 'Vai trò',
  'Email': 'Email',
  'User': 'Người dùng',
  'Report ID': 'Mã báo cáo',
  'Total': 'Tổng',
  'Reporter': 'Người báo cáo',
  'No reports found.': 'Không tìm thấy báo cáo.',
  'Try another status filter to see more reports.':
      'Thử bộ lọc trạng thái khác để xem thêm báo cáo.',
  'Report information': 'Thông tin báo cáo',
  'Core details submitted by the reporter':
      'Chi tiết chính do người báo cáo gửi',
  'Booking ID': 'Mã đặt lịch',
  'Availability ID': 'Mã lịch dạy',
  'Lesson ID': 'Mã buổi học',
  'Subject': 'Môn học',
  'No proof images': 'Không có ảnh bằng chứng',
  'No image proof was submitted for this report.':
      'Không có ảnh bằng chứng nào được gửi cho báo cáo này.',
  'image(s) attached for review': 'ảnh đính kèm để xem xét',
  'Admin actions': 'Thao tác quản trị',
  'Update the review status and leave an optional internal note':
      'Cập nhật trạng thái xem xét và để lại ghi chú nội bộ nếu cần',
  'Admin note optional': 'Ghi chú quản trị (tùy chọn)',
  'Reject report': 'Từ chối báo cáo',
  'Report marked as': 'Đã đánh dấu báo cáo là',
  'Reported tutor': 'Gia sư bị báo cáo',
  'Account and verification details for the reported tutor':
      'Thông tin tài khoản và xác minh của gia sư bị báo cáo',
  'Tutor name': 'Tên gia sư',
  'Tutor user ID': 'Mã người dùng gia sư',
  'Account status': 'Trạng thái tài khoản',
  'Deactivate tutor account': 'Vô hiệu hóa tài khoản gia sư',
  'Activate tutor account': 'Kích hoạt tài khoản gia sư',
  'Tutor account activated': 'Đã kích hoạt tài khoản gia sư',
  'Tutor account deactivated': 'Đã vô hiệu hóa tài khoản gia sư',
  'This tutor will not be able to login or receive new bookings. You should only do this if the report proof is serious enough.':
      'Gia sư này sẽ không thể đăng nhập hoặc nhận lịch đặt mới. Chỉ thực hiện khi bằng chứng báo cáo đủ nghiêm trọng.',
  'Booking': 'Đặt lịch',
  'Lesson': 'Buổi học',
  'Payout': 'Chi trả',
  'Admin Console': 'Bảng quản trị',
  'Key metrics': 'Chỉ số chính',
  'Downloads': 'Lượt tải',
  'Installs': 'Lượt cài đặt',
  'Pending tutors': 'Gia sư chờ duyệt',
  'Needs review': 'Cần xem xét',
  'Pending payouts': 'Chi trả chờ xử lý',
  'Action needed': 'Cần xử lý',
  'Revenue breakdown': 'Phân tích doanh thu',
  'Gross · platform 20% · tutor 80%': 'Tổng · nền tảng 20% · gia sư 80%',
  'Gross revenue': 'Tổng doanh thu',
  'Platform (20%)': 'Nền tảng (20%)',
  'Pending payout': 'Chi trả chờ xử lý',
  'Tutor verification status': 'Trạng thái xác minh gia sư',
  'Across all registered tutors': 'Trên tất cả gia sư đã đăng ký',
  'Lesson activity': 'Hoạt động buổi học',
  'Completed lessons total': 'Tổng số buổi học đã hoàn tất',
  'completed lessons': 'buổi học đã hoàn tất',
  'subjects active': 'môn học đang hoạt động',
  'Gross': 'Tổng',
  'Platform': 'Nền tảng',
  'Subject management': 'Quản lý môn học',
  'Create and review subjects that tutors can teach on the platform.':
      'Tạo và xem các môn học mà gia sư có thể dạy trên nền tảng.',
  'subjects': 'môn học',
  'Add new subject': 'Thêm môn học mới',
  'Keep names short and descriptions clear':
      'Giữ tên ngắn gọn và mô tả rõ ràng',
  'Subject name': 'Tên môn học',
  'Add subject': 'Thêm môn học',
  'Current subjects': 'Môn học hiện có',
  'Subjects available in the platform catalog':
      'Các môn học có trong danh mục nền tảng',
  'No subjects yet': 'Chưa có môn học',
  'Add your first subject above.': 'Thêm môn học đầu tiên ở phía trên.',
  'No description': 'Chưa có mô tả',
  'Subject name is required': 'Vui lòng nhập tên môn học',
  'Subject added': 'Đã thêm môn học',
  'Tutor verification': 'Xác minh gia sư',
  'Review submitted tutors, approve valid profiles, or reject incomplete applications.':
      'Xem gia sư đã nộp hồ sơ, duyệt hồ sơ hợp lệ hoặc từ chối hồ sơ chưa đầy đủ.',
  'tutors': 'gia sư',
  'No tutors found': 'Không tìm thấy gia sư',
  'Tutor accounts will appear here.': 'Tài khoản gia sư sẽ xuất hiện tại đây.',
  'Pending approval': 'Chờ phê duyệt',
  'No pending tutors.': 'Không có gia sư chờ duyệt.',
  'No rejected tutors.': 'Không có gia sư bị từ chối.',
  'No approved tutors.': 'Không có gia sư đã duyệt.',
  'Not submitted': 'Chưa nộp',
  'No not-submitted tutors.': 'Không có gia sư chưa nộp hồ sơ.',
  'Other status': 'Trạng thái khác',
  'No tutors in this group.': 'Không có gia sư trong nhóm này.',
  'CCCD': 'CCCD',
  'Bank': 'Ngân hàng',
  'Payout requests': 'Yêu cầu chi trả',
  'Approve tutor withdrawals with payOS Chi. If automatic payout fails, use the QR/manual backup.':
      'Duyệt rút tiền gia sư bằng payOS Chi. Nếu chi trả tự động thất bại, dùng QR/thủ công dự phòng.',
  'requests': 'yêu cầu',
  'No payouts': 'Không có chi trả',
  'Tutor payout requests will appear here.':
      'Yêu cầu chi trả của gia sư sẽ xuất hiện tại đây.',
  'Processing': 'Đang xử lý',
  'Manual QR required': 'Cần QR thủ công',
  'No pending payouts.': 'Không có chi trả chờ xử lý.',
  'No payOS Chi payouts are processing.':
      'Không có chi trả payOS Chi đang xử lý.',
  'No payouts need QR/manual backup.':
      'Không có chi trả cần QR/thủ công dự phòng.',
  'No paid payouts.': 'Không có chi trả đã thanh toán.',
  'No failed payouts.': 'Không có chi trả thất bại.',
  'No payouts in this group.': 'Không có chi trả trong nhóm này.',
  'Method': 'Phương thức',
  'Ref': 'Mã tham chiếu',
  'Issue': 'Sự cố',
  'ManualQr': 'QR thủ công',
  'Payout marked as': 'Đã đánh dấu chi trả là',
  'Payout approved. payOS Chi is processing.':
      'Đã duyệt chi trả. payOS Chi đang xử lý.',
  'Tutor receiving this payout': 'Gia sư nhận khoản chi trả này',
  'Tutor email': 'Email gia sư',
  'Bank account': 'Tài khoản ngân hàng',
  'Destination account for payOS Chi or QR/manual backup':
      'Tài khoản nhận cho payOS Chi hoặc QR/thủ công dự phòng',
  'Bank BIN': 'Mã BIN ngân hàng',
  'Account number': 'Số tài khoản',
  'Account holder name': 'Tên chủ tài khoản',
  'Payout information': 'Thông tin chi trả',
  'Amount, status, transfer content, and timestamps':
      'Số tiền, trạng thái, nội dung chuyển khoản và mốc thời gian',
  'Amount': 'Số tiền',
  'Transfer content': 'Nội dung chuyển khoản',
  'Requested at': 'Yêu cầu lúc',
  'Approved at': 'Duyệt lúc',
  'Paid at': 'Thanh toán lúc',
  'Processing...': 'Đang xử lý...',
  'Approve with payOS Chi': 'Duyệt bằng payOS Chi',
  'Mark payout as Paid manually?': 'Đánh dấu chi trả đã thanh toán thủ công?',
  'Only confirm this after you have successfully transferred money to the tutor bank account.':
      'Chỉ xác nhận sau khi bạn đã chuyển tiền thành công vào tài khoản ngân hàng của gia sư.',
  'Mark Paid manually': 'Đánh dấu đã thanh toán thủ công',
  'Mark payout as Failed?': 'Đánh dấu chi trả thất bại?',
  'The payout amount will be returned to the tutor wallet. This payout cannot be updated again after failing.':
      'Số tiền chi trả sẽ được hoàn về ví gia sư. Không thể cập nhật lại chi trả này sau khi đánh dấu thất bại.',
  'Mark Failed': 'Đánh dấu thất bại',
  'Only confirm this after you have verified the tutor received the money.':
      'Chỉ xác nhận sau khi bạn đã kiểm tra gia sư đã nhận tiền.',
  'Use this if payOS Chi failed and the amount should be returned to the tutor wallet.':
      'Dùng mục này nếu payOS Chi thất bại và cần hoàn tiền về ví gia sư.',
  'Confirm manual transfer?': 'Xác nhận chuyển khoản thủ công?',
  'Only confirm this after you have transferred the payout using QR/bank app.':
      'Chỉ xác nhận sau khi bạn đã chuyển khoản bằng QR/ứng dụng ngân hàng.',
  'I transferred manually': 'Tôi đã chuyển khoản thủ công',
  'The payout amount will be returned to the tutor wallet.':
      'Số tiền chi trả sẽ được hoàn về ví gia sư.',
  'Approve with payOS Chi?': 'Duyệt bằng payOS Chi?',
  'This will send the payout request to payOS Chi using the tutor bank information. If it fails, the backend will switch this payout to QR/manual backup.':
      'Thao tác này sẽ gửi yêu cầu chi trả đến payOS Chi bằng thông tin ngân hàng của gia sư. Nếu thất bại, backend sẽ chuyển khoản chi trả sang QR/thủ công dự phòng.',
  'I confirm this payout has been handled correctly.':
      'Tôi xác nhận khoản chi trả này đã được xử lý đúng.',
  'Automatic payout failed. Use QR/manual transfer backup.':
      'Chi trả tự động thất bại. Dùng QR/chuyển khoản thủ công dự phòng.',
  'Automatic payout tracking information': 'Thông tin theo dõi chi trả tự động',
  'Payout method': 'Phương thức chi trả',
  'Reference ID': 'Mã tham chiếu',
  'Batch / payout ID': 'Mã lô / chi trả',
  'Payout item ID': 'Mã mục chi trả',
  'Approval state': 'Trạng thái duyệt',
  'Transaction state': 'Trạng thái giao dịch',
  'Failure reason': 'Lý do thất bại',
  'payOS Chi is processing': 'payOS Chi đang xử lý',
  'Do not mark this as paid until you verify the payout result. If needed, you can manually confirm or fail the payout.':
      'Đừng đánh dấu đã thanh toán cho đến khi bạn xác minh kết quả chi trả. Nếu cần, bạn có thể xác nhận thủ công hoặc đánh dấu thất bại.',
  'QR/manual backup required': 'Cần QR/thủ công dự phòng',
  'Automatic payout failed. Scan the transfer QR or use the tutor bank information to transfer manually.':
      'Chi trả tự động thất bại. Quét QR chuyển khoản hoặc dùng thông tin ngân hàng của gia sư để chuyển thủ công.',
  'Automatic payout failed': 'Chi trả tự động thất bại',
  'Quick transfer QR': 'QR chuyển khoản nhanh',
  'QR is unavailable for this payout': 'Không có QR cho khoản chi trả này',
  'Enter the tutor bank BIN to enable quick money transfer QR.':
      'Nhập Bank BIN của gia sư để bật QR chuyển tiền nhanh.',
  'Scan this code to transfer payout money to the tutor':
      'Quét mã này để chuyển tiền chi trả cho gia sư',
  'Unable to load transfer QR': 'Không thể tải QR chuyển khoản',
  'Scan this QR to transfer payout money to the tutor.':
      'Quét QR này để chuyển tiền chi trả cho gia sư.',
  'Copy': 'Sao chép',
  'Copied': 'Đã sao chép',
  'Payout is Paid': 'Chi trả đã thanh toán',
  'This payout has been completed and cannot be updated again.':
      'Khoản chi trả này đã hoàn tất và không thể cập nhật lại.',
  'Payout is Failed': 'Chi trả thất bại',
  'The payout amount was returned to the tutor wallet. This payout cannot be updated again.':
      'Số tiền chi trả đã được hoàn về ví gia sư. Không thể cập nhật lại khoản chi trả này.',
  'Payout is': 'Chi trả đang',
  'No further action is available.': 'Không còn thao tác nào khác.',
  'Manage Reports': 'Quản lý báo cáo',
  'Search reports': 'Tìm báo cáo',
  'Search by title, category, reporter, booking...':
      'Tìm theo tiêu đề, danh mục, người báo cáo, lịch đặt...',
  'Search tutor, reporter, category, title, booking...':
      'Tìm gia sư, người báo cáo, danh mục, tiêu đề, lịch đặt...',
  'Support': 'Hỗ trợ',
  'Search tutor support reports': 'Tìm báo cáo hỗ trợ gia sư',
  'Tutor/User': 'Gia sư/Người dùng',
  'Verification': 'Xác minh',
  'Identity, account, and verification information':
      'Thông tin danh tính, tài khoản và xác minh',
  'Tutor ID': 'Mã gia sư',
  'User ID': 'Mã người dùng',
  'CCCD number': 'Số CCCD',
  'Not provided': 'Chưa cung cấp',
  'Reject reason': 'Lý do từ chối',
  'Used for admin payout verification':
      'Dùng để quản trị viên xác minh chi trả',
  'Bank name': 'Tên ngân hàng',
  'Account holder': 'Chủ tài khoản',
  'Branch': 'Chi nhánh',
  'This tutor can create availability and receive bookings while the account is active.':
      'Gia sư này có thể tạo lịch dạy và nhận đặt lịch khi tài khoản đang hoạt động.',
  'This tutor will be able to create availability and receive bookings.':
      'Gia sư này sẽ có thể tạo lịch dạy và nhận đặt lịch.',
  'Reason optional': 'Lý do (tùy chọn)',
  'Example: CCCD image is unclear': 'Ví dụ: ảnh CCCD không rõ',
  'Inappropriate behavior': 'Hành vi không phù hợp',
  'Did not attend lesson': 'Không tham gia buổi học',
  'Poor teaching quality': 'Chất lượng giảng dạy kém',
  'Wrong information': 'Thông tin sai',
  'Payment or booking issue': 'Vấn đề thanh toán hoặc đặt lịch',
  'Other': 'Khác',
  'Closed': 'Đã đóng',
  'open': 'đang mở',
  'proof': 'bằng chứng',
  'Report tutor': 'Báo cáo gia sư',
  'Describe the problem clearly so admin can review it faster.':
      'Mô tả rõ vấn đề để quản trị viên xem xét nhanh hơn.',
  'Brief summary of the issue': 'Tóm tắt ngắn gọn vấn đề',
  'Explain what happened and include important details':
      'Giải thích sự việc và thêm các chi tiết quan trọng',
  'Submit report': 'Gửi báo cáo',
  'Submit a tutor report': 'Gửi báo cáo gia sư',
  'Your report will be reviewed by the admin team with the proof images you provide.':
      'Báo cáo của bạn sẽ được đội ngũ quản trị xem xét cùng ảnh bằng chứng bạn cung cấp.',
  'Upload at least one image. Maximum 5 images.':
      'Tải lên ít nhất một ảnh. Tối đa 5 ảnh.',
  'No proof images selected': 'Chưa chọn ảnh bằng chứng',
  'Tap to add image proof for admin review.':
      'Nhấn để thêm ảnh bằng chứng cho quản trị viên xem xét.',
  'Tutor account is active': 'Tài khoản gia sư đang hoạt động',
  'Tutor account is deactivated': 'Tài khoản gia sư đã bị vô hiệu hóa',
  'This tutor can login and appear in available courses.':
      'Gia sư này có thể đăng nhập và xuất hiện trong các khóa học khả dụng.',
  'This tutor cannot login or receive new bookings.':
      'Gia sư này không thể đăng nhập hoặc nhận lịch đặt mới.',
  'This tutor will be able to login and use tutor features again.':
      'Gia sư này sẽ có thể đăng nhập và dùng lại tính năng gia sư.',
  'This tutor will not be able to login. Their courses should also be hidden from learners.':
      'Gia sư này sẽ không thể đăng nhập. Các khóa học của họ cũng nên được ẩn khỏi người học.',
  'No image submitted': 'Chưa gửi ảnh',
  'Unable to load image': 'Không thể tải ảnh',
  'Explain the result to the tutor': 'Giải thích kết quả cho gia sư',
  'Report Issue to Admin': 'Báo cáo sự cố cho quản trị viên',
  'Use this form for tutor problems such as missing payment, slow payout, wrong wallet balance, student no-show, booking issue, or app bug.':
      'Dùng biểu mẫu này cho các vấn đề của gia sư như thiếu thanh toán, chi trả chậm, sai số dư ví, học sinh không tham gia, lỗi đặt lịch hoặc lỗi ứng dụng.',
  'Issue category': 'Danh mục sự cố',
  'Missing payment': 'Thiếu thanh toán',
  'Slow payout': 'Chi trả chậm',
  'Wrong wallet balance': 'Sai số dư ví',
  'Lesson issue': 'Sự cố buổi học',
  'Student no-show': 'Học sinh không tham gia',
  'Booking issue': 'Sự cố đặt lịch',
  'App bug': 'Lỗi ứng dụng',
  'Account issue': 'Sự cố tài khoản',
  'Example: My completed lesson was not paid':
      'Ví dụ: Buổi học đã hoàn tất của tôi chưa được thanh toán',
  'Describe the problem clearly for admin':
      'Mô tả rõ vấn đề để quản trị viên xử lý',
  'Related IDs optional': 'Mã liên quan (tùy chọn)',
  'Payout ID optional': 'Mã chi trả (tùy chọn)',
  'Booking ID optional': 'Mã đặt lịch (tùy chọn)',
  'Lesson ID optional': 'Mã buổi học (tùy chọn)',
  'Submit to Admin': 'Gửi cho quản trị viên',
  'Issue report submitted': 'Đã gửi báo cáo sự cố',
  'Proof images optional': 'Ảnh bằng chứng (tùy chọn)',
  'Upload screenshots of wallet, payout, booking, lesson, or app errors.':
      'Tải ảnh chụp màn hình ví, chi trả, đặt lịch, buổi học hoặc lỗi ứng dụng.',
  'Add proof images': 'Thêm ảnh bằng chứng',
  'Could not pick images': 'Không thể chọn ảnh',
  'No reports found': 'Không tìm thấy báo cáo',
  'Reports submitted by learners about your tutoring sessions will appear here.':
      'Báo cáo do người học gửi về các buổi dạy của bạn sẽ xuất hiện tại đây.',
  'Unknown subject': 'Chưa rõ môn học',
  'Reviewed': 'Đã xem xét',
  'Waiting for admin review.': 'Đang chờ quản trị viên xem xét.',
  'Admin is reviewing the evidence.': 'Quản trị viên đang xem xét bằng chứng.',
  'The report has been processed.': 'Báo cáo đã được xử lý.',
  'The report was rejected.': 'Báo cáo đã bị từ chối.',
  'Current status': 'Trạng thái hiện tại',
  'No related IDs provided': 'Chưa có mã liên quan',
  'Waiting for admin to review.': 'Đang chờ quản trị viên xem xét.',
  'Admin is checking your issue.': 'Quản trị viên đang kiểm tra sự cố của bạn.',
  'Admin has resolved this issue.': 'Quản trị viên đã xử lý sự cố này.',
  'Admin rejected this report.': 'Quản trị viên đã từ chối báo cáo này.',
  'Report center': 'Trung tâm báo cáo',
  'Track tutor reports by review stage, category, proof, and admin response.':
      'Theo dõi báo cáo gia sư theo trạng thái xem xét, danh mục, bằng chứng và phản hồi của quản trị viên.',
  'No reports yet': 'Chưa có báo cáo',
  'Reports you submit about tutors will appear here with review progress.':
      'Báo cáo bạn gửi về gia sư sẽ xuất hiện tại đây cùng tiến độ xử lý.',
  'Last update': 'Cập nhật cuối',
  'Waiting': 'Đang chờ',
  'Could not load image': 'Không thể tải ảnh',
  'Payment': 'Thanh toán',
  'Check payment': 'Kiểm tra thanh toán',
  'Payment link is empty': 'Liên kết thanh toán đang trống',
  'Invalid payment link': 'Liên kết thanh toán không hợp lệ',
  'Could not open payment link': 'Không thể mở liên kết thanh toán',
  'Payment status': 'Trạng thái thanh toán',
  'Leave payment screen?': 'Rời màn hình thanh toán?',
  'If you already paid, tap "I have paid / Check payment" before leaving so EduNest can confirm your booking and create lessons.':
      'Nếu bạn đã thanh toán, hãy nhấn "Tôi đã thanh toán / Kiểm tra thanh toán" trước khi rời đi để EduNest xác nhận đặt lịch và tạo buổi học.',
  'Stay': 'Ở lại',
  'Leave anyway': 'Vẫn rời đi',
  'Provider': 'Nhà cung cấp',
  'Payment completed': 'Thanh toán hoàn tất',
  'Scan QR to pay': 'Quét QR để thanh toán',
  'QR code is empty. Check backend PayOS configuration.':
      'Mã QR đang trống. Vui lòng kiểm tra cấu hình PayOS ở backend.',
  'Open payment link': 'Mở liên kết thanh toán',
  'I have paid / Check payment': 'Tôi đã thanh toán / Kiểm tra thanh toán',
  'Your booking is confirmed. Lessons have been created.':
      'Đặt lịch của bạn đã được xác nhận. Các buổi học đã được tạo.',
  'After transferring money, tap "I have paid / Check payment" to sync PayOS status and create lessons.':
      'Sau khi chuyển tiền, nhấn "Tôi đã thanh toán / Kiểm tra thanh toán" để đồng bộ trạng thái PayOS và tạo buổi học.',
};

extension AppStringsX on BuildContext {
  AppStrings get l10n => AppStrings.of(this);
}
