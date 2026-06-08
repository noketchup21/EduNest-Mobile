const tutorSupportCategories = [
  'MissingPayment',
  'SlowPayout',
  'WrongWalletBalance',
  'LessonIssue',
  'StudentNoShow',
  'BookingIssue',
  'AppBug',
  'AccountIssue',
  'Other',
];

String supportCategoryLabel(String value) {
  switch (value) {
    case 'MissingPayment':
      return 'Missing payment';
    case 'SlowPayout':
      return 'Slow payout';
    case 'WrongWalletBalance':
      return 'Wrong wallet balance';
    case 'LessonIssue':
      return 'Lesson issue';
    case 'StudentNoShow':
      return 'Student no-show';
    case 'BookingIssue':
      return 'Booking issue';
    case 'AppBug':
      return 'App bug';
    case 'AccountIssue':
      return 'Account issue';
    case 'Other':
    default:
      return 'Other';
  }
}