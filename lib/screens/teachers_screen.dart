import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import '../services/etlab_api_service.dart';
import '../widgets/page_header.dart';
import 'notifications_screen.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (EtlabApiService().teachersData == null) {
      _loadTeachers();
    }
  }

  Future<void> _loadTeachers() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await EtlabApiService().fetchTeachers();
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final api = EtlabApiService();
    final teachers = DashboardDataMapper.parseTeachers(
      api.teachersData ?? api.profileData,
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: 'Faculty',
              actions: [
                HeaderAction(
                  icon: Icons.refresh,
                  tooltip: 'Refresh',
                  onTap: _loadTeachers,
                ),
                HeaderAction(
                  icon: Icons.notifications_outlined,
                  tooltip: 'Notifications',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            Expanded(
              child: _isLoading && teachers.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadTeachers,
                      child: teachers.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.5,
                                  child: Center(
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
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
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
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
