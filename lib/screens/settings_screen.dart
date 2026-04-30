import 'package:flutter/material.dart';
import 'package:lecturer_digest/core/theme/app_theme.dart';
import 'package:lecturer_digest/core/widgets/brand_logo.dart';
import 'package:lecturer_digest/core/providers/app_provider.dart';
import 'package:lecturer_digest/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:lecturer_digest/core/utils/responsive.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: isDesktop ? 80 : 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: isDesktop ? Row(
          children: [
            const BrandLogo(size: 28),
            const SizedBox(width: 8),
            Text('LectureDigest', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          ],
        ) : Text('Pengaturan', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        centerTitle: !isDesktop,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 1000 : double.infinity),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                Consumer<AppProvider>(
                  builder: (context, provider, child) {
                    final user = provider.currentUser;
                    final emailPrefix = user?.email?.split('@')[0] ?? 'Pengguna';
                    final displayName = emailPrefix.isNotEmpty 
                        ? (emailPrefix[0].toUpperCase() + emailPrefix.substring(1))
                        : 'Pengguna';

                    return Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.1)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 24, offset: const Offset(0, 8))
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: isDesktop ? 100 : 80,
                            height: isDesktop ? 100 : 80,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Center(
                              child: Text(
                                displayName[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: isDesktop ? 40 : 32,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: const Text(
                                    'ANGGOTA PREMIUM',
                                    style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  displayName,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, fontSize: isDesktop ? 28 : 20),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user?.email ?? 'Tidak ada email',
                                  style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          if (isDesktop) ...[
                            const SizedBox(width: 24),
                            ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.edit_rounded, size: 18),
                              label: const Text('Edit Profil'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(16)),
                              child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 48),

                const Text('PENGATURAN UMUM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppTheme.primary)),
                const SizedBox(height: 16),

                if (isDesktop) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildSettingsItem(Icons.person_outline_rounded, 'Akun', 'Keamanan, Email, dan Langganan', AppTheme.secondary, isDesktop)),
                      const SizedBox(width: 24),
                      Expanded(child: _buildAppPreferences(isDesktop)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _buildSmallSettingItem(Icons.notifications_none_rounded, 'Notifikasi', isDesktop)),
                      const SizedBox(width: 24),
                      Expanded(child: _buildSmallSettingItem(Icons.help_outline_rounded, 'Bantuan & Dukungan', isDesktop)),
                    ],
                  ),
                ] else ...[
                  _buildSettingsItem(Icons.person_outline_rounded, 'Akun', 'Keamanan, Email, dan Langganan', AppTheme.secondary, isDesktop),
                  const SizedBox(height: 16),
                  _buildAppPreferences(isDesktop),
                  const SizedBox(height: 16),
                  _buildSmallSettingItem(Icons.notifications_none_rounded, 'Notifikasi', isDesktop),
                  const SizedBox(height: 16),
                  _buildSmallSettingItem(Icons.help_outline_rounded, 'Bantuan & Dukungan', isDesktop),
                ],
                const SizedBox(height: 48),

                // Logout
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isDesktop ? 400 : double.infinity),
                    child: InkWell(
                      onTap: () async {
                        final provider = Provider.of<AppProvider>(context, listen: false);
                        await provider.logout();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.red.withOpacity(0.1)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
                            SizedBox(width: 12),
                            Text('Keluar Akun', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppPreferences(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.tertiary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.settings_suggest_rounded, color: AppTheme.tertiary, size: 20)),
              const SizedBox(width: 12),
              const Text('Preferensi Aplikasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 24),
          _buildToggleRow('Mode Gelap', 'Gunakan tema gelap sistem', false),
          const Divider(height: 32),
          _buildActionRow('Bahasa', 'Indonesia', 'Ubah'),
        ],
      ),
    );
  }

  Widget _buildToggleRow(String title, String subtitle, bool value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
        Switch(value: value, onChanged: (v){}, activeColor: AppTheme.primary),
      ],
    );
  }

  Widget _buildActionRow(String title, String current, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 2),
            Text('Saat ini: $current', style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
        Text(action, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 13)),
      ],
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, String subtitle, Color color, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.outlineVariant),
        ],
      ),
    );
  }

  Widget _buildSmallSettingItem(IconData icon, String title, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppTheme.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.outlineVariant, size: 18),
        ],
      ),
    );
  }
}
