import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_antigravity_starter_pack/app/theme/app_tokens.dart';
import 'package:flutter_antigravity_starter_pack/core/config/env.dart';
import 'package:flutter_antigravity_starter_pack/core/extensions/context_extensions.dart';
import 'package:flutter_antigravity_starter_pack/core/widgets/async_value_view.dart';
import 'package:flutter_antigravity_starter_pack/features/profile/application/profile_controller.dart';
import 'package:flutter_antigravity_starter_pack/features/profile/data/models/employee_profile.dart';

/// Halaman Profil Pegawai yang memuat data dari endpoint Laravel `GET /api/auth/me`.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final controller = ref.read(profileControllerProvider.notifier);
    final apiBaseUrl = ref.watch(envProvider).apiBaseUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Pegawai'),
        actions: [
          IconButton(
            key: const Key('profile.refresh'),
            tooltip: 'Muat ulang profil',
            onPressed: controller.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: AsyncValueView<EmployeeProfile>(
        value: profileState,
        onRetry: () => ref.invalidate(profileControllerProvider),
        data: (profile) => RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            children: [
              _ProfileHeaderCard(
                profile: profile,
                avatarUrl: profile.resolveAvatarUrl(apiBaseUrl),
              ),
              const SizedBox(height: AppSpacing.md),
              _ProfileInfoSection(
                title: 'Informasi Kepegawaian',
                items: [
                  _ProfileInfoItem(
                    icon: Icons.badge_outlined,
                    label: 'ID Pegawai',
                    value: _nonEmpty(profile.employeeId) ?? '#${profile.id}',
                  ),
                  _ProfileInfoItem(
                    icon: Icons.work_outline,
                    label: 'Jabatan',
                    value: _nonEmpty(profile.position) ?? '-',
                  ),
                  _ProfileInfoItem(
                    icon: Icons.business_outlined,
                    label: 'Departemen',
                    value: _nonEmpty(profile.department) ?? '-',
                  ),
                  _ProfileInfoItem(
                    icon: Icons.verified_user_outlined,
                    label: 'Peran',
                    value: profile.roleLabel,
                  ),
                  if (_formatDate(profile.joinDate ?? profile.createdAt)
                      case final formattedDate?)
                    _ProfileInfoItem(
                      icon: Icons.calendar_today_outlined,
                      label: 'Bergabung Sejak',
                      value: formattedDate,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _ProfileInfoSection(
                title: 'Informasi Akun',
                items: [
                  _ProfileInfoItem(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: profile.email,
                  ),
                  if (_nonEmpty(profile.phone) case final phone?)
                    _ProfileInfoItem(
                      icon: Icons.phone_outlined,
                      label: 'Nomor Telepon',
                      value: phone,
                    ),
                  if (_nonEmpty(profile.address) case final address?)
                    _ProfileInfoItem(
                      icon: Icons.location_on_outlined,
                      label: 'Alamat',
                      value: address,
                    ),
                  if (_nonEmpty(profile.emailVerifiedAt) != null)
                    const _ProfileInfoItem(
                      icon: Icons.mark_email_read_outlined,
                      label: 'Status Email',
                      value: 'Terverifikasi',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({required this.profile, required this.avatarUrl});

  final EmployeeProfile profile;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final position = _nonEmpty(profile.position);
    final department = _nonEmpty(profile.department);
    final subtitle = switch ((position, department)) {
      (final pos?, final dept?) => '$pos · $dept',
      (final pos?, null) => pos,
      (null, final dept?) => dept,
      (null, null) => profile.email,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          _ProfileAvatar(initials: profile.initials, avatarUrl: avatarUrl),
          const SizedBox(height: AppSpacing.md),
          Text(
            profile.fullName,
            textAlign: TextAlign.center,
            style: context.textTheme.titleLarge?.copyWith(
              color: colors.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.onPrimaryContainer.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Text(
              profile.roleLabel,
              style: context.textTheme.labelMedium?.copyWith(
                color: colors.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatefulWidget {
  const _ProfileAvatar({required this.initials, required this.avatarUrl});

  final String initials;
  final String? avatarUrl;

  @override
  State<_ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<_ProfileAvatar> {
  bool _imageFailed = false;

  @override
  void didUpdateWidget(covariant _ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarUrl != widget.avatarUrl) {
      _imageFailed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final url = widget.avatarUrl;
    final showImage = url != null && url.isNotEmpty && !_imageFailed;

    return CircleAvatar(
      radius: 40,
      backgroundColor: colors.primary,
      foregroundColor: colors.onPrimary,
      backgroundImage: showImage ? NetworkImage(url) : null,
      onBackgroundImageError: showImage
          ? (_, _) {
              if (mounted) setState(() => _imageFailed = true);
            }
          : null,
      child: showImage
          ? null
          : Text(
              widget.initials,
              style: context.textTheme.headlineSmall?.copyWith(
                color: colors.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}

class _ProfileInfoSection extends StatelessWidget {
  const _ProfileInfoSection({required this.title, required this.items});

  final String title;
  final List<_ProfileInfoItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                Divider(
                  height: AppSpacing.md,
                  color: colors.outlineVariant.withValues(alpha: 0.5),
                ),
              _ProfileInfoRow(item: items[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoItem {
  const _ProfileInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({required this.item});

  final _ProfileInfoItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, size: 20, color: colors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: context.textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String? _nonEmpty(String? value) {
  final trimmed = value?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}

const _monthNames = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

String? _formatDate(String? raw) {
  final value = _nonEmpty(raw);
  if (value == null) return null;
  final parsed = DateTime.tryParse(value)?.toLocal();
  if (parsed == null) return value;
  return '${parsed.day} ${_monthNames[parsed.month - 1]} ${parsed.year}';
}
