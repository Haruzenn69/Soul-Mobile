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
import 'laporan/laporan_screen.dart';
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
  const _ShellScaffold({required this.tabs});

  final List<_TabItem> tabs;

  @override
  ConsumerState<_ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends ConsumerState<_ShellScaffold> {
  final Map<int, Widget> _tabCache = {};

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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF0F9FF), Colors.white, Color(0xFFFFFBEB)],
            stops: [0, 0.52, 1],
          ),
        ),
        child: IndexedStack(index: safeIndex, children: tabChildren),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.line)),
        ),
        child: NavigationBar(
          selectedIndex: safeIndex,
          onDestinationSelected: (i) =>
              ref.read(shellTabProvider.notifier).set(i),
          backgroundColor: Colors.white,
          indicatorColor: AppTheme.blueBg,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            for (final tab in widget.tabs)
              NavigationDestination(
                icon: Icon(tab.icon, color: AppTheme.sub),
                selectedIcon: Icon(tab.icon, color: AppTheme.blue),
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
          'Laporan',
          Icons.description_outlined,
          (_) => LaporanScreen(user: user),
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
