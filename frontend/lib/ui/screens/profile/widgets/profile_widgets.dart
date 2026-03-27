import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/colors.dart';
import '../../../../data/dtos/university_dto.dart';

class ProfileUtils {
  ProfileUtils._();

  /// Extract a short school abbreviation from the university's name.
  static String getSchoolShortName(UniversityDto? university) {
    if (university == null) return 'N/A';

    // Try abbreviation from name first (first letter of each significant word)
    const skipWords = {'of', 'the', 'and', 'in', 'at', 'for', 'a', 'an', 'to'};
    final nameParts = university.name.trim().split(RegExp(r'\s+'));
    final initials = nameParts
        .where((w) => w.isNotEmpty && !skipWords.contains(w.toLowerCase()))
        .map((w) => w[0].toUpperCase())
        .join();
    if (initials.isNotEmpty) return initials;

    // Fallback: parse domain
    const excluded = {
      'student',
      'mail',
      'www',
      'edu',
      'ac',
      'com',
      'org',
      'net',
      'kh',
    };
    final domainParts = university.domain.split('.');
    final meaningful = domainParts.where(
      (p) => p.length > 2 && !excluded.contains(p.toLowerCase()),
    );
    if (meaningful.isNotEmpty) return meaningful.first.toUpperCase();
    return domainParts.isNotEmpty ? domainParts.first.toUpperCase() : 'N/A';
  }
}

class ProfileAvatar extends StatefulWidget {
  final String? imageUrl;
  final String? displayName;
  final double radius;
  final double borderWidth;
  final double gapWidth;
  final Color borderColor;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    this.displayName,
    this.radius = 65,
    this.borderWidth = 3,
    this.gapWidth = 3,
    this.borderColor = AppColors.accent,
  });

  /// Total visual radius including gap and border
  double get totalRadius => radius + gapWidth + borderWidth;

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  @override
  void didUpdateWidget(ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  String _initials() {
    final name = widget.displayName?.trim() ?? '';
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _stableImageKey(String? url) {
    if (url == null || url.isEmpty) return '';
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    if ((uri.scheme == 'http' || uri.scheme == 'https') && uri.hasAuthority) {
      return uri.replace(query: '', fragment: '').toString();
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.imageUrl != null && widget.imageUrl!.isNotEmpty;

    return RepaintBoundary(
      child: Container(
        padding: EdgeInsets.all(widget.gapWidth),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.background,
          border: Border.all(
            color: widget.borderColor,
            width: widget.borderWidth,
          ),
        ),
        child: ClipOval(
          child: SizedBox(
            width: widget.radius * 2,
            height: widget.radius * 2,
            child: hasImage
                ? CachedNetworkImage(
                    key: ValueKey(
                      'profile_avatar_${_stableImageKey(widget.imageUrl)}',
                    ),
                    imageUrl: widget.imageUrl!,
                    fit: BoxFit.cover,
                    useOldImageOnUrlChange: true,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    placeholder: (context, url) => Container(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      child: Center(
                        child: Text(
                          _initials(),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: widget.radius * 0.42,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    child: Center(
                      child: Text(
                        _initials(),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: widget.radius * 0.42,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class ProfileStatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String? label;

  const ProfileStatItem({
    super.key,
    required this.icon,
    required this.value,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                if (label != null)
                  TextSpan(
                    text: ' $label',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Reusable profile stats row used by both current and other profile pages.
class UserStatsRow extends StatelessWidget {
  final int followers;
  final int following;
  final String major;
  final String schoolShortName;
  final double avatarTotalRadius;
  final double sideSpacing;
  final double rowHeight;
  final double detailGap;

  const UserStatsRow({
    super.key,
    required this.followers,
    required this.following,
    required this.major,
    required this.schoolShortName,
    required this.avatarTotalRadius,
    this.sideSpacing = 10,
    this.rowHeight = 30,
    this.detailGap = 10,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: avatarTotalRadius + rowHeight,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: sideSpacing),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _ProfileCountStat(
                    icon: Icons.person_add_outlined,
                    count: '$followers',
                    label: 'Followers',
                  ),
                  SizedBox(height: detailGap),
                  _ProfileCountStat(
                    icon: Icons.people_outlined,
                    count: '$following',
                    label: 'Following',
                  ),
                ],
              ),
            ),
            SizedBox(width: avatarTotalRadius * 2 + 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileStatItem(icon: Icons.school_outlined, value: major),
                  SizedBox(height: detailGap),
                  ProfileStatItem(
                    icon: Icons.verified_outlined,
                    value: schoolShortName,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCountStat extends StatelessWidget {
  final IconData icon;
  final String count;
  final String label;

  const _ProfileCountStat({
    required this.icon,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Icon-only tab bar
class ProfileSectionTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  const ProfileSectionTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildTab(icon: Icons.post_add_outlined, index: 0),
        _buildTab(icon: Icons.perm_contact_cal_outlined, index: 1),
      ],
    );
  }

  Widget _buildTab({required IconData icon, required int index}) {
    final isSelected = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2.5 : 1,
              ),
            ),
          ),
          child: Icon(
            icon,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            size: 28,
          ),
        ),
      ),
    );
  }
}

/// Data class for profile header information
class ProfileHeaderData {
  final String? coverImage;
  final String? profileImage;
  final String fullName;
  final String? bio;
  final int followerCount;
  final int followingCount;
  final String? major;
  final String schoolShortName;

  const ProfileHeaderData({
    this.coverImage,
    this.profileImage,
    required this.fullName,
    this.bio,
    required this.followerCount,
    required this.followingCount,
    this.major,
    required this.schoolShortName,
  });
}

/// Reusable profile header section consolidating cover, avatar, stats, and name/bio
class ProfileHeaderSection extends StatelessWidget {
  final ProfileHeaderData data;
  final Widget? coverOverlay;
  final Widget? avatarOverlay;
  final Widget? actionsBelow;
  final VoidCallback? onCoverTap;
  final VoidCallback? onAvatarTap;
  final bool canEditCover;
  final double avatarRadius;
  final double avatarBorder;
  final double avatarGap;
  final double coverHeight;
  final double statsDetailGap;

  const ProfileHeaderSection({
    super.key,
    required this.data,
    this.coverOverlay,
    this.avatarOverlay,
    this.actionsBelow,
    this.onCoverTap,
    this.onAvatarTap,
    this.canEditCover = false,
    this.avatarRadius = 65,
    this.avatarBorder = 3,
    this.avatarGap = 3,
    this.coverHeight = 150,
    this.statsDetailGap = 10,
  });

  double get _avatarTotalRadius => avatarRadius + avatarGap + avatarBorder;

  String _stableImageKey(String? url) {
    if (url == null || url.isEmpty) return '';
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    if ((uri.scheme == 'http' || uri.scheme == 'https') && uri.hasAuthority) {
      return uri.replace(query: '', fragment: '').toString();
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Stack(
      children: [
        Column(
          children: [
            _buildCoverSection(),
            _buildStatsRow(),
            _buildNameAndBio(textTheme),
            if (actionsBelow != null) ...[
              const SizedBox(height: 16),
              actionsBelow!,
            ],
            const SizedBox(height: 16),
          ],
        ),
        Positioned(
          top: coverHeight - _avatarTotalRadius,
          left: 0,
          right: 0,
          child: Center(child: _buildAvatar()),
        ),
      ],
    );
  }

  Widget _buildCoverSection() {
    final coverUrl = data.coverImage;
    final hasCover = coverUrl != null && coverUrl.isNotEmpty;

    return Stack(
      children: [
        GestureDetector(
          onTap: hasCover ? onCoverTap : null,
          child: SizedBox(
            height: coverHeight,
            width: double.infinity,
            child: RepaintBoundary(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  hasCover
                      ? CachedNetworkImage(
                          key: ValueKey(
                            'cover_image_${_stableImageKey(coverUrl)}',
                          ),
                          imageUrl: coverUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          useOldImageOnUrlChange: true,
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
                          placeholder: (context, url) =>
                              _buildCoverPlaceholder(isLoading: true),
                          errorWidget: (context, url, error) =>
                              _buildCoverPlaceholder(),
                        )
                      : _buildCoverPlaceholder(),
                  if (coverOverlay != null) coverOverlay!,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoverPlaceholder({bool isLoading = false}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.32),
            const Color(0xFFB7D7EA),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -24,
            right: -18,
            child: Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.22),
              ),
            ),
          ),
          Positioned(
            left: 18,
            bottom: -30,
            child: Container(
              width: 134,
              height: 134,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
          ),
          Center(
            child: isLoading
                ? const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.landscape_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        child: Text(
                          canEditCover ? 'Add a cover photo' : 'No cover photo',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: onAvatarTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ProfileAvatar(
            imageUrl: data.profileImage,
            displayName: data.fullName,
            radius: avatarRadius,
            borderWidth: avatarBorder,
            gapWidth: avatarGap,
          ),
          if (avatarOverlay != null) Positioned.fill(child: avatarOverlay!),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return UserStatsRow(
      followers: data.followerCount,
      following: data.followingCount,
      major: data.major ?? 'N/A',
      schoolShortName: data.schoolShortName,
      avatarTotalRadius: _avatarTotalRadius,
      detailGap: statsDetailGap,
    );
  }

  Widget _buildNameAndBio(TextTheme textTheme) {
    final bio = (data.bio != null && data.bio!.isNotEmpty)
        ? data.bio!
        : 'No bio yet.';
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          data.fullName,
          style: textTheme.titleLarge?.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            bio,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}

