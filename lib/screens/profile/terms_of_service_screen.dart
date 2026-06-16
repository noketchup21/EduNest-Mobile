import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final terms = t.isVi ? _viTerms : _enTerms;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.termsOfService),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Header(
            title: t.isVi ? 'ĐIỀU KHOẢN DỊCH VỤ' : 'TERMS OF SERVICE',
            intro: t.isVi
                ? 'Bằng việc đăng ký, truy cập hoặc sử dụng EduNest, bạn xác nhận đã đọc, hiểu và đồng ý với các điều khoản này, bao gồm cách EduNest thu thập và xử lý dữ liệu.'
                : 'By registering, accessing, or using EduNest, you confirm that you have read, understood, and agreed to these Terms of Service, including our data collection and privacy practices.',
          ),
          const SizedBox(height: 12),
          ...terms.map((term) => _TermSection(term: term)),
          const SizedBox(height: 24),
          Text(
            t.isVi
                ? 'Vui lòng đọc kỹ Điều khoản dịch vụ của EduNest trước khi sử dụng nền tảng.'
                : 'Please read and review the EduNest Terms of Service carefully before using the platform.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String intro;

  const _Header({
    required this.title,
    required this.intro,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text('${t.isVi ? 'Nền tảng' : 'Platform'}: EduNest'),
            Text(t.isVi
                ? 'Ngày hiệu lực: [Nhập ngày hiệu lực]'
                : 'Effective Date: [Enter effective date]'),
            Text(t.isVi
                ? 'Đơn vị vận hành: [Nhóm/Công ty/Cá nhân]'
                : 'Operated by: [Team/Company/Individual name]'),
            Text(t.isVi
                ? 'Email hỗ trợ: [Email hỗ trợ]'
                : 'Support Email: [Support email]'),
            const SizedBox(height: 12),
            Text(intro),
          ],
        ),
      ),
    );
  }
}

class _TermSection extends StatelessWidget {
  final _Term term;

  const _TermSection({required this.term});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              term.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              term.body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                    letterSpacing: 0,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Term {
  final String title;
  final String body;

  const _Term(this.title, this.body);
}

const _viTerms = [
  _Term(
    '1. Giới thiệu về EduNest',
    'EduNest là nền tảng kết nối người học với gia sư. Người dùng có thể tìm khóa học, đặt lịch, thanh toán, tham gia buổi học, theo dõi điểm danh, trò chuyện và gửi báo cáo khi có sự cố. Gia sư là nhà cung cấp dịch vụ giáo dục độc lập trên nền tảng.',
  ),
  _Term(
    '2. Vai trò người dùng',
    'EduNest có các vai trò chính: phụ huynh/học sinh, gia sư và quản trị viên. Người học có thể đặt lịch và thanh toán. Gia sư có thể tạo khóa học sau khi được xác minh và phê duyệt. Quản trị viên xử lý duyệt gia sư, báo cáo, yêu cầu rút tiền và vi phạm.',
  ),
  _Term(
    '3. Đăng ký tài khoản và xác minh email',
    'Người dùng phải đăng ký bằng email hợp lệ và xác minh email trước khi sử dụng đầy đủ tính năng. Người dùng chịu trách nhiệm bảo mật thông tin đăng nhập và mọi hoạt động dưới tài khoản của mình.',
  ),
  _Term(
    '4. Xóa tài khoản và dữ liệu',
    'Người dùng có quyền yêu cầu xóa tài khoản và dữ liệu cá nhân. Dữ liệu sẽ được xóa hoặc ẩn danh trong thời hạn hợp lý, trừ khi cần lưu giữ theo pháp luật, phòng chống gian lận hoặc hoàn tất giao dịch đang chờ.',
  ),
  _Term(
    '5. Yêu cầu đối với gia sư',
    'Gia sư phải cung cấp thông tin chính xác, bao gồm thông tin cá nhân, giấy tờ định danh, chứng chỉ liên quan và thông tin ngân hàng. Cung cấp thông tin sai lệch có thể dẫn đến đình chỉ tài khoản.',
  ),
  _Term(
    '6. Tạo khóa học và lịch học',
    'Gia sư đã được duyệt có thể tạo khóa học với môn học, trình độ, hình thức học, ngày học, thời gian, số buổi và học phí. Gia sư chịu trách nhiệm đảm bảo thông tin chính xác và khả thi.',
  ),
  _Term(
    '7. Đặt lịch và thanh toán',
    'Người học cần kiểm tra kỹ thông tin khóa học trước khi đặt lịch. Thanh toán có thể được xử lý qua PayOS, VietQR hoặc phương thức tích hợp khác. Khi thanh toán được xác nhận, hệ thống cập nhật trạng thái và tạo các buổi học tương ứng.',
  ),
  _Term(
    '8. Hủy lịch, hoàn tiền và tranh chấp',
    'Việc hủy lịch, hoàn tiền hoặc xử lý tranh chấp phụ thuộc trạng thái đặt lịch, thời điểm buổi học và bằng chứng liên quan. EduNest có thể từ chối hoàn tiền khi buổi học đã diễn ra hoặc yêu cầu không có căn cứ hợp lệ.',
  ),
  _Term(
    '9. Buổi học và điểm danh',
    'Gia sư chịu trách nhiệm cung cấp liên kết học, tham gia đúng giờ, điểm danh học sinh và hoàn tất buổi học. Người học chịu trách nhiệm tham gia đúng giờ, chuẩn bị thiết bị và thông báo trước nếu không thể tham gia.',
  ),
  _Term(
    '10. Ví gia sư và rút tiền',
    'Sau khi buổi học hợp lệ được hoàn tất, thu nhập sẽ được ghi nhận vào ví gia sư. Gia sư có thể gửi yêu cầu rút tiền về tài khoản ngân hàng đã đăng ký. EduNest có thể tạm giữ hoặc điều chỉnh thu nhập khi có tranh chấp, báo cáo, gian lận hoặc lỗi hệ thống.',
  ),
  _Term(
    '11. Trò chuyện và giao tiếp',
    'Tính năng trò chuyện chỉ phục vụ mục đích học tập. Người dùng không được quấy rối, lăng mạ, đe dọa, spam, gian lận, trao đổi nội dung trái pháp luật hoặc yêu cầu thanh toán ngoài nền tảng.',
  ),
  _Term(
    '12. Báo cáo và xử lý vi phạm',
    'Người học có thể gửi báo cáo khi có sự cố với gia sư hoặc buổi học. Báo cáo cần trung thực và có bằng chứng phù hợp. Báo cáo sai sự thật hoặc nhằm gây hại có thể dẫn đến hạn chế tài khoản.',
  ),
  _Term(
    '13. Tài liệu học tập',
    'Gia sư chịu trách nhiệm đảm bảo tài liệu tải lên không vi phạm bản quyền, không chứa nội dung độc hại hoặc không phù hợp. Người học không được sao chép hoặc phân phối lại tài liệu ngoài mục đích học cá nhân nếu chưa được phép.',
  ),
  _Term(
    '14. Dữ liệu cá nhân và bảo mật',
    'EduNest thu thập dữ liệu tài khoản, xác minh gia sư, giao dịch, trò chuyện, báo cáo và dữ liệu sử dụng để vận hành nền tảng, xử lý thanh toán, giải quyết tranh chấp và bảo mật hệ thống. EduNest không bán dữ liệu cá nhân cho bên thứ ba vì mục đích quảng cáo.',
  ),
  _Term(
    '15. Dịch vụ bên thứ ba',
    'EduNest có thể sử dụng PayOS, VietQR, Cloudinary, Render và dịch vụ email để vận hành nền tảng. Các nhà cung cấp này xử lý dữ liệu theo mục đích cung cấp dịch vụ và chính sách riêng của họ.',
  ),
  _Term(
    '16. Tạm khóa hoặc chấm dứt tài khoản',
    'EduNest có quyền tạm khóa hoặc chấm dứt tài khoản khi người dùng vi phạm điều khoản, cung cấp thông tin sai, gian lận, gây hại cho người khác, lạm dụng nền tảng hoặc vi phạm pháp luật.',
  ),
  _Term(
    '17. Luật áp dụng và giải quyết tranh chấp',
    'Các điều khoản này được điều chỉnh bởi pháp luật Việt Nam. Tranh chấp sẽ được ưu tiên giải quyết thông qua thương lượng; nếu không thể giải quyết, có thể chuyển đến cơ quan có thẩm quyền theo quy định pháp luật.',
  ),
  _Term(
    '18. Liên hệ',
    'Nếu có câu hỏi về Điều khoản dịch vụ hoặc dữ liệu cá nhân, vui lòng liên hệ email hỗ trợ được hiển thị trong ứng dụng. EduNest sẽ cố gắng phản hồi trong thời gian sớm nhất.',
  ),
];

const _enTerms = [
  _Term(
    '1. Introduction to EduNest',
    'EduNest connects learners with tutors. Users can search for courses, schedule sessions, make payments, attend lessons, track attendance, chat, and submit reports when issues arise. Tutors are independent education providers on the platform.',
  ),
  _Term(
    '2. User Roles',
    'EduNest supports parent/student, tutor, and administrator roles. Learners can book and pay. Tutors can create courses after verification and approval. Administrators review tutors, reports, payouts, and account violations.',
  ),
  _Term(
    '3. Accounts and Email Verification',
    'Users must register with a valid email and verify it before using full platform features. Users are responsible for account security and all activity under their account.',
  ),
  _Term(
    '4. Account and Data Deletion',
    'Users may request deletion of their account and personal data. Data will be deleted or anonymized within a reasonable period except where retention is required by law, fraud prevention, or pending transactions.',
  ),
  _Term(
    '5. Tutors',
    'Tutors must provide accurate personal, identity, credential, and bank information. False or misleading verification information may result in account suspension.',
  ),
  _Term(
    '6. Courses and Schedules',
    'Approved tutors may create courses with subject, level, format, schedule, number of sessions, and tuition. Tutors are responsible for accurate and feasible course information.',
  ),
  _Term(
    '7. Bookings and Payments',
    'Learners should review course details before booking. Payments may be processed through PayOS, VietQR, or other integrated methods. Confirmed payment updates booking status and creates lesson sessions.',
  ),
  _Term(
    '8. Cancellations, Refunds, and Disputes',
    'Cancellations, refunds, and disputes depend on booking status, lesson timing, and supporting evidence. EduNest may refuse refunds when a lesson has occurred or the request lacks valid evidence.',
  ),
  _Term(
    '9. Lessons and Attendance',
    'Tutors provide lesson links, attend on time, record attendance, and complete lessons. Learners join on time, prepare devices, and notify tutors in advance when unable to attend.',
  ),
  _Term(
    '10. Tutor Wallet and Withdrawals',
    'Tutor earnings are credited after valid lesson completion. Tutors may request withdrawals to registered bank accounts. EduNest may hold or adjust earnings during disputes, reports, fraud checks, or system errors.',
  ),
  _Term(
    '11. Chat and Communication',
    'Chat is for educational purposes only. Users must not harass, threaten, spam, commit fraud, exchange illegal content, or request off-platform payments.',
  ),
  _Term(
    '12. Reports and Enforcement',
    'Learners may submit reports with truthful information and evidence. False or harmful reports may result in account restrictions.',
  ),
  _Term(
    '13. Learning Materials',
    'Tutors must ensure uploaded materials do not infringe copyright or contain harmful content. Learners may not redistribute materials beyond personal study without permission.',
  ),
  _Term(
    '14. Personal Data and Security',
    'EduNest processes account, verification, transaction, chat, report, and usage data to operate the platform, process payments, resolve disputes, and protect security. EduNest does not sell personal data for advertising.',
  ),
  _Term(
    '15. Third-Party Services',
    'EduNest may use PayOS, VietQR, Cloudinary, Render, and email services. These providers process data for service delivery and under their own policies.',
  ),
  _Term(
    '16. Suspension or Termination',
    'EduNest may suspend or terminate accounts for terms violations, false information, fraud, harm to others, platform abuse, or legal violations.',
  ),
  _Term(
    '17. Governing Law and Disputes',
    'These terms are governed by Vietnamese law. Disputes should first be resolved through negotiation and may be referred to competent authorities when necessary.',
  ),
  _Term(
    '18. Contact',
    'For questions about these terms or personal data, contact the support email listed in the app. EduNest will respond as soon as reasonably possible.',
  ),
];
