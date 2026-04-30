import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lecturer_digest/core/providers/app_provider.dart';
import 'package:lecturer_digest/core/theme/app_theme.dart';

class WebSidebar extends StatelessWidget {
  const WebSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final currentIndex = provider.currentTabIndex;

    return Container(
      width: 280,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh.withOpacity(0.8),
        border: Border(
          right: BorderSide(
            color: AppTheme.outlineVariant.withOpacity(0.2),
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Branding
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LectureDigest',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ACADEMIC SYNTHESIS',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      letterSpacing: 2.0,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.onSurfaceVariant.withOpacity(0.5),
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 64),

                          // Navigation Items
                          _SidebarItem(
                            icon: Icons.home_filled,
                            label: 'Home',
                            isActive: currentIndex == 0,
                            onTap: () => provider.setTabIndex(0),
                          ),
                          _SidebarItem(
                            icon: Icons.library_books_rounded,
                            label: 'Courses',
                            isActive: currentIndex == 1,
                            onTap: () => provider.setTabIndex(1),
                          ),
                          _SidebarItem(
                            icon: Icons.auto_awesome_rounded,
                            label: 'AI Tools',
                            isActive: currentIndex == 2,
                            onTap: () => provider.setTabIndex(2),
                          ),
                          _SidebarItem(
                            icon: Icons.groups_rounded,
                            label: 'Collab',
                            isActive: false, // Placeholder
                            onTap: () {},
                          ),
                          _SidebarItem(
                            icon: Icons.account_circle_rounded,
                            label: 'Profile',
                            isActive: currentIndex == 3,
                            onTap: () => provider.setTabIndex(3),
                          ),

                          const Spacer(),
                          const SizedBox(height: 32),

                          // Action Button
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.primary, AppTheme.primaryContainer],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                // Action for Summarize New
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Summarize New',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Footer Links
                          _FooterItem(
                            icon: Icons.help_outline_rounded,
                            label: 'Help',
                            onTap: () {},
                          ),
                          _FooterItem(
                            icon: Icons.logout_rounded,
                            label: 'Logout',
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white.withOpacity(0.5) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: isActive
                ? Border(
                    right: BorderSide(
                      color: AppTheme.primary,
                      width: 4,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive ? AppTheme.primary : AppTheme.onSurfaceVariant.withOpacity(0.7),
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: isActive ? AppTheme.primary : AppTheme.onSurfaceVariant.withOpacity(0.7),
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FooterItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.onSurfaceVariant.withOpacity(0.6)),
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurfaceVariant.withOpacity(0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
