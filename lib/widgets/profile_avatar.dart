import 'dart:io';
import 'package:flutter/material.dart';

import '../screens/profile_screen.dart';
import '../services/etlab/etlab_data_store.dart';

/// Renders student profile avatar, preferring cached image from local storage,
/// falling back to network image (while caching to storage), and ultimately
/// initials if unavailable.
class ProfileAvatar extends StatelessWidget {
  final double size;
  final String? name;
  final String? imageUrl;
  final String? localImagePath;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;
  final TextStyle? textStyle;
  final Color? backgroundColor;

  const ProfileAvatar({
    super.key,
    this.size = 42,
    this.name,
    this.imageUrl,
    this.localImagePath,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 1.5,
    this.textStyle,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataStore = EtlabDataStore();

    return ValueListenableBuilder<String?>(
      valueListenable: dataStore.profileImageNotifier,
      builder: (context, notifPath, _) {
        final profile = dataStore.profileData;
        final resolvedName = name ?? profile?['name']?.toString() ?? '';
        final resolvedUrl = imageUrl ?? profile?['url']?.toString() ?? '';
        final resolvedLocalPath =
            localImagePath ?? notifPath ?? dataStore.profileImagePath;

        final hasLocalFile = resolvedLocalPath != null &&
            resolvedLocalPath.isNotEmpty &&
            File(resolvedLocalPath).existsSync();

        final hasNetworkUrl = resolvedUrl.startsWith('http');

        // If no local file yet but valid network URL, trigger caching to storage
        if (!hasLocalFile && hasNetworkUrl) {
          dataStore.cacheProfileImage(resolvedUrl);
        }

        Widget avatarContent;
        if (hasLocalFile) {
          avatarContent = Image.file(
            File(resolvedLocalPath),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              if (hasNetworkUrl) {
                return Image.network(
                  resolvedUrl,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildInitials(theme, resolvedName),
                );
              }
              return _buildInitials(theme, resolvedName);
            },
          );
        } else if (hasNetworkUrl) {
          avatarContent = Image.network(
            resolvedUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildInitials(theme, resolvedName),
          );
        } else {
          avatarContent = _buildInitials(theme, resolvedName);
        }

        final containerBg = backgroundColor ??
            (size > 60
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerLow);

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: containerBg,
            border: showBorder
                ? Border.all(
                    color: borderColor ?? theme.colorScheme.primary,
                    width: borderWidth,
                  )
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: avatarContent,
        );
      },
    );
  }

  Widget _buildInitials(ThemeData theme, String name) {
    final letter = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'S';
    final isLarge = size > 60;
    final defaultColor = isLarge
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;

    return Center(
      child: Text(
        letter,
        style: textStyle ??
            TextStyle(
              fontSize: size * 0.38,
              fontWeight: FontWeight.bold,
              color: defaultColor,
            ),
      ),
    );
  }
}

/// App bar action button that displays the profile avatar and opens the Profile screen on tap.
class ProfileAvatarAction extends StatelessWidget {
  const ProfileAvatarAction({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          child: const SizedBox(
            width: 42,
            height: 42,
            child: ProfileAvatar(
              size: 42,
              showBorder: false,
            ),
          ),
        ),
      ),
    );
  }
}
