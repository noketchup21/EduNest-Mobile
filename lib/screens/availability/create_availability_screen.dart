import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/mvp_models.dart';
import '../../providers/app_data_provider.dart';
import '../../widgets/app_button.dart';
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
  String level = 'Beginner';

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
    final data = context.watch<AppDataProvider>();
    final verification = data.tutorVerification;

    final approved = _isApproved(verification);

    if (data.loading && verification == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Create availability'),
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
        title: const Text('Create availability'),
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
            Card(
              child: ListTile(
                leading: const Icon(Icons.verified),
                title: const Text('Tutor approved'),
                subtitle: const Text(
                  'You can now create teaching availability.',
                ),
                trailing: Chip(
                  label: Text(verification?.verificationStatus ?? 'Approved'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Form(
              key: formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: selectedSubjectId,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      hintText: 'Choose a subject',
                    ),
                    items: data.subjects.map((subject) {
                      return DropdownMenuItem<int>(
                        value: subject.subjectId,
                        child: Text(subject.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedSubjectId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please choose a subject';
                      }

                      return null;
                    },
                  ),
                  if (data.subjects.isEmpty) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed:
                            data.loading ? null : data.loadMyAvailability,
                        icon: const Icon(Icons.refresh),
                        label: const Text('No subjects loaded. Refresh'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  FormField<Set<String>>(
                    initialValue: selectedDaysOfWeek,
                    validator: (_) {
                      if (selectedDaysOfWeek.isEmpty) {
                        return 'Choose at least one day';
                      }

                      return null;
                    },
                    builder: (field) {
                      final colors = Theme.of(context).colorScheme;

                      return InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Days of week',
                          errorText: field.errorText,
                          border: const OutlineInputBorder(),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: weekdayOptions.map((day) {
                            final selected = selectedDaysOfWeek.contains(day);

                            return FilterChip(
                              label: Text(day),
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
                    decoration: const InputDecoration(
                      labelText: 'Mode',
                    ),
                    items: const [
                      'Online',
                      'Offline',
                    ].map((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
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
                      decoration: const InputDecoration(
                        labelText: 'Offline tutoring areas',
                        hintText: 'Example: District 1, District 3, Binh Thanh',
                      ),
                      minLines: 2,
                      maxLines: 4,
                      maxLength: 500,
                      validator: (value) {
                        if (mode == 'Offline' &&
                            (value == null || value.trim().isEmpty)) {
                          return 'Enter the areas you are willing to tutor';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  DropdownButtonFormField<String>(
                    initialValue: level,
                    decoration: const InputDecoration(
                      labelText: 'Level',
                    ),
                    items: const [
                      'Beginner',
                      'Intermediate',
                      'Advanced',
                    ].map((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        level = value ?? 'Beginner';
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: startDate,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Start course date',
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
                      labelText: 'End course date',
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
                      labelText: 'Start time',
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
                      labelText: 'End time',
                      hintText: 'HH:mm:ss',
                      suffixIcon: IconButton(
                        onPressed: () => _pickTime(endTime),
                        icon: const Icon(Icons.schedule_outlined),
                      ),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: price,
                    decoration: const InputDecoration(
                      labelText: 'Price per lesson',
                      hintText: 'Example: 200000',
                    ),
                    keyboardType: TextInputType.number,
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.calculate_outlined),
                      title: const Text('Course price preview'),
                      subtitle: Text(
                        'Lessons: $lessons\n'
                        'Price per lesson: ${price.text.trim().isEmpty ? '0' : price.text.trim()}',
                      ),
                      trailing: MoneyText(total),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Create',
                    loading: data.loading,
                    onPressed: () => _submit(data),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'My availability',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            if (data.myAvailabilities.isEmpty && !data.loading)
              const Card(
                child: ListTile(
                  title: Text('No availability yet'),
                  subtitle: Text('Create your first teaching schedule above.'),
                ),
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
                    '${availability.dayOfWeek} '
                    '${availability.startTime}-${availability.endTime}\n'
                    '${availability.mode} • ${availability.level}\n'
                    '${_offlineAreaLine(availability)}'
                    'Lessons: ${availability.slot}\n'
                    'Price per lesson: ${availability.pricePerSlot.toStringAsFixed(0)}',
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
    final status = verification?.verificationStatus ?? 'NotSubmitted';
    final lowerStatus = status.toLowerCase();

    String title;
    String message;
    IconData icon;

    if (lowerStatus == 'pending') {
      title = 'Waiting for admin approval';
      message =
          'Your documents have been submitted. You cannot create availability until admin approves your tutor profile.';
      icon = Icons.hourglass_top;
    } else if (lowerStatus == 'rejected') {
      title = 'Verification rejected';
      message = verification?.verificationRejectReason ??
          'Your verification was rejected. Please update your documents and submit again.';
      icon = Icons.cancel_outlined;
    } else {
      title = 'Tutor verification required';
      message =
          'Please submit your CCCD, certificate or university document, and bank information before creating availability.';
      icon = Icons.assignment_outlined;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create availability'),
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
                    label: Text('Status: $status'),
                  ),
                  const SizedBox(height: 20),
                  if (lowerStatus != 'pending')
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => context.go('/tutor-verification'),
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Open verification form'),
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
                        label: const Text('Refresh approval status'),
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
    if (!formKey.currentState!.validate()) return;

    final parsedStartDate = DateTime.tryParse(startDate.text.trim());
    final parsedEndDate = DateTime.tryParse(endDate.text.trim());

    if (parsedStartDate == null || parsedEndDate == null) {
      _showMessage('Invalid course date. Use yyyy-MM-dd');
      return;
    }

    if (parsedStartDate.isAfter(parsedEndDate)) {
      _showMessage('Start date must be before end date');
      return;
    }

    final parsedStartTime = _parseTime(startTime.text.trim());
    final parsedEndTime = _parseTime(endTime.text.trim());

    if (parsedStartTime == null || parsedEndTime == null) {
      _showMessage('Invalid time. Use HH:mm:ss');
      return;
    }

    if (parsedStartTime >= parsedEndTime) {
      _showMessage('Start time must be before end time');
      return;
    }

    final lessonCount = _calculateSlotCount();

    if (lessonCount <= 0) {
      _showMessage('No lesson found for selected days in this date range');
      return;
    }

    final parsedPrice = double.tryParse(price.text.trim());

    if (parsedPrice == null || parsedPrice <= 0) {
      _showMessage('Invalid price per lesson');
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
        level: level,
        startCourseTime: parsedStartDate,
        endCourseTime: parsedEndDate,
        startTime: startTime.text.trim(),
        endTime: endTime.text.trim(),
        pricePerSlot: parsedPrice,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Availability created'),
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

  String _offlineAreaLine(AvailabilityModel availability) {
    final areas = availability.offlineAreas?.trim() ?? '';

    if (availability.mode != 'Offline' || areas.isEmpty) {
      return '';
    }

    return 'Areas: $areas\n';
  }

  bool _isApproved(TutorVerificationModel? verification) {
    if (verification == null) return false;

    return verification.isVerified &&
        verification.verificationStatus.toLowerCase() == 'approved';
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
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
