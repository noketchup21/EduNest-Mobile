import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/money_text.dart';

class CreateAvailabilityScreen extends StatefulWidget {
  const CreateAvailabilityScreen({super.key});

  @override
  State<CreateAvailabilityScreen> createState() =>
      _CreateAvailabilityScreenState();
}

class _CreateAvailabilityScreenState extends State<CreateAvailabilityScreen> {
  static const List<String> weekdayOptions = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final formKey = GlobalKey<FormState>();

  late final TextEditingController startDate;
  late final TextEditingController endDate;

  final startTime = TextEditingController(text: '18:00:00');
  final endTime = TextEditingController(text: '20:00:00');
  final price = TextEditingController(text: '200000');
  final offlineAreas = TextEditingController();

  int? selectedSubjectId;

  final Set<String> selectedDaysOfWeek = {'Monday'};
  String mode = 'Online';

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    startDate = TextEditingController(
      text: _dateText(DateTime(now.year, now.month, now.day).add(
        const Duration(days: 1),
      )),
    );
    endDate = TextEditingController(
      text: _dateText(DateTime(now.year, now.month, now.day).add(
        const Duration(days: 60),
      )),
    );

    startDate.addListener(_refreshPreview);
    endDate.addListener(_refreshPreview);
    startTime.addListener(_refreshPreview);
    endTime.addListener(_refreshPreview);
    price.addListener(_refreshPreview);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = context.read<AppDataProvider>();

      data.loadMyTutorVerification();
      data.loadMyAvailability();
    });
  }

  @override
  void dispose() {
    startDate.removeListener(_refreshPreview);
    endDate.removeListener(_refreshPreview);
    startTime.removeListener(_refreshPreview);
    endTime.removeListener(_refreshPreview);
    price.removeListener(_refreshPreview);

    startDate.dispose();
    endDate.dispose();
    startTime.dispose();
    endTime.dispose();
    price.dispose();
    offlineAreas.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final data = context.watch<AppDataProvider>();
    final verification = data.tutorVerification;

    final approved = _isApproved(verification);

    if (data.loading && verification == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(t.text('Create availability')),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!approved) {
      return _buildApprovalRequired(context, data, verification);
    }

    final lessons = _calculateSlotCount();
    final total = _estimatedTotalPrice();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.text('Create availability')),
        actions: [
          IconButton(
            onPressed: data.loading
                ? null
                : () {
                    data.loadMyTutorVerification();
                    data.loadMyAvailability();
                  },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await data.loadMyTutorVerification();
          await data.loadMyAvailability();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ErrorBanner(data.error),
            AppSurfaceCard(
              child: AppSectionHeader(
                icon: Icons.verified_rounded,
                title: t.text('Tutor approved'),
                subtitle: t.text('You can now create teaching availability.'),
                action: AppStatusBadge(
                  label: t.status(
                    verification?.verificationStatus ?? 'Approved',
                  ),
                  tone: AppStatusTone.success,
                  icon: Icons.check_circle_rounded,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Form(
              key: formKey,
              child: Column(
                children: [
                  AppSectionHeader(
                    icon: Icons.menu_book_rounded,
                    title: t.text('Course basics'),
                    subtitle: t.text('Choose the subject you want to teach.'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: selectedSubjectId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: t.text('Subject'),
                      hintText: t.text('Choose a subject'),
                    ),
                    selectedItemBuilder: (context) => data.subjects
                        .map(
                          (subject) => Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              subject.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    items: data.subjects.map((subject) {
                      return DropdownMenuItem<int>(
                        value: subject.subjectId,
                        child: Text(
                          subject.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedSubjectId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return t.text('Please choose a subject');
                      }

                      return null;
                    },
                  ),
                  if (selectedSubjectId != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => context.push(
                          '/teaching-guide',
                          extra: selectedSubjectId,
                        ),
                        icon: const Icon(Icons.auto_awesome_outlined),
                        label: Text(t.text('Open teaching preparation guide')),
                      ),
                    ),
                  ],
                  if (data.subjects.isEmpty) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed:
                            data.loading ? null : data.loadMyAvailability,
                        icon: const Icon(Icons.refresh),
                        label: Text(t.text('No subjects loaded. Refresh')),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  AppSectionHeader(
                    icon: Icons.tune_rounded,
                    title: t.text('Teaching format'),
                    subtitle: t.text('Set the days and delivery mode.'),
                  ),
                  const SizedBox(height: 12),
                  FormField<Set<String>>(
                    initialValue: selectedDaysOfWeek,
                    validator: (_) {
                      if (selectedDaysOfWeek.isEmpty) {
                        return t.text('Choose at least one day');
                      }

                      return null;
                    },
                    builder: (field) {
                      final colors = Theme.of(context).colorScheme;

                      return InputDecorator(
                        decoration: InputDecoration(
                          labelText: t.text('Days of week'),
                          errorText: field.errorText,
                          border: const OutlineInputBorder(),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: weekdayOptions.map((day) {
                            final selected = selectedDaysOfWeek.contains(day);

                            return FilterChip(
                              label: Text(t.text(day)),
                              selected: selected,
                              avatar: selected
                                  ? Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                      color: colors.onSecondaryContainer,
                                    )
                                  : null,
                              onSelected: (value) {
                                setState(() {
                                  if (value) {
                                    selectedDaysOfWeek.add(day);
                                  } else {
                                    selectedDaysOfWeek.remove(day);
                                  }

                                  field.didChange({...selectedDaysOfWeek});
                                });
                              },
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: mode,
                    decoration: InputDecoration(
                      labelText: t.text('Mode'),
                    ),
                    items: [
                      'Online',
                      'Offline',
                    ].map((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(t.mode(item)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        mode = value ?? 'Online';
                        if (mode != 'Offline') {
                          offlineAreas.clear();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  if (mode == 'Offline') ...[
                    TextFormField(
                      controller: offlineAreas,
                      decoration: InputDecoration(
                        labelText: t.text('Offline tutoring areas'),
                        hintText: t.text(
                          'Example: District 1, District 3, Binh Thanh',
                        ),
                      ),
                      minLines: 2,
                      maxLines: 4,
                      maxLength: 500,
                      validator: (value) {
                        if (mode == 'Offline' &&
                            (value == null || value.trim().isEmpty)) {
                          return t.text(
                            'Enter the areas you are willing to tutor',
                          );
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 12),
                  AppSectionHeader(
                    icon: Icons.calendar_month_rounded,
                    title: t.text('Schedule and teaching time'),
                    subtitle:
                        t.text('Choose a repeatable schedule for this course.'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: startDate,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: t.text('Start course date'),
                      hintText: 'yyyy-MM-dd',
                      suffixIcon: IconButton(
                        onPressed: () => _pickDate(startDate),
                        icon: const Icon(Icons.calendar_month_outlined),
                      ),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: endDate,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: t.text('End course date'),
                      hintText: 'yyyy-MM-dd',
                      suffixIcon: IconButton(
                        onPressed: () => _pickDate(endDate),
                        icon: const Icon(Icons.calendar_month_outlined),
                      ),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: startTime,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: t.text('Start time'),
                      hintText: 'HH:mm:ss',
                      suffixIcon: IconButton(
                        onPressed: () => _pickTime(startTime),
                        icon: const Icon(Icons.schedule_outlined),
                      ),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: endTime,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: t.text('End time'),
                      hintText: 'HH:mm:ss',
                      suffixIcon: IconButton(
                        onPressed: () => _pickTime(endTime),
                        icon: const Icon(Icons.schedule_outlined),
                      ),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 24),
                  AppSectionHeader(
                    icon: Icons.payments_outlined,
                    title: t.text('Pricing'),
                    subtitle:
                        t.text('Set the price per lesson before publishing.'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: price,
                    decoration: InputDecoration(
                      labelText: t.text('Price per lesson'),
                      hintText: t.text('Example: 200000'),
                    ),
                    keyboardType: TextInputType.number,
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  AppSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.calculate_outlined,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                t.text('Course price preview'),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${t.text('Lessons')}: $lessons\n'
                          '${t.text('Price per lesson')}: ${price.text.trim().isEmpty ? '0' : price.text.trim()}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: MoneyText(total),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: t.text('Create'),
                    loading: data.loading,
                    onPressed: () => _submit(data),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t.text('My availability'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            if (data.myAvailabilities.isEmpty && !data.loading)
              AppEmptyState(
                icon: Icons.calendar_month_outlined,
                title: t.text('No availability yet'),
                message: t.text('Create your first teaching schedule above.'),
              ),
            ...data.myAvailabilities.map((availability) {
              final totalPrice = availability.totalCoursePrice > 0
                  ? availability.totalCoursePrice
                  : availability.pricePerSlot * availability.slot;

              return Card(
                child: ListTile(
                  title: Text(
                    data.availabilitySubjectName(availability),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    _availabilitySubtitle(availability, t),
                  ),
                  trailing: MoneyText(totalPrice),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalRequired(
    BuildContext context,
    AppDataProvider data,
    TutorVerificationModel? verification,
  ) {
    final t = AppStrings.of(context, listen: false);
    final status = verification?.verificationStatus ?? 'NotSubmitted';
    final lowerStatus = status.toLowerCase();

    String title;
    String message;
    IconData icon;

    if (lowerStatus == 'pending') {
      title = t.text('Waiting for admin approval');
      message = t.text(
        'Your documents have been submitted. You cannot create availability until admin approves your tutor profile.',
      );
      icon = Icons.hourglass_top;
    } else if (lowerStatus == 'rejected') {
      title = t.text('Verification rejected');
      message = verification?.verificationRejectReason ??
          t.text(
            'Your verification was rejected. Please update your documents and submit again.',
          );
      icon = Icons.cancel_outlined;
    } else {
      title = t.text('Tutor verification required');
      message = t.text(
        'Please submit your CCCD, certificate or university document, and bank information before creating availability.',
      );
      icon = Icons.assignment_outlined;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.text('Create availability')),
        actions: [
          IconButton(
            onPressed: data.loading
                ? null
                : () =>
                    context.read<AppDataProvider>().loadMyTutorVerification(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ErrorBanner(data.error),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(icon, size: 72),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Chip(
                    label: Text('${t.text('Status')}: ${t.status(status)}'),
                  ),
                  const SizedBox(height: 20),
                  if (lowerStatus != 'pending')
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => context.go('/tutor-verification'),
                        icon: const Icon(Icons.upload_file),
                        label: Text(t.text('Open verification form')),
                      ),
                    ),
                  if (lowerStatus == 'pending')
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: data.loading
                            ? null
                            : () => context
                                .read<AppDataProvider>()
                                .loadMyTutorVerification(),
                        icon: const Icon(Icons.refresh),
                        label: Text(t.text('Refresh approval status')),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(AppDataProvider data) async {
    final t = AppStrings.of(context, listen: false);

    if (!formKey.currentState!.validate()) return;

    final parsedStartDate = DateTime.tryParse(startDate.text.trim());
    final parsedEndDate = DateTime.tryParse(endDate.text.trim());

    if (parsedStartDate == null || parsedEndDate == null) {
      _showMessage(t.text('Invalid course date. Use yyyy-MM-dd'));
      return;
    }

    if (parsedStartDate.isAfter(parsedEndDate)) {
      _showMessage(t.text('Start date must be before end date'));
      return;
    }

    final parsedStartTime = _parseTime(startTime.text.trim());
    final parsedEndTime = _parseTime(endTime.text.trim());

    if (parsedStartTime == null || parsedEndTime == null) {
      _showMessage(t.text('Invalid time. Use HH:mm:ss'));
      return;
    }

    if (parsedStartTime >= parsedEndTime) {
      _showMessage(t.text('Start time must be before end time'));
      return;
    }

    final lessonCount = _calculateSlotCount();

    if (lessonCount <= 0) {
      _showMessage(
        t.text('No lesson found for selected days in this date range'),
      );
      return;
    }

    final parsedPrice = double.tryParse(price.text.trim());

    if (parsedPrice == null || parsedPrice <= 0) {
      _showMessage(t.text('Invalid price per lesson'));
      return;
    }

    try {
      await data.createAvailability(
        subjectId: selectedSubjectId!,
        daysOfWeek: weekdayOptions
            .where((day) => selectedDaysOfWeek.contains(day))
            .toList(),
        mode: mode,
        offlineAreas: mode == 'Offline' ? offlineAreas.text.trim() : null,
        startCourseTime: parsedStartDate,
        endCourseTime: parsedEndDate,
        startTime: startTime.text.trim(),
        endTime: endTime.text.trim(),
        pricePerSlot: parsedPrice,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.text('Availability created')),
        ),
      );
    } catch (_) {
      // ErrorBanner will show data.error.
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final current = DateTime.tryParse(controller.text.trim()) ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked == null) return;

    controller.text = _dateText(picked);
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final current = _parseTimeOfDay(controller.text.trim()) ??
        const TimeOfDay(hour: 18, minute: 0);

    final picked = await showTimePicker(
      context: context,
      initialTime: current,
    );

    if (picked == null) return;

    controller.text = _timeText(picked);
  }

  void _refreshPreview() {
    if (mounted) {
      setState(() {});
    }
  }

  String _availabilitySubtitle(AvailabilityModel availability, AppStrings t) {
    return '${_daysText(availability.dayOfWeek, t)} '
        '${availability.startTime}-${availability.endTime}\n'
        '${t.mode(availability.mode)}\n'
        '${_offlineAreaLine(availability, t)}'
        '${t.text('Lessons')}: ${availability.slot}\n'
        '${t.text('Price per lesson')}: '
        '${availability.pricePerSlot.toStringAsFixed(0)}';
  }

  String _offlineAreaLine(AvailabilityModel availability, AppStrings t) {
    final areas = availability.offlineAreas?.trim() ?? '';

    if (availability.mode != 'Offline' || areas.isEmpty) {
      return '';
    }

    return '${t.text('Areas')}: $areas\n';
  }

  String _daysText(String value, AppStrings t) {
    return value
        .split(',')
        .map((day) => t.text(day.trim()))
        .where((day) => day.isNotEmpty)
        .join(', ');
  }

  bool _isApproved(TutorVerificationModel? verification) {
    if (verification == null) return false;

    return verification.isVerified &&
        verification.verificationStatus.toLowerCase() == 'approved';
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.of(context, listen: false).requiredField;
    }

    return null;
  }

  int _calculateSlotCount() {
    final start = DateTime.tryParse(startDate.text.trim());
    final end = DateTime.tryParse(endDate.text.trim());

    if (start == null || end == null || start.isAfter(end)) {
      return 0;
    }

    final targetWeekdays = selectedDaysOfWeek.map(_weekdayNumber).toSet();
    var count = 0;

    for (var date = DateTime(start.year, start.month, start.day);
        !date.isAfter(end);
        date = date.add(const Duration(days: 1))) {
      if (targetWeekdays.contains(date.weekday)) {
        count++;
      }
    }

    return count;
  }

  int _weekdayNumber(String value) {
    switch (value.toLowerCase()) {
      case 'monday':
        return DateTime.monday;
      case 'tuesday':
        return DateTime.tuesday;
      case 'wednesday':
        return DateTime.wednesday;
      case 'thursday':
        return DateTime.thursday;
      case 'friday':
        return DateTime.friday;
      case 'saturday':
        return DateTime.saturday;
      case 'sunday':
        return DateTime.sunday;
      default:
        return DateTime.monday;
    }
  }

  double _estimatedTotalPrice() {
    final lessons = _calculateSlotCount();
    final pricePerLesson = double.tryParse(price.text.trim()) ?? 0;

    return lessons * pricePerLesson;
  }

  int? _parseTime(String value) {
    final parts = value.split(':');

    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    final second = parts.length >= 3 ? int.tryParse(parts[2]) ?? 0 : 0;

    if (hour == null || minute == null) return null;

    if (hour < 0 || hour > 23) return null;
    if (minute < 0 || minute > 59) return null;
    if (second < 0 || second > 59) return null;

    return hour * 3600 + minute * 60 + second;
  }

  TimeOfDay? _parseTimeOfDay(String value) {
    final parts = value.split(':');

    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return null;

    if (hour < 0 || hour > 23) return null;
    if (minute < 0 || minute > 59) return null;

    return TimeOfDay(hour: hour, minute: minute);
  }

  static String _dateText(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');

    return '${value.year}-$month-$day';
  }

  static String _timeText(TimeOfDay value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$hour:$minute:00';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}
