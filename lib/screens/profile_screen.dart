import 'package:flutter/material.dart';
import '../services/etlab_api_service.dart';
import '../widgets/page_header.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Map<String, String> _detailLabels = {
    'register_no': 'Register Number',
    'student_id': 'Student ID',
    'admno': 'Admission No',
    'admission_no': 'Admission No',
    'course_code': 'Course',
    'course': 'Course',
    'coursename': 'Course',
    'branch_name': 'Branch',
    'branch': 'Branch',
    'department': 'Department',
    'section': 'Section',
    'batch': 'Batch',
    'academic_year': 'Academic Year',
    'academicyear': 'Academic Year',
    'dob': 'Date of Birth',
    'date_of_birth': 'Date of Birth',
    'gender': 'Gender',
    'sex': 'Gender',
    'blood_group': 'Blood Group',
    'bloodgroup': 'Blood Group',
    'mobile': 'Mobile',
    'mobile_no': 'Mobile',
    'mobileno': 'Mobile',
    'phone': 'Phone',
    'contact_no': 'Contact No',
    'email': 'Email',
    'mail': 'Email',
    'hosteller': 'Hosteller',
  };

  String _formatValue(String key, String raw) {
    if (key == 'hosteller') {
      final v = raw.trim().toLowerCase();
      return (v == '1' || v == 'true' || v == 'yes') ? 'Yes' : 'No';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final api = EtlabApiService();
    final profile = api.profileData;

    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final name = profile['name']?.toString() ?? 'Student';
    final regNo =
        profile['register_no']?.toString() ??
        profile['student_id']?.toString() ??
        '';
    final sem = profile['curnt_sem']?.toString() ?? '';
    final photoUrl = profile['url']?.toString();
    final hasPhoto = photoUrl != null && photoUrl.startsWith('http');

    final byLowerKey = {
      for (final e in profile.entries) e.key.toLowerCase(): e.value,
    };
    final detailRows = _detailLabels.entries
        .map((labelEntry) {
          final value = byLowerKey[labelEntry.key]?.toString().trim() ?? '';
          if (value.isEmpty) return null;
          return MapEntry(
            labelEntry.value,
            _formatValue(labelEntry.key, value),
          );
        })
        .whereType<MapEntry<String, String>>()
        .toList();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PageHeader(title: 'Profile'),
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primaryContainer,
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: hasPhoto
                            ? Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    _initialAvatar(theme, name),
                              )
                            : _initialAvatar(theme, name),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (regNo.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withAlpha(120),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            regNo,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      'DETAILS',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant.withAlpha(
                            100,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            if (sem.isNotEmpty)
                              _DetailRow(label: 'Semester', value: sem),
                            if (sem.isNotEmpty)
                              const Divider(height: 1, indent: 16),
                            for (var i = 0; i < detailRows.length; i++) ...[
                              _DetailRow(
                                label: detailRows[i].key,
                                value: detailRows[i].value,
                              ),
                              if (i < detailRows.length - 1)
                                const Divider(height: 1, indent: 16),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _initialAvatar(ThemeData theme, String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'S',
        style: TextStyle(
          fontSize: 40,
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: SelectableText(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileAvatarAction extends StatelessWidget {
  const ProfileAvatarAction({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = EtlabApiService().profileData;
    final url = profile?['url']?.toString() ?? '';
    final name = profile?['name']?.toString() ?? '';
    final hasPhoto = url.startsWith('http');

    return Tooltip(
      message: 'Profile',
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        shape: CircleBorder(
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          },
          child: SizedBox(
            width: 42,
            height: 42,
            child: hasPhoto
                ? Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _initial(theme, name),
                  )
                : _initial(theme, name),
          ),
        ),
      ),
    );
  }

  Widget _initial(ThemeData theme, String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'S',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
