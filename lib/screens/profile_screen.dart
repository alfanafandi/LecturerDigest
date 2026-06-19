import 'package:flutter/material.dart';
import 'package:lecturer_digest/main.dart';
import 'package:provider/provider.dart';
import 'package:lecturer_digest/core/theme/app_theme.dart';
import 'package:lecturer_digest/core/providers/app_provider.dart';
import 'package:lecturer_digest/core/widgets/brand_logo.dart';
import 'package:lecturer_digest/core/utils/responsive.dart';
import 'package:lecturer_digest/screens/main_wrapper.dart';

class ProfileScreen extends StatefulWidget {
  final bool isTab;
  const ProfileScreen({super.key, this.isTab = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  bool _isEditing = false;
  
  final List<String> _availableAvatars = [
    'assets/images/avatars/male1.png',
    'assets/images/avatars/female1.png',
    'assets/images/avatars/male2.png',
    'assets/images/avatars/female2.png',
  ];

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<AppProvider>(context, listen: false).userProfile;
    _nameController = TextEditingController(text: profile?['full_name'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveProfile({String? avatarUrl}) async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    await provider.updateUserProfile(
      name: _nameController.text,
      avatarUrl: avatarUrl,
    );
    setState(() {
      _isEditing = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Responsive.isDesktop(context);

    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final profile = provider.userProfile;
        final isDark = provider.themeMode == ThemeMode.dark;
        final currentAvatar = profile?['avatar_url'];

        return GestureDetector(
          onTap: () {
            if (_isEditing) {
              _saveProfile();
              FocusScope.of(context).unfocus();
            }
          },
          child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.background,
            body: SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 1000 : double.infinity),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Custom Header Row (Replaces Scaffold AppBar)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Row(
                            children: [
                              if (!widget.isTab) ...[
                                GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Theme.of(context).colorScheme.surfaceVariant,
                                    ),
                                    child: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary, size: 20),
                                  ),
                                ),
                              ],
                              const BrandLogo(size: 32),
                              const SizedBox(width: 8),
                              Text(
                                'LectureDigest',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppTheme.onBackground,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Integrated Header Section
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.12)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.01),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 64,
                              height: 64,
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.primary, width: 1.5),
                              ),
                              child: CircleAvatar(
                                radius: 32,
                                backgroundColor: AppTheme.surfaceContainerHigh,
                                backgroundImage: currentAvatar != null 
                                    ? (currentAvatar.startsWith('http')
                                        ? NetworkImage(currentAvatar) as ImageProvider
                                        : AssetImage(currentAvatar) as ImageProvider)
                                    : null,
                                child: currentAvatar == null 
                                    ? const Icon(Icons.person_outline_rounded, size: 32, color: AppTheme.primary)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // Name & Email
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (_isEditing)
                                         Expanded(
                                           child: TextField(
                                              controller: _nameController,
                                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                                              decoration: const InputDecoration(
                                                hintText: 'Nama kamu',
                                                isDense: true,
                                                contentPadding: EdgeInsets.zero,
                                                border: InputBorder.none,
                                              ),
                                              autofocus: true,
                                              textInputAction: TextInputAction.done,
                                              onSubmitted: (_) {
                                                _saveProfile();
                                                FocusScope.of(context).unfocus();
                                              },
                                            ),
                                         )
                                      else
                                        Flexible(
                                          child: Text(
                                            profile?['full_name'] ?? 'Mahasiswa',
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () {
                                          if (_isEditing) {
                                            _saveProfile();
                                            FocusScope.of(context).unfocus();
                                          } else {
                                            setState(() => _isEditing = true);
                                          }
                                        },
                                        icon: Icon(
                                          _isEditing ? Icons.check_circle_rounded : Icons.edit_rounded, 
                                          color: AppTheme.primary,
                                          size: 20,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        visualDensity: VisualDensity.compact,
                                        tooltip: 'Edit Profil',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    provider.currentUser?.email ?? '',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Avatar Choice
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildSectionHeader(context, 'PILIH AVATAR AI'),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 68,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: _availableAvatars.length,
                          itemBuilder: (context, index) {
                            final avatarPath = _availableAvatars[index];
                            final isSelected = currentAvatar == avatarPath;
                            
                            return GestureDetector(
                              onTap: () => _saveProfile(avatarUrl: avatarPath),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 52,
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? AppTheme.primary : Colors.transparent,
                                    width: 2.5,
                                  ),
                                  boxShadow: isSelected ? [BoxShadow(color: AppTheme.primary.withOpacity(0.2), blurRadius: 8)] : null,
                                ),
                                child: CircleAvatar(
                                  backgroundColor: AppTheme.surfaceContainerHigh,
                                  backgroundImage: AssetImage(avatarPath),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Settings Grid/List
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(context, 'PENGATURAN APLIKASI'),
                            const SizedBox(height: 10),
                            
                            _buildSettingsGroup(
                              context,
                              _buildSettingsItems(context, provider, isDark),
                            ),
                            
                            const SizedBox(height: 16),
                            _buildSectionHeader(context, 'AKUN'),
                            const SizedBox(height: 10),
                            
                            _buildSettingsGroup(
                              context,
                              [
                                _buildSettingTile(
                                  context,
                                  icon: Icons.lock_reset_rounded,
                                  title: 'Ganti Kata Sandi',
                                  onTap: () => _showPasswordDialog(context, provider),
                                ),
                                _buildSettingTile(
                                  context,
                                  icon: Icons.logout_rounded,
                                  title: 'Keluar dari Aplikasi',
                                  titleColor: Colors.redAccent,
                                  onTap: () => _showLogoutDialog(context, provider),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 100 + MediaQuery.of(context).padding.bottom),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

  List<Widget> _buildSettingsItems(BuildContext context, AppProvider provider, bool isDark) {
    return [
      _buildSettingTile(
        context,
        icon: Icons.dark_mode_rounded,
        title: 'Mode Gelap',
        subtitle: 'Kurangi ketegangan mata',
        trailing: Switch(
          value: isDark,
          onChanged: (val) => provider.toggleTheme(),
          activeColor: AppTheme.primary,
        ),
      ),
    ];
  }

  void _showLogoutDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Keluar dari Aplikasi?'),
        content: const Text('Kamu perlu masuk kembali untuk mengakses rangkuman dan data akademismu.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.signOut();
              LectureDigestApp.navigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => MainWrapper()),
                (route) => false,
              );
            }, 
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent, 
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Ya, Keluar')
          ),
        ],
      ),
    );
  }

  void _showPasswordDialog(BuildContext context, AppProvider provider) {
    final TextEditingController passController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ganti Kata Sandi'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Masukkan kata sandi baru untuk akunmu:'),
            const SizedBox(height: 16),
            TextField(
              controller: passController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Kata sandi baru',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (passController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sandi minimal 6 karakter')),
                );
                return;
              }
              
              try {
                await provider.changePassword(passController.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sandi berhasil diubah!'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal: ${e.toString()}'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Update Sandi'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context, List<Widget> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: List.generate(tiles.length * 2 - 1, (index) {
          if (index.isOdd) {
            return Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
              indent: 52,
              endIndent: 16,
            );
          }
          return tiles[index ~/ 2];
        }),
      ),
    );
  }

  Widget _buildSettingTile(BuildContext context, {
    required IconData icon, 
    required String title, 
    String? subtitle, 
    Widget? trailing,
    Color? titleColor,
    VoidCallback? onTap
  }) {
    return ListTile(
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(
        icon, 
        color: titleColor ?? Theme.of(context).colorScheme.primary, 
        size: 20
      ),
      title: Text(
        title, 
        style: TextStyle(
          fontWeight: FontWeight.bold, 
          color: titleColor ?? Theme.of(context).colorScheme.onSurface,
          fontSize: 14,
        )
      ),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 11)) : null,
      trailing: trailing ?? Icon(Icons.chevron_right, color: Colors.grey.withOpacity(0.4), size: 16),
    );
  }
}
