import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/premium_textfield.dart';
import 'widgets/profile_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late final TextEditingController _locationController;

  final ImagePicker _picker = ImagePicker();
  bool _isUploadingAvatar = false;
  String? _uploadedAvatarUrl;

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<ProfileProvider>(context, listen: false).profile;
    _nameController = TextEditingController(text: profile?.fullName ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
    _locationController = TextEditingController(text: profile?.location ?? '');
    _uploadedAvatarUrl = profile?.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 500,
      );
      if (image == null) return;
      if (!mounted) return;

      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final currentProfile = profileProvider.profile;
      if (currentProfile == null) return;

      setState(() => _isUploadingAvatar = true);

      final bytes = await image.readAsBytes();
      if (!mounted) return;

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';

      final url = await profileProvider.uploadAvatar(
        userId: currentProfile.id,
        fileBytes: bytes,
        fileName: fileName,
      );

      if (!mounted) return;

      setState(() {
        _isUploadingAvatar = false;
        if (url != null) _uploadedAvatarUrl = url;
      });

      if (url != null) {
        final updated = currentProfile.copyWith(avatarUrl: url);
        Provider.of<AuthProvider>(context, listen: false).updateCurrentUser(updated);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Avatar uploaded!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload avatar: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final currentProfile = profileProvider.profile;
    if (currentProfile == null) return;

    final updated = currentProfile.copyWith(
      fullName: _nameController.text.trim(),
      bio: _bioController.text.trim(),
      location: _locationController.text.trim(),
      avatarUrl: _uploadedAvatarUrl ?? currentProfile.avatarUrl,
    );

    final success = await profileProvider.updateProfile(updated);
    if (success && mounted) {
      Provider.of<AuthProvider>(context, listen: false).updateCurrentUser(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(profileProvider.errorMessage ?? 'Failed to update profile'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profileProvider = Provider.of<ProfileProvider>(context);
    final isLoading = profileProvider.isLoading;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: CustomAppBar(
        title: 'Edit Profile',
        showBack: true,
        actions: [
          if (!isLoading)
            TextButton(
              onPressed: _saveProfile,
              child: Text(
                'Save',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: isLoading,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppSizes.s20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: AppSizes.s16),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ProfileAvatar(
                      imageUrl: _uploadedAvatarUrl,
                      displayName: _nameController.text,
                      radius: 60,
                    ),
                    if (_isUploadingAvatar)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? AppColors.bgDark : Colors.white,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSizes.s36),
                GlassCard(
                  padding: AppSizes.cardPadding,
                  child: Column(
                    children: [
                      PremiumTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        hint: 'Your display name',
                        prefixIcon: Icon(Icons.person_outline_rounded, size: AppSizes.iconSm, color: AppColors.primary),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Name cannot be empty';
                          return null;
                        },
                      ),
                      SizedBox(height: AppSizes.s16),
                      PremiumTextField(
                        controller: _locationController,
                        label: 'Location',
                        hint: 'e.g. Seattle, WA',
                        prefixIcon: Icon(Icons.location_on_outlined, size: AppSizes.iconSm, color: AppColors.primary),
                      ),
                      SizedBox(height: AppSizes.s16),
                      PremiumTextField(
                        controller: _bioController,
                        label: 'Bio',
                        hint: 'Tell fellow readers a bit about yourself\u2026',
                        prefixIcon: Icon(Icons.info_outline_rounded, size: AppSizes.iconSm, color: AppColors.primary),
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSizes.s36),
                PremiumButton(
                  label: 'Save Changes',
                  style: PremiumButtonStyle.gradient,
                  isLoading: isLoading,
                  icon: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                  onPressed: isLoading ? null : _saveProfile,
                  height: AppSizes.buttonLg,
                  borderRadius: AppSizes.radiusMd,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
