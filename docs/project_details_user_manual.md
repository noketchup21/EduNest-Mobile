# EduNest Project Details and User Manual

## 1. Product Overview

EduNest is a tutoring and learning management application for Students, Parents, Tutors, and Admins. The Flutter mobile/desktop frontend connects to the ASP.NET Core EduNest backend to support account registration, tutor discovery, class booking, lesson tracking, homework, course materials, chat, reports, tutor wallet, payouts, and administrative review.

[IMAGE PLACEHOLDER: EduNest app logo and a simple overview diagram showing Student/Parent, Tutor, and Admin connected through the EduNest platform.]

## 2. User Roles

EduNest supports four main roles:

- Student: learns through booked classes, views lessons, submits homework, reads tutor feedback, downloads course materials, and chats with tutors.
- Parent: books tutoring classes, monitors lessons/homework/results, accesses materials, communicates with tutors, and manages learning activity for the student.
- Tutor: creates course availability, manages lessons, adds homework, grades submissions, uploads materials, manages wallet/payout information, and communicates with learners.
- Admin: reviews tutor verification, manages reports, handles payout review, monitors platform metrics, and manages tutor account status.

[IMAGE PLACEHOLDER: Role selection screen showing Tutor and Learner options.]

## 3. Registration and Login Flow

### 3.1 Register an Account

1. Open the app.
2. Tap Register.
3. Choose Tutor or Learner.
4. If choosing Learner, select Parent or Student.
5. Fill in the required registration details:
   - Name
   - Email
   - Password
   - Phone
   - Student school, parent address, or tutor bio where applicable
6. Submit the registration form.
7. Open the verification email and enter the verification code in the app.
8. After verification, return to login and sign in with the registered account.

[IMAGE PLACEHOLDER: Registration flow screenshots: role selection, registration form, email verification screen.]

### 3.2 Login

1. Open the app.
2. Tap Login.
3. Choose Tutor or Learner.
4. Enter email and password.
5. The app redirects the user based on role:
   - Admin goes to the Admin dashboard.
   - Tutor goes to tutor verification or the main tutor experience.
   - Student/Parent goes to Home.

[IMAGE PLACEHOLDER: Login screen and successful landing screen after login.]

## 4. Main Navigation

EduNest uses a bottom navigation bar. Available tabs depend on the user role.

Student/Parent navigation:

- Home: browse tutors/classes and view dashboard content.
- Booking: view enrolled or pending bookings.
- Course: quick access menu for Lessons, Homework, and Materials.
- Chat: conversations with tutors.
- Profile: account details, avatar, reports, terms, and support actions.

Tutor navigation:

- Home: manage course availability/classes.
- Course: quick access menu for Lessons, Homework, and Materials.
- Chat: conversations with students/parents.
- Wallet: balance, transactions, and payout requests.
- Profile: account details, tutor bank account, verification, reports, and support.

Admin navigation:

- Admin: dashboard, tutor verification, reports, payouts, and tutor account management.
- Chat/Profile may be available depending on the signed-in account flow.

[IMAGE PLACEHOLDER: Bottom navigation bar with Home, Booking, Course, Chat, Wallet/Profile. Include Course quick menu expanded with Lesson, Homework, Materials.]

## 5. Student and Parent Guide

### 5.1 Browse Tutors and Book a Class

1. Go to Home.
2. Browse available tutors and classes.
3. Open a tutor profile to view tutor details, subjects, class schedule, price, and reviews.
4. Tap Enroll or Enroll Now.
5. Confirm booking information.
6. Continue to payment if required.
7. After payment or successful booking, the class appears under Booking and related lessons appear under Course > Lesson.

[IMAGE PLACEHOLDER: Home tutor list, tutor profile detail, class card, and booking confirmation/payment screen.]

### 5.2 Manage Bookings

1. Go to Booking.
2. Review pending, confirmed, completed, or cancelled bookings.
3. Open a booking to check tutor, class, price, and status.
4. Cancel a booking where cancellation is allowed.
5. Sync payment status if payment was completed but the app has not updated yet.

[IMAGE PLACEHOLDER: Booking screen showing booking cards with status labels.]

### 5.3 View Lessons

1. Tap Course in the bottom navigation.
2. Select Lesson.
3. View upcoming and completed lessons.
4. Open lesson detail to see:
   - Lesson time
   - Tutor/student information
   - Attendance status
   - Meeting link if available
   - Related homework
5. Use Open to join or open the meeting link when provided.

[IMAGE PLACEHOLDER: Course quick menu and Lesson list/detail screens.]

### 5.4 Do and Submit Homework

1. Tap Course.
2. Select Homework.
3. Choose the class/date group.
4. Expand the homework item.
5. Check homework title, description, due date, warning badge, and status.
6. Tap Do homework for unsubmitted homework.
7. Answer multiple-choice questions and essay prompts.
8. Tap Submit.
9. After submission, the app opens the result view.

Homework statuses may include pending/not submitted, submitted, graded, or completed depending on backend response.

[IMAGE PLACEHOLDER: Homework list grouped by class/date, homework detail, multiple-choice answer screen, essay answer screen, submit button.]

### 5.5 View Homework Results

1. Open Course > Homework.
2. Select a submitted homework item.
3. Tap View result.
4. Review:
   - Multiple-choice answers
   - Essay answers
   - Score
   - Tutor feedback
   - Overall feedback
   - Submitted date

[IMAGE PLACEHOLDER: Homework result screen showing score, question feedback, essay feedback, and tutor comments.]

### 5.6 View and Download Course Materials

1. Tap Course.
2. Select Materials.
3. Choose the enrolled class.
4. Expand material sections.
5. Tap a material item to open or download it.
6. Materials may include uploaded files or external links, depending on what the tutor provided.

[IMAGE PLACEHOLDER: Materials screen with class dropdown, expandable sections, and file/download action.]

### 5.7 Chat with Tutor

1. Go to Chat.
2. Select an existing conversation or start chat from a tutor profile.
3. Send messages related to lessons, homework, schedules, or learning support.

[IMAGE PLACEHOLDER: Chat conversation list and chat detail screen.]

### 5.8 Report an Issue or Tutor

1. Go to Profile or the relevant report screen.
2. Choose the report/support action.
3. Enter issue category, title, description, and related booking/lesson/payout ID if applicable.
4. Add proof images if needed.
5. Submit the report.
6. Track report status in My Reports or My Support Reports.

[IMAGE PLACEHOLDER: Create support report screen and My Reports status list.]

### 5.9 Manage Profile

1. Go to Profile.
2. View account information.
3. Update profile details.
4. Upload, update, or delete avatar.
5. Open Terms of Service.
6. Logout when finished.

[IMAGE PLACEHOLDER: Profile screen with avatar, profile fields, terms, and logout action.]

## 6. Tutor Guide

### 6.1 Tutor Verification

1. Register as a Tutor.
2. Login and open Tutor verification.
3. Upload required verification documents:
   - CCCD front image
   - CCCD back image
   - Certificate, degree, or university document
4. Enter CCCD number and bank account details.
5. Submit verification.
6. Wait for Admin approval.
7. If rejected, review the rejection reason and resubmit corrected information.

[IMAGE PLACEHOLDER: Tutor verification form with document upload cards and bank account fields.]

### 6.2 Create and Manage Class Availability

1. Go to Home.
2. Tap Create Availability or Add Course.
3. Select subject, schedule, start/end dates, price, slot count, and days of week.
4. Submit the class availability.
5. Use the course status action to publish or hide the course.
6. Existing booked classes appear in the tutor dashboard and lesson/homework/material flows.

[IMAGE PLACEHOLDER: Tutor Home screen, create availability form, multiple day-of-week selector, publish/hide course action.]

### 6.3 Manage Lessons

1. Tap Course.
2. Select Lesson.
3. Open a lesson detail.
4. Add or update a meeting link.
5. Mark attendance as Present, Absent, or Late.
6. Complete a lesson or complete a lesson group where available.
7. Review lesson details for students in the class.

[IMAGE PLACEHOLDER: Tutor lesson list, lesson detail, attendance menu, meeting link form.]

### 6.4 Add Homework

1. Tap Course.
2. Select Homework.
3. Choose a class from the class dropdown.
4. Select a lesson that is eligible for homework.
5. Tap Add.
6. Enter homework title, description, type, and due date.
7. Add multiple-choice questions:
   - Enter question text.
   - Enter points.
   - Add answer options.
   - Mark the correct option.
   - Remove unwanted options if needed.
8. Add essay questions:
   - Enter essay prompt.
   - Enter points.
   - Remove essay prompts if needed.
9. Save the homework.

Tutors cannot edit homework after a student or parent has submitted it.

[IMAGE PLACEHOLDER: Tutor Homework screen with class dropdown, add homework form, multiple-choice editor, essay editor, due date field.]

### 6.5 View, Edit, Delete, and Grade Homework

1. Open Course > Homework.
2. Use the class dropdown to filter homework.
3. Expand a class/date group to see homework items.
4. Open View detail to review title, description, due date, questions, essays, and submissions.
5. Edit homework only if no submission has been completed.
6. Delete homework only when deletion is allowed.
7. Open a submission and tap Grade.
8. Enter score and feedback for essay answers.
9. Add overall feedback.
10. Save grade.

[IMAGE PLACEHOLDER: Tutor homework grouped list, homework detail view, submission list, grading dialog.]

### 6.6 Manage Course Materials

1. Tap Course.
2. Select Materials.
3. Choose the class/availability.
4. Tap Section to add a material section.
5. Enter section title and optional description.
6. Add materials inside the section.
7. For each material item, enter:
   - Title
   - Optional description
   - Uploaded file or external link
   - Section placement
8. Edit or delete sections and material items as needed.
9. Students and parents enrolled in the class can view and download the materials.

[IMAGE PLACEHOLDER: Tutor Materials screen with class dropdown, add section dialog, add material dialog, expanded section with file item.]

### 6.7 Wallet and Payouts

1. Go to Wallet.
2. Review wallet balance and transaction history.
3. Request a payout when funds are available.
4. Enter payout amount.
5. Track payout status.
6. Admin reviews and processes payout requests.

[IMAGE PLACEHOLDER: Tutor Wallet screen showing balance, transaction list, payout request action.]

### 6.8 Tutor Reports and Support

1. Open Profile or Reports.
2. View reports related to the tutor account.
3. Create a support report if there is a platform, payout, booking, lesson, or account issue.
4. Track support status until Admin resolves it.

[IMAGE PLACEHOLDER: Tutor reports list and support report form.]

## 7. Admin Guide

### 7.1 Admin Dashboard

1. Login with an Admin account.
2. Open Admin.
3. Review platform metrics such as total tutors, pending tutors, approved tutors, completed lessons, and revenue indicators.

[IMAGE PLACEHOLDER: Admin dashboard with metric cards.]

### 7.2 Tutor Verification Review

1. Open Admin.
2. Go to pending tutor verification.
3. Open tutor verification detail.
4. Review CCCD images, certificate image, tutor profile, and bank information.
5. Approve the tutor if valid.
6. Reject with a clear reason if information is incomplete or invalid.

[IMAGE PLACEHOLDER: Admin tutor verification list and verification detail screen.]

### 7.3 Reports Management

1. Open Manage Reports.
2. Search or filter submitted reports.
3. Open report detail.
4. Review description, related IDs, proof images, and reported tutor details.
5. Mark the report as Reviewing, Resolved, or Rejected.
6. Add an admin note.
7. Activate or deactivate a tutor account if required by the report outcome.

[IMAGE PLACEHOLDER: Admin report list, report detail, proof image viewer, status action buttons.]

### 7.4 Support Reports Management

1. Open Support Reports.
2. Filter reports by role or search text.
3. Open a support report.
4. Review issue category, description, related IDs, and proof images.
5. Update status to Pending, Reviewing, Resolved, or Rejected.
6. Add an admin note for the user.

[IMAGE PLACEHOLDER: Admin support reports list and update status dialog.]

### 7.5 Payout Management

1. Open Admin payout management.
2. Review tutor payout requests.
3. Open payout detail.
4. Confirm tutor bank account and payout amount.
5. Approve through payOS Chi where available or mark manually as Paid/Failed.
6. Track payout status changes.

[IMAGE PLACEHOLDER: Admin payout list, payout detail, payOS Chi approval action.]

## 8. Core Backend Feature Mapping

The frontend workflows are backed by these main API areas:

- Authentication: register, verify email, login, refresh token, logout.
- Availability: create, update, hide/publish, list tutor classes and public classes.
- Booking: create booking, view bookings, cancel booking, expire pending bookings.
- Payment: create payOS payment, sync payment, receive payOS webhook.
- Lesson: list lessons, view detail, set meeting link, attendance, complete lesson.
- Homework: create, update, delete, submit, view result, grade submission.
- Materials: create/update/delete sections, upload/update/delete material items, download/open materials.
- Chat: create conversation, list conversations, send and receive messages.
- Profile: view/update profile, update avatar, tutor bank account.
- Wallet/Payout: view wallet, transactions, request payout, admin payout review.
- Reports: tutor reports, support reports, admin status updates.
- Admin: dashboard, tutor verification approval/rejection, tutor activation status.

[IMAGE PLACEHOLDER: Backend feature map diagram showing frontend screens connected to API modules.]

## 9. End-to-End User Flow Summary

### Student/Parent Flow

1. Register as Learner.
2. Verify email.
3. Login.
4. Browse tutors/classes on Home.
5. Open tutor profile.
6. Enroll in a class.
7. Complete payment if required.
8. View bookings.
9. Open Course > Lesson for schedules.
10. Open Course > Homework to submit homework and view results.
11. Open Course > Materials to download tutor-provided materials.
12. Use Chat for communication.
13. Use Profile for account settings, support, and logout.

[IMAGE PLACEHOLDER: Student/Parent flowchart from Register to Homework Result and Materials Download.]

### Tutor Flow

1. Register as Tutor.
2. Verify email.
3. Submit tutor verification documents.
4. Wait for Admin approval.
5. Create class availability.
6. Manage lessons and attendance.
7. Add homework and course materials.
8. Grade student submissions.
9. Communicate through Chat.
10. Review wallet and request payouts.
11. Use reports/support when needed.

[IMAGE PLACEHOLDER: Tutor flowchart from Register to Verification, Course Creation, Homework Grading, and Payout.]

### Admin Flow

1. Login as Admin.
2. Review dashboard metrics.
3. Approve/reject tutor verification.
4. Review support reports and tutor reports.
5. Manage tutor account status.
6. Review and process payout requests.

[IMAGE PLACEHOLDER: Admin flowchart showing verification, report, and payout review.]

## 10. Common User Notes

- A verified email is required before full access.
- Tutor accounts may require Admin approval before tutoring features are fully available.
- Homework close to the due date displays warning indicators.
- Submitted homework switches to result viewing and cannot be edited by the tutor after submission.
- Course Materials are organized by class and section to avoid overcrowding one screen.
- Payment status may be synced from the booking/payment screen if external payment confirmation is delayed.
- Users should contact support or create a support report if payment, booking, homework, or account information looks incorrect.

[IMAGE PLACEHOLDER: A final collage of important states: due-date warning, submitted homework result, material download, support report status.]
