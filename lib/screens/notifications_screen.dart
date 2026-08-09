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

    // Mark as read once they are loaded on the screen
    await service.markAllAsRead();
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

                return Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.errorContainer,
                      child: Icon(Icons.warning_amber_rounded, color: theme.colorScheme.onErrorContainer),
                    ),
                    title: Text(
                      'Absence Detected 👻',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Looks like you vanished during $subject on $date (Hour $hour).',
                      ),
                    ),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const AttendanceScreen()),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
