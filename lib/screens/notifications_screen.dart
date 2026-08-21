import 'package:flutter/material.dart';
import '../services/notifications_service.dart';
import 'attendance_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _newAbsences = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final service = NotificationsService();
    final absences = await service.getNewAbsences();
    
    if (mounted) {
      setState(() {
        _newAbsences = absences;
        _isLoading = false;
      });
    }

    // We no longer mark them all as read immediately.
    // The user must manually dismiss them.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _newAbsences.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant.withAlpha(100)),
                  const SizedBox(height: 16),
                  Text('All caught up!', style: theme.textTheme.titleMedium),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _newAbsences.length,
              itemBuilder: (context, index) {
                final absence = _newAbsences[index];
                final date = absence['date'] ?? '';
                final subject = absence['subject'] ?? '';
                final hour = absence['hour'] ?? '';

                return Dismissible(
                  key: Key(absence['key'] ?? index.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: theme.colorScheme.error,
                    child: Icon(Icons.delete_outline, color: theme.colorScheme.onError),
                  ),
                  onDismissed: (direction) async {
                    final service = NotificationsService();
                    await service.markAsRead(absence['key']);
                    setState(() {
                      _newAbsences.removeAt(index);
                    });
                  },
                  child: Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerHighest,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant.withAlpha(100),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: theme.colorScheme.errorContainer,
                                child: Icon(Icons.warning_amber_rounded, color: theme.colorScheme.onErrorContainer, size: 18),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Absence Detected',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.error,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                date,
                                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            subject,
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Period / Hour: $hour',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.tonalIcon(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const AttendanceScreen()),
                                );
                              },
                              icon: const Icon(Icons.analytics_outlined, size: 18),
                              label: const Text('View Attendance'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
