import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _Header(),
          SizedBox(height: 12),
          _TermSection(
            title: '1. Introduction to EduNest',
            body: 'EduNest is a platform that connects learners with tutors. '
                'Users can search for courses, schedule sessions, make payments, attend lessons, '
                'track attendance, chat with tutors, and submit reports when issues arise. '
                'EduNest is not a direct teaching provider unless otherwise stated. '
                'Tutors are independent service providers offering educational services through the platform.',
          ),
          _TermSection(
            title: '2. User Roles',
            body:
                'EduNest has three main roles: parent/student, tutor, and administrator. '
                'Parent/Student can book sessions and make payments. Tutors can create courses after being verified. '
                'Administrators have the authority to approve tutors, handle reports, manage withdrawal requests, and take action on accounts that violate the rules.',
          ),
          _TermSection(
            title: '3. Account & Email Verification',
            body:
                'Users must register with a valid email address and verify it before accessing full platform features. '
                'Users are responsible for securing their account, password, and all activities that occur under their account. '
                'EduNest reserves the right to suspend or disable accounts found to be fraudulent, impersonating others, or in violation of these terms.',
          ),
          _TermSection(
            title: '4. Requirements for Tutors',
            body:
                'Tutors must provide accurate information, including personal details, national ID (CCCD/CMND), front and back photos of their identification document, '
                'relevant certificates or credentials, bank account information, and any other required data. '
                'Tutors may only create courses after their profile has been approved by an administrator.',
          ),
          _TermSection(
            title: '5. Tutor Approval or Rejection',
            body:
                'Administrators have the right to approve, reject, or request additional documentation from tutor applicants. '
                'A profile may be rejected for reasons including missing documents, unclear photos, invalid banking details, '
                'mismatched personal information, or signs of fraudulent submission. '
                'Rejected tutors may resubmit their profile if the system permits.',
          ),
          _TermSection(
            title: '6. Creating Courses & Schedules',
            body:
                'Approved tutors may create courses with details such as subject, level, teaching format, days of the week, '
                'start time, end time, course start date, course end date, number of sessions, and price per session. '
                'Tutors are responsible for ensuring that course information is accurate, feasible, and consistent with their teaching capabilities.',
          ),
          _TermSection(
            title: '7. Booking a Session',
            body:
                'Learners should carefully review the subject name, tutor, schedule, number of sessions, tuition fee, teaching format, and other course details before booking. '
                'Bookings may have the following statuses: Pending, Confirmed, Completed, Cancelled, Expired, or Failed. '
                'Unpaid bookings may be cancelled or expired according to system policy.',
          ),
          _TermSection(
            title: '8. Payments',
            body:
                'EduNest may support payment via PayOS, VietQR, or other integrated methods. '
                'Learners must pay the correct amount, use the correct transaction reference, and complete payment within the specified timeframe. '
                'Once payment is confirmed, the system will update the booking status and generate the corresponding lesson sessions.',
          ),
          _TermSection(
            title: '9. Booking Cancellation & Refunds',
            body:
                'Learners may cancel a booking while it is still in a cancellable status, such as Pending. '
                'For bookings that have been paid or confirmed, cancellations, refunds, or dispute resolution are subject to EduNest\'s current policies '
                'and the actual status of the course. EduNest reserves the right to refuse a refund if a session has already taken place, the learner was absent despite the tutor being present, '
                'or the refund request lacks valid supporting evidence.',
          ),
          _TermSection(
            title: '10. Lessons & Attendance',
            body:
                'Once a booking is confirmed, the system will generate the corresponding lesson sessions. Tutors are responsible for providing lesson links or session information on time, '
                'being present punctually, recording student attendance, and marking sessions as completed after they conclude. Learners are responsible for joining on time, preparing their devices, '
                'ensuring a stable internet connection, and notifying the tutor in advance if they are unable to attend.',
          ),
          _TermSection(
            title: '11. Tutor Wallet & Earnings',
            body:
                'After a lesson session is validly marked as completed, the earnings will be credited to the tutor\'s wallet. '
                'Under the current model, tutors receive 90% of the revenue and the platform retains 10% as a service fee. '
                'EduNest reserves the right to hold or adjust earnings if there are disputes, reports, fraudulent activity, or system errors.',
          ),
          _TermSection(
            title: '12. Tutor Withdrawals',
            body:
                'Tutors may submit withdrawal requests to transfer funds from their wallet to their registered bank account. '
                'Withdrawal details include the bank name, bank code/BIN, account number, account holder name, and the amount to withdraw. '
                'Withdrawal requests may be processed automatically via a payment partner or manually by an administrator. '
                'If a withdrawal fails, the amount will be returned to the tutor\'s wallet.',
          ),
          _TermSection(
            title: '13. Chat & Communication',
            body:
                'EduNest may provide a chat feature between learners and tutors. Users must not use the chat to harass, insult, threaten, spam, '
                'commit fraud, exchange illegal content, or solicit payments outside the platform. EduNest reserves the right to review and take action on accounts that violate these rules.',
          ),
          _TermSection(
            title: '14. Reporting a Tutor',
            body:
                'Learners who have booked sessions with a tutor may submit a report if an issue arises. Reports may include the issue type, title, detailed description, '
                'related booking, related lesson session, and supporting images. Report submitters must provide truthful information and valid evidence. '
                'False reports or reports intended to cause harm may result in account restrictions.',
          ),
          _TermSection(
            title: '15. Report Processing',
            body:
                'Report statuses may include Pending, Reviewing, Resolved, and Rejected. Pending means the report has just been submitted. Reviewing means it is being examined by an administrator. '
                'Resolved means the report has been fully processed. Rejected means the report was dismissed due to being invalid or lacking sufficient evidence. '
                'A Resolved status does not automatically result in the tutor\'s account being disabled.',
          ),
          _TermSection(
            title: '16. Activating & Deactivating Tutor Accounts',
            body:
                'Administrators have the right to activate or deactivate tutor accounts based on profile review, reports, usage behavior, or risks to the platform. '
                'A tutor\'s account may be deactivated due to serious reports, failure to attend paid sessions, fraud, submission of false information, '
                'violation of conduct guidelines, or deliberately directing learners to pay outside the platform.',
          ),
          _TermSection(
            title: '17. Learning Content & Materials',
            body:
                'Tutors are responsible for ensuring that learning materials do not infringe on copyrights, do not contain harmful content, and are appropriate for educational purposes. '
                'Learners may not copy, redistribute, or use tutor materials beyond personal study purposes without prior permission.',
          ),
          _TermSection(
            title: '18. Prohibited Conduct',
            body:
                'Users must not impersonate others, provide false information, commit payment fraud, attack the system, abuse the reporting feature, '
                'harass other users, post offensive content, create multiple accounts to manipulate the system, or make payments outside the platform to avoid service fees.',
          ),
          _TermSection(
            title: '19. Personal Data & Privacy',
            body:
                'EduNest may collect and process full names, email addresses, phone numbers, user roles, tutor verification information, bank account details, '
                'booking and payment information, chat messages, report images, and app usage data. '
                'This data is used to manage accounts, verify tutors, process bookings, handle payments, withdrawals, reports, disputes, and maintain platform security.',
          ),
          _TermSection(
            title: '20. Storage of Images & Documents',
            body:
                'Certain images, such as tutor verification documents or report evidence, may be stored on third-party cloud services. '
                'EduNest will implement appropriate measures to restrict unauthorized access to sensitive images. '
                'Users must not upload images that violate the law or are unrelated to the verification or reporting process.',
          ),
          _TermSection(
            title: '21. Third-Party Services',
            body:
                'EduNest may integrate with third-party services such as PayOS, VietQR, Cloudinary, Render, Firebase, or equivalent providers. '
                'Use of these services may be subject to additional terms and conditions from the respective third parties. EduNest does not have full control over the operations, errors, or policies of these third parties.',
          ),
          _TermSection(
            title: '22. Limitation of Liability',
            body:
                'To the extent permitted by law, EduNest is not liable for losses arising from incorrect user-entered information, off-platform payments, '
                'personal disputes outside the platform, misconduct by other users, device failures, network errors, third-party service issues, or indirect damages.',
          ),
          _TermSection(
            title: '23. Account Suspension or Termination',
            body:
                'EduNest reserves the right to suspend or terminate accounts if users violate these terms, provide false information, engage in fraudulent activity, '
                'harm other users, abuse the platform, or violate applicable laws.',
          ),
          _TermSection(
            title: '24. Changes to Terms',
            body:
                'EduNest reserves the right to update these Terms of Service at any time. When significant changes are made, EduNest may notify users via the app, email, or other appropriate means. '
                'Continued use of the platform after the updated terms take effect constitutes the user\'s acceptance of the new terms.',
          ),
          _TermSection(
            title: '25. Governing Law & Dispute Resolution',
            body:
                'These terms are governed by the laws of Vietnam, unless otherwise specified. '
                'Any disputes arising will be prioritized for resolution through negotiation between the user and EduNest. '
                'If a dispute cannot be resolved through negotiation, it may be referred to the competent authorities in accordance with applicable law.',
          ),
          _TermSection(
            title: '26. User Acknowledgment',
            body:
                'By creating an account, logging in, making a booking, completing a payment, teaching a session, requesting a withdrawal, or using any feature of EduNest, '
                'users confirm that they have read, understood, and agreed to comply with these Terms of Service.',
          ),
          SizedBox(height: 24),
          _Footer(),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TERMS OF SERVICE',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            const Text('Platform: EduNest'),
            const Text('Effective Date: [Enter effective date]'),
            const Text('Operated by: [Team/Company/Individual name]'),
            const Text('Support Email: [Support email]'),
            const SizedBox(height: 12),
            const Text(
              'By registering, accessing, or using EduNest, users confirm that they have read, understood, and agreed to these terms.',
            ),
          ],
        ),
      ),
    );
  }
}

class _TermSection extends StatelessWidget {
  final String title;
  final String body;

  const _TermSection({
    required this.title,
    required this.body,
  });

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
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              body,
              textAlign: TextAlign.start,
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

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Note: Read and review Edunest Terms of Service before using the platform.',
      style: Theme.of(context).textTheme.bodySmall,
      textAlign: TextAlign.center,
    );
  }
}
