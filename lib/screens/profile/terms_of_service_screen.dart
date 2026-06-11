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
            body:
            'EduNest is a platform that connects learners with tutors. '
                'Users can search for courses, schedule sessions, make payments, attend lessons, '
                'track attendance, chat with tutors, and submit reports when issues arise. '
                'EduNest is not a direct teaching provider unless otherwise stated. '
                'Tutors are independent service providers offering educational services through the platform.',
          ),
          _TermSection(
            title: '2. User Roles',
            body:
            'EduNest has three main roles: parent/student, tutor, and administrator. '
                'Parent/Student accounts can book sessions and make payments. '
                'Tutors can create courses after being verified and approved. '
                'Administrators have the authority to approve tutors, handle reports, manage withdrawal requests, '
                'and take action on accounts that violate these terms.',
          ),
          _TermSection(
            title: '3. Account Registration & Email Verification',
            body:
            'Users must register with a valid email address and verify it before accessing full platform features. '
                'Users are responsible for maintaining the security of their account credentials and for all activities '
                'that occur under their account. '
                'EduNest reserves the right to suspend or disable accounts found to be fraudulent, '
                'impersonating others, or in violation of these terms. '
                'Users must be at least 13 years of age to register. Users under 18 must have parental or guardian consent.',
          ),
          _TermSection(
            title: '4. Account Deletion',
            body:
            'Users have the right to request deletion of their account and associated personal data at any time. '
                'Account deletion requests can be submitted through the app settings under "Account" > "Delete Account", '
                'or by contacting our support email. '
                'Upon deletion, personal data will be removed or anonymized within 30 days, except where retention '
                'is required by law, for fraud prevention, or to complete pending transactions. '
                'Certain transaction records may be retained for legal and financial compliance purposes '
                'even after account deletion.',
          ),
          _TermSection(
            title: '5. Requirements for Tutors',
            body:
            'Tutors must provide accurate information, including personal details, national ID (CCCD/CMND), '
                'front and back photos of their identification document, relevant certificates or credentials, '
                'bank account information, and any other required data. '
                'Tutors may only create courses after their profile has been approved by an administrator. '
                'Providing false or misleading information during tutor verification is a violation of these terms '
                'and may result in permanent account suspension.',
          ),
          _TermSection(
            title: '6. Tutor Approval or Rejection',
            body:
            'Administrators have the right to approve, reject, or request additional documentation from tutor applicants. '
                'A profile may be rejected for reasons including missing documents, unclear photos, invalid banking details, '
                'mismatched personal information, or signs of fraudulent submission. '
                'Rejected tutors may resubmit their profile if the system permits.',
          ),
          _TermSection(
            title: '7. Creating Courses & Schedules',
            body:
            'Approved tutors may create courses with details such as subject, level, teaching format, days of the week, '
                'start time, end time, course start date, course end date, number of sessions, and price per session. '
                'Tutors are responsible for ensuring that course information is accurate, feasible, and consistent with '
                'their teaching capabilities.',
          ),
          _TermSection(
            title: '8. Booking a Session',
            body:
            'Learners should carefully review all course details before booking, including subject name, tutor, '
                'schedule, number of sessions, tuition fee, and teaching format. '
                'Bookings may carry the following statuses: Pending, Confirmed, Completed, Cancelled, Expired, or Failed. '
                'Unpaid bookings may be automatically cancelled or expired according to system policy.',
          ),
          _TermSection(
            title: '9. Payments',
            body:
            'EduNest may support payment via PayOS, VietQR, or other integrated methods. '
                'Learners must pay the correct amount, use the correct transaction reference, and complete payment '
                'within the specified timeframe. '
                'Once payment is confirmed, the system will update the booking status and generate the corresponding '
                'lesson sessions. All payment processing is handled by third-party providers subject to their own terms.',
          ),
          _TermSection(
            title: '10. Booking Cancellation & Refunds',
            body:
            'Learners may cancel a booking while it is still in a cancellable status, such as Pending. '
                'For bookings that have been paid or confirmed, cancellations, refunds, or dispute resolution are '
                'subject to EduNest\'s current policies and the actual status of the course. '
                'EduNest reserves the right to refuse a refund if a session has already taken place, '
                'the learner was absent despite the tutor being present, '
                'or the refund request lacks valid supporting evidence.',
          ),
          _TermSection(
            title: '11. Lessons & Attendance',
            body:
            'Once a booking is confirmed, the system will generate the corresponding lesson sessions. '
                'Tutors are responsible for providing lesson links or session information on time, '
                'being present punctually, recording student attendance, and marking sessions as completed. '
                'Learners are responsible for joining on time, preparing their devices, '
                'ensuring a stable internet connection, and notifying the tutor in advance if they are unable to attend.',
          ),
          _TermSection(
            title: '12. Tutor Wallet & Earnings',
            body:
            'After a lesson session is validly marked as completed, the earnings will be credited to the tutor\'s wallet. '
                'Under the current model, tutors receive 90% of the revenue and the platform retains 10% as a service fee. '
                'EduNest reserves the right to hold or adjust earnings if there are disputes, reports, '
                'fraudulent activity, or system errors.',
          ),
          _TermSection(
            title: '13. Tutor Withdrawals',
            body:
            'Tutors may submit withdrawal requests to transfer funds from their wallet to their registered bank account. '
                'Required withdrawal details include the bank name, bank code/BIN, account number, account holder name, '
                'and the amount to withdraw. '
                'Withdrawal requests may be processed automatically via a payment partner or manually by an administrator. '
                'If a withdrawal fails, the amount will be returned to the tutor\'s wallet.',
          ),
          _TermSection(
            title: '14. Chat & Communication',
            body:
            'EduNest may provide a chat feature between learners and tutors for educational purposes only. '
                'Users must not use the chat to harass, insult, threaten, spam, commit fraud, '
                'exchange illegal content, or solicit payments outside the platform. '
                'EduNest reserves the right to review and take action on accounts that violate these rules.',
          ),
          _TermSection(
            title: '15. Reporting a Tutor',
            body:
            'Learners who have booked sessions with a tutor may submit a report if an issue arises. '
                'Reports may include the issue type, title, detailed description, related booking, related lesson session, '
                'and supporting images. Report submitters must provide truthful information and valid evidence. '
                'False reports or reports intended to cause harm may result in account restrictions.',
          ),
          _TermSection(
            title: '16. Report Processing',
            body:
            'Report statuses may include Pending, Reviewing, Resolved, and Rejected. '
                'Pending means the report has just been submitted. Reviewing means it is being examined by an administrator. '
                'Resolved means the report has been fully processed. '
                'Rejected means the report was dismissed due to being invalid or lacking sufficient evidence. '
                'A Resolved status does not automatically result in the tutor\'s account being disabled.',
          ),
          _TermSection(
            title: '17. Activating & Deactivating Tutor Accounts',
            body:
            'Administrators have the right to activate or deactivate tutor accounts based on profile review, '
                'reports, usage behavior, or risks to the platform. '
                'A tutor\'s account may be deactivated due to serious reports, failure to attend paid sessions, fraud, '
                'submission of false information, violation of conduct guidelines, '
                'or deliberately directing learners to pay outside the platform.',
          ),
          _TermSection(
            title: '18. Learning Content & Materials',
            body:
            'Tutors are responsible for ensuring that all uploaded learning materials do not infringe on copyrights, '
                'do not contain harmful or inappropriate content, and are appropriate for educational purposes. '
                'Learners may not copy, redistribute, or use tutor-provided materials beyond personal study '
                'without prior written permission from the tutor.',
          ),
          _TermSection(
            title: '19. Prohibited Conduct',
            body:
            'Users must not impersonate others, provide false information, commit payment fraud, attack the system, '
                'abuse the reporting feature, harass other users, post offensive or illegal content, '
                'create multiple accounts to manipulate the system, or make payments outside the platform '
                'to avoid service fees. Violations may result in immediate account suspension or termination.',
          ),
          _TermSection(
            title: '20. Children\'s Privacy',
            body:
            'EduNest does not knowingly collect personal data from children under the age of 13 without verified '
                'parental or guardian consent. Users aged 13–17 must have parental or guardian consent to register and use the platform. '
                'If we become aware that personal data has been collected from a child under 13 without proper consent, '
                'we will delete that data promptly. Parents or guardians who believe their child\'s data has been '
                'collected in error should contact us at the support email listed in the app.',
          ),
          _TermSection(
            title: '21. Personal Data We Collect',
            body:
            'EduNest collects and processes the following categories of personal data: '
                '(a) Account data: full name, email address, phone number, role, and profile photo. '
                '(b) Tutor verification data: national ID images, certificates, and bank account details. '
                '(c) Transaction data: booking records, payment history, wallet balances, and withdrawal requests. '
                '(d) Communication data: chat messages between users. '
                '(e) Report data: report descriptions and supporting images. '
                '(f) Usage data: app interaction logs, session data, and device information. '
                'This data is collected to operate the platform, verify tutors, process bookings and payments, '
                'resolve disputes, and maintain platform security.',
          ),
          _TermSection(
            title: '22. How We Use Your Data',
            body:
            'Your personal data is used to: create and manage your account; verify tutor identities; '
                'process bookings, payments, and withdrawals; facilitate communication between users; '
                'handle reports and disputes; send transactional notifications (booking confirmations, payment receipts); '
                'improve platform features and performance; and comply with legal obligations. '
                'We do not sell your personal data to third parties for advertising or marketing purposes.',
          ),
          _TermSection(
            title: '23. Data Sharing & Third-Party Services',
            body:
            'EduNest may share your data with third-party service providers solely to operate the platform, including: '
                'PayOS and VietQR for payment processing; Cloudinary for file and image storage; '
                'Render for cloud hosting; and email delivery services. '
                'These providers are contractually bound to handle your data securely and only for the purposes '
                'described. EduNest does not control and is not responsible for the independent operations, '
                'errors, or policies of these third parties.',
          ),
          _TermSection(
            title: '24. Data Retention & Deletion',
            body:
            'We retain your personal data for as long as your account is active or as needed to provide services. '
                'Account data is deleted or anonymized within 30 days of an account deletion request, '
                'except where retention is required by law or for legitimate business purposes '
                'such as resolving disputes or preventing fraud. '
                'Transaction records may be retained for up to 5 years for financial and legal compliance. '
                'You may request deletion of your account and data at any time through the app settings '
                'or by contacting our support email.',
          ),
          _TermSection(
            title: '25. Your Rights Over Your Data',
            body:
            'Subject to applicable law, you have the right to: '
                '(a) Access — request a copy of the personal data we hold about you. '
                '(b) Correction — request correction of inaccurate or incomplete data. '
                '(c) Deletion — request deletion of your personal data and account. '
                '(d) Portability — request your data in a machine-readable format where technically feasible. '
                '(e) Objection — object to certain types of data processing. '
                'To exercise any of these rights, contact us at the support email listed in the app. '
                'We will respond to valid requests within 30 days.',
          ),
          _TermSection(
            title: '26. Storage of Images & Documents',
            body:
            'Certain images, such as tutor verification documents or report evidence, are stored on Cloudinary, '
                'a third-party cloud storage provider. EduNest implements access controls to restrict unauthorized '
                'access to sensitive images. '
                'Users must not upload images that violate the law, infringe on third-party rights, '
                'or are unrelated to the verification or reporting process.',
          ),
          _TermSection(
            title: '27. Data Security',
            body:
            'EduNest implements reasonable technical and organizational measures to protect your personal data '
                'against unauthorized access, loss, alteration, or disclosure. '
                'These measures include JWT-based authentication, encrypted data transmission (HTTPS), '
                'and restricted access controls for sensitive data. '
                'However, no system is completely secure and we cannot guarantee absolute security. '
                'You are responsible for keeping your login credentials confidential.',
          ),
          _TermSection(
            title: '28. Limitation of Liability',
            body:
            'To the extent permitted by applicable law, EduNest is not liable for losses arising from '
                'incorrect user-entered information, off-platform payments, personal disputes outside the platform, '
                'misconduct by other users, device failures, network errors, third-party service issues, '
                'or indirect and consequential damages.',
          ),
          _TermSection(
            title: '29. Account Suspension or Termination',
            body:
            'EduNest reserves the right to suspend or terminate accounts if users violate these terms, '
                'provide false information, engage in fraudulent activity, harm other users, '
                'abuse the platform, or violate applicable laws. '
                'Where possible, we will notify users before suspension unless doing so would compromise '
                'security or an ongoing investigation.',
          ),
          _TermSection(
            title: '30. Changes to These Terms',
            body:
            'EduNest reserves the right to update these Terms of Service at any time. '
                'When significant changes are made, we will notify users via in-app notification, email, '
                'or other appropriate means at least 7 days before the changes take effect. '
                'Continued use of the platform after the updated terms take effect constitutes '
                'the user\'s acceptance of the revised terms.',
          ),
          _TermSection(
            title: '31. Governing Law & Dispute Resolution',
            body:
            'These terms are governed by the laws of the Socialist Republic of Vietnam. '
                'Any disputes arising will be prioritized for resolution through direct negotiation between '
                'the user and EduNest. If a dispute cannot be resolved through negotiation, '
                'it may be referred to the competent courts or authorities in accordance with Vietnamese law.',
          ),
          _TermSection(
            title: '32. Contact Us',
            body:
            'If you have any questions about these Terms of Service, your personal data, or wish to exercise '
                'your data rights, please contact us at: '
                'Support Email: [Support email] '
                'We aim to respond to all inquiries within 5 business days.',
          ),
          _TermSection(
            title: '33. User Acknowledgment',
            body:
            'By creating an account, logging in, making a booking, completing a payment, teaching a session, '
                'requesting a withdrawal, or using any feature of EduNest, users confirm that they have read, '
                'understood, and agreed to comply with these Terms of Service and our data collection practices '
                'as described above.',
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
              'By registering, accessing, or using EduNest, you confirm that you have read, understood, '
                  'and agreed to these Terms of Service, including our data collection and privacy practices.',
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
      'Please read and review the EduNest Terms of Service carefully before using the platform.',
      style: Theme.of(context).textTheme.bodySmall,
      textAlign: TextAlign.center,
    );
  }
}