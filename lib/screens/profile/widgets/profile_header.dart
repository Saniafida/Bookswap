import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../models/user_model.dart';
import '../../../widgets/glass_card.dart';
import 'profile_avatar.dart';

class ProfileHeader extends StatelessWidget {
  final UserModel profile;
  final bool isOwnProfile;
  final int listingsCount;

  const ProfileHeader({
    super.key,
    required this.profile,
    required this.isOwnProfile,
    required this.listingsCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.s20, AppSizes.s16, AppSizes.s20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ProfileAvatar(
            imageUrl: profile.avatarUrl,
            displayName: profile.fullName,
            radius: 52,
          ),
          SizedBox(height: AppSizes.s16),
          Text(
            profile.fullName,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          if (isOwnProfile) ...[
            SizedBox(height: AppSizes.s2),
            Text(
              profile.email,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: isDark ? Colors.white54 : AppColors.textMuted,
              ),
            ),
          ],
          if (profile.location != null && profile.location!.isNotEmpty) ...[
            SizedBox(height: AppSizes.s6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_rounded, size: 14, color: AppColors.primary),
                SizedBox(width: AppSizes.s4),
                Flexible(
                  child: Text(
                    profile.location!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            SizedBox(height: AppSizes.s16),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              borderRadius: AppSizes.radiusMd,
              child: Text(
                profile.bio!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ),
          ],
          SizedBox(height: AppSizes.s20),
          GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatItem(label: 'Swaps', value: profile.swapCount.toString()),
                Container(
                  height: 28,
                  width: 1,
                  color: isDark ? Colors.white10 : AppColors.divider,
                ),
                _StatItem(label: 'Listings', value: listingsCount.toString()),
              ],
            ),
          ),
          SizedBox(height: AppSizes.s28),
          Row(
            children: [
              Flexible(
                child: Text(
                  isOwnProfile ? 'My Items' : 'Items',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(width: AppSizes.s8),
              Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                boxShadow: AppColors.primaryGlowShadow,
              ),
              child: Text(
                listingsCount.toString(),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: AppSizes.s4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white54 : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
