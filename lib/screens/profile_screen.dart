import 'package:flutter/material.dart';
import 'package:lecturer_digest/main.dart';
import 'package:provider/provider.dart';
import 'package:lecturer_digest/core/theme/app_theme.dart';
import 'package:lecturer_digest/core/providers/app_provider.dart';
import 'package:lecturer_digest/core/widgets/brand_logo.dart';
import 'package:lecturer_digest/core/utils/responsive.dart';
import 'package:lecturer_digest/screens/splash_screen.dart';
import 'package:lecturer_digest/screens/login_screen.dart';

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
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: !widget.isTab,
              leadingWidth: isDesktop ? 80 : (widget.isTab ? 0 : 70),
              leading: widget.isTab && !isDesktop ? null : Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              title: Text(
                'Profil & Pengaturan',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            body: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 1000 : double.infinity),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 0, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Integrated Header Section
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark 
                              ? [AppTheme.primary.withOpacity(0.1), AppTheme.surface]
                              : [AppTheme.primary.withOpacity(0.05), Colors.white],
                          ),
                          borderRadius: BorderRadius.circular(isDesktop ? 32 : 0),
                          boxShadow: isDesktop ? [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 40)] : null,
                        ),
                        child: Row(
                          children: [
                            // Avatar with Glow
                            Container(
                              width: isDesktop ? 120 : 80,
                              height: isDesktop ? 120 : 80,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 2),
                              ),
                              child: CircleAvatar(
                                radius: isDesktop ? 60 : 40,
                                backgroundColor: AppTheme.surfaceContainerHigh,
                                backgroundImage: currentAvatar != null 
                                    ? AssetImage(currentAvatar) 
                                    : null,
                                child: currentAvatar == null 
                                    ? Icon(Icons.person_outline_rounded, size: isDesktop ? 60 : 40, color: AppTheme.primary)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 32),
                            
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
                                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
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
                                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      const SizedBox(width: 12),
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
                                          size: 24,
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
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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

                      const SizedBox(height: 40),

                      // Avatar Choice
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildSectionHeader(context, 'PILIH AVATAR AI'),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 90,
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
                                width: 70,
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? AppTheme.primary : Colors.transparent,
                                    width: 3,
                                  ),
                                  boxShadow: isSelected ? [BoxShadow(color: AppTheme.primary.withOpacity(0.2), blurRadius: 12)] : null,
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

                      const SizedBox(height: 40),

                      // Settings Grid/List
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(context, 'PENGATURAN APLIKASI'),
                            const SizedBox(height: 16),
                            
                            if (isDesktop) 
                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                                childAspectRatio: 4,
                                children: _buildSettingsItems(context, provider, isDark),
                              )
                            else 
                              Column(
                                children: _buildSettingsItems(context, provider, isDark),
                              ),
                            
                            const SizedBox(height: 40),
                            _buildSectionHeader(context, 'AKUN'),
                            const SizedBox(height: 16),
                            
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
                      ),
                      
                      const SizedBox(height: 60),
                    ],
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
      _buildSettingTile(
        context,
        icon: Icons.notifications_active_rounded,
        title: 'Notifikasi',
        subtitle: 'Dapatkan update rangkuman AI',
        trailing: Switch(
          value: true,
          onChanged: (val) {},
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
              LectureDigestApp.navigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
              await provider.signOut();
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

  Widget _buildSettingTile(BuildContext context, {
    required IconData icon, 
    required String title, 
    String? subtitle, 
    Widget? trailing,
    Color? titleColor,
    VoidCallback? onTap
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: titleColor ?? Theme.of(context).colorScheme.primary, size: 22),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: titleColor)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 11)) : null,
        trailing: trailing ?? Icon(Icons.chevron_right, color: Colors.grey.withOpacity(0.3), size: 18),
      ),
    );
  }
}
