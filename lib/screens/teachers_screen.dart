import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import '../services/etlab_api_service.dart';
import '../widgets/page_header.dart';

class TeachersScreen extends StatelessWidget {
  final bool isTabMode;
  const TeachersScreen({super.key, this.isTabMode = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final teachersData = EtlabApiService().fetchTeachers();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(title: 'Faculty'),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>?>(
                future: teachersData,
                builder: (context, snapshot) {
                  final teachers = DashboardDataMapper.parseTeachers(
                    snapshot.data ?? EtlabApiService().profileData,
                  );

                  if (teachers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 48,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No teacher details found.',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    itemCount: teachers.length,
                    itemBuilder: (context, index) {
                      final teacher = teachers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant.withAlpha(
                              100,
                            ),
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                (teacher.imageUrl != null &&
                                    teacher.imageUrl!.startsWith('http'))
                                ? NetworkImage(teacher.imageUrl!)
                                : null,
                            child:
                                (teacher.imageUrl == null ||
                                    !teacher.imageUrl!.startsWith('http'))
                                ? Text(
                                    teacher.name.isNotEmpty
                                        ? teacher.name[0]
                                        : '?',
                                  )
                                : null,
                          ),
                          title: Text(
                            teacher.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                teacher.roleOrSubject,
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              if (teacher.email.isNotEmpty)
                                Text(
                                  teacher.email,
                                  style: theme.textTheme.bodySmall,
                                ),
                              if (teacher.phone != null &&
                                  teacher.phone!.isNotEmpty)
                                Text(
                                  'Phone: ${teacher.phone}',
                                  style: theme.textTheme.bodySmall,
                                ),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
