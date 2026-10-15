import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'anggota/anggota_screen.dart';
import 'aktivitas/siswa_aktivitas_screen.dart';
import 'beranda/ketua_beranda.dart';
import 'beranda/siswa_beranda.dart';
import 'katalog/katalog_screen.dart';
import 'kegiatan/kegiatan_screen.dart';
import 'menu/ketua_menu_screen.dart';
import 'notifikasi/notifikasi_screen.dart';
import 'profil/profil_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return user.isKetua ? KetuaShell(user: user) : SiswaShell(user: user);
  }
}

class _TabItem {
  const _TabItem(this.label, this.icon, this.builder);

  final String label;
  final IconData icon;
  final WidgetBuilder builder;
}

class _ShellScaffold extends ConsumerStatefulWidget {
  const _ShellScaffold({required this.tabs, required this.user});

  final List<_TabItem> tabs;
  final AuthUser user;

  @override
  ConsumerState<_ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends ConsumerState<_ShellScaffold> {
  final Map<int, Widget> _tabCache = {};

  @override
  void didUpdateWidget(covariant _ShellScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user) _tabCache.clear();
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(shellTabProvider);
    // The tab provider is shared by both role shells. A user can therefore
    // leave a higher tab index in the ketua shell and then return to the
    // shorter siswa shell. NavigationBar requires the index to be valid.
    final safeIndex = index >= 0 && index < widget.tabs.length ? index : 0;
    final tabChildren = List<Widget>.generate(widget.tabs.length, (i) {
      final cachedTab = _tabCache[i];
      if (cachedTab != null) return cachedTab;
      if (i != safeIndex) return const SizedBox.shrink();

      final tab = widget.tabs[i].builder(context);
      _tabCache[i] = tab;
      return tab;
    });
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
                ? const [
                    AppTheme.darkCanvas,
                    AppTheme.darkSurface,
                    AppTheme.darkCanvas,
                  ]
                : const [AppTheme.canvas, Colors.white, AppTheme.canvas],
            stops: const [0, 0.52, 1],
          ),
        ),
        child: IndexedStack(index: safeIndex, children: tabChildren),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: safeIndex,
          onDestinationSelected: (i) =>
              ref.read(shellTabProvider.notifier).set(i),
          backgroundColor: Theme.of(context).colorScheme.surface,
          indicatorColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            for (final tab in widget.tabs)
              NavigationDestination(
                icon: Icon(
                  tab.icon,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                selectedIcon: Icon(
                  tab.icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
                label: tab.label,
              ),
          ],
        ),
      ),
    );
  }
}

class SiswaShell extends StatelessWidget {
  const SiswaShell({super.key, required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return _ShellScaffold(
      user: user,
      tabs: [
        _TabItem(
          'Beranda',
          Icons.home_outlined,
          (_) => BerandaSiswa(user: user),
        ),
        _TabItem(
          'Ekskul',
          Icons.explore_outlined,
          (_) => KatalogScreen(user: user),
        ),
        _TabItem(
          'Aktivitas',
          Icons.fact_check_outlined,
          (_) => const SiswaAktivitasScreen(),
        ),
        _TabItem(
          'Notifikasi',
          Icons.notifications_outlined,
          (_) => NotifikasiScreen(isKetua: false),
        ),
        _TabItem(
          'Profil',
          Icons.person_outline,
          (_) => ProfilScreen(user: user),
        ),
      ],
    );
  }
}

class KetuaShell extends StatelessWidget {
  const KetuaShell({super.key, required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return _ShellScaffold(
      user: user,
      tabs: [
        _TabItem(
          'Beranda',
          Icons.home_outlined,
          (_) => BerandaKetua(user: user),
        ),
        _TabItem(
          'Anggota',
          Icons.groups_outlined,
          (_) => AnggotaScreen(user: user, isKetua: true),
        ),
        _TabItem(
          'Kegiatan',
          Icons.calendar_month_outlined,
          (_) => KegiatanScreen(user: user),
        ),
        _TabItem(
          'Notifikasi',
          Icons.notifications_outlined,
          (_) => NotifikasiScreen(isKetua: true),
        ),
        _TabItem(
          'Menu',
          Icons.menu_rounded,
          (_) => KetuaMenuScreen(user: user),
        ),
      ],
    );
  }
}
