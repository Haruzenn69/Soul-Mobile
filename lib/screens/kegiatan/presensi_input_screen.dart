import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers.dart';
import '../../data/providers.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class PresensiInputScreen extends ConsumerStatefulWidget {
  const PresensiInputScreen({
    super.key,
    required this.kegiatanId,
    required this.materi,
  });

  final int kegiatanId;
  final String materi;

  @override
  ConsumerState<PresensiInputScreen> createState() =>
      _PresensiInputScreenState();
}

class _PresensiInputScreenState extends ConsumerState<PresensiInputScreen> {
  final Map<int, String> _statuses = {};
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _members = const [];
  String? _pelatihStatus;
  int? _pelatihId;
  bool _initialized = false;
  bool _saving = false;
  int _markAllRevision = 0;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initData(Map<String, dynamic> data) {
    if (_initialized) return;
    final existing = data['presensi_existing'];
    if (existing is Map) {
      existing.forEach((key, val) {
        final id = int.tryParse(key.toString());
        if (id != null && val != null) {
          _statuses[id] = val.toString();
        }
      });
    }

    final pelatih = data['pelatih'] is Map ? data['pelatih'] as Map : null;
    if (pelatih != null) {
      _pelatihId = (pelatih['id'] as num?)?.toInt();
      _pelatihStatus = data['pelatih_status'] as String? ?? 'hadir';
    }

    final rawAnggotas = data['anggotas'];
    _members = rawAnggotas is List
        ? rawAnggotas.whereType<Map>().toList(growable: false)
        : const [];
    for (final rawAnggota in _members) {
      final a = _jsonMap(rawAnggota);
      final id = (a['id'] as num?)?.toInt();
      if (id != null && !_statuses.containsKey(id)) {
        _statuses[id] = 'hadir';
      }
    }
    _initialized = true;
  }

  Future<void> _simpan() async {
    setState(() => _saving = true);
    try {
      final presensiList = _statuses.entries
          .map((e) => {'pendaftaran_id': e.key, 'status': e.value})
          .toList();

      final payload = <String, dynamic>{'presensi': presensiList};

      if (_pelatihId != null && _pelatihStatus != null) {
        payload['pelatih_presensi'] = {
          'pelatih_id': _pelatihId,
          'status': _pelatihStatus,
        };
      }

      await ref
          .read(apiClientProvider)
          .post('/ketua/kegiatan/${widget.kegiatanId}/presensi', data: payload);

      ref.invalidate(kegiatanDetailProvider(widget.kegiatanId));
      ref.invalidate(ketuaKegiatanProvider);
      ref.invalidate(ketuaDashboardProvider);
      ref.invalidate(ketuaRekapProvider);
      ref.invalidate(ketuaRekapMonthProvider(null));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Presensi berhasil disimpan!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) await showErrorDialog(context, ref, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(presensiFormProvider(widget.kegiatanId));

    return Scaffold(
      appBar: AppBar(title: Text('Presensi: ${widget.materi}')),
      body: ApiAsyncView(
        value: form,
        onRetry: () => ref.invalidate(presensiFormProvider(widget.kegiatanId)),
        builder: (context, data) {
          _initData(data);
          final anggotas = _members;
          final pelatih = data['pelatih'] is Map
              ? data['pelatih'] as Map
              : null;
          final filteredMembers = _searchQuery.isEmpty
              ? anggotas
              : anggotas
                    .where((raw) {
                      final nama = Pendaftaran.fromJson(_jsonMap(raw))
                          .siswaNama;
                      return (nama ?? '').toLowerCase().contains(_searchQuery);
                    })
                    .toList(growable: false);

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SectionTitle('Presensi Pelatih'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.line),
                        ),
                        child: pelatih == null
                            ? Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: AppTheme.blueBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.info_outline_rounded,
                                      color: AppTheme.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Pelatih belum ada di ekskul ini.',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AppTheme.sub,
                                        fontSize: 12.5,
                                        height: 1.4,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  const Icon(
                                    Icons.sports,
                                    color: AppTheme.blue,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Pelatih: ${pelatih['nama'] ?? '-'}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AppTheme.ink,
                                        fontSize: 13.5,
                                        height: 1.25,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _StatusSelector(
                                    selected: _pelatihStatus ?? 'hadir',
                                    onChanged: (val) =>
                                        setState(() => _pelatihStatus = val),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: SectionTitle(
                              'Kehadiran Siswa (${filteredMembers.length})',
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.done_all, size: 16),
                            label: const Text('Semua Hadir'),
                            onPressed: () {
                              setState(() {
                                for (final a in anggotas) {
                                  final id = (_jsonMap(a)['id'] as num?)
                                      ?.toInt();
                                  if (id != null) _statuses[id] = 'hadir';
                                }
                                _markAllRevision++;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        onChanged: (value) => setState(
                          () => _searchQuery = value.trim().toLowerCase(),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Cari nama siswa...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchQuery.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Hapus pencarian',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                        ),
                        controller: _searchController,
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: filteredMembers.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: EmptyState(
                            title: anggotas.isEmpty
                                ? 'Belum ada anggota aktif untuk presensi'
                                : 'Nama siswa tidak ditemukan',
                            subtitle: anggotas.isEmpty
                                ? null
                                : 'Coba kata kunci nama yang lain.',
                            icon: anggotas.isEmpty
                                ? Icons.person_off_outlined
                                : Icons.search_off_rounded,
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final anggotaMap = _jsonMap(filteredMembers[index]);
                          final id = (anggotaMap['id'] as num?)?.toInt() ?? 0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _AnggotaPresensiTile(
                              key: ValueKey(id),
                              pendaftaran: Pendaftaran.fromJson(anggotaMap),
                              selectedStatus: _statuses[id] ?? 'hadir',
                              markAllRevision: _markAllRevision,
                              onStatusChanged: (status) =>
                                  _statuses[id] = status,
                            ),
                          );
                        }, childCount: filteredMembers.length),
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ElevatedButton(
            onPressed: _saving || !form.hasValue ? null : _simpan,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Simpan Presensi'),
          ),
        ),
      ),
    );
  }
}

Map<String, dynamic> _jsonMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw const FormatException('Data anggota tidak valid.');
}

class _AnggotaPresensiTile extends StatefulWidget {
  const _AnggotaPresensiTile({
    super.key,
    required this.pendaftaran,
    required this.selectedStatus,
    required this.markAllRevision,
    required this.onStatusChanged,
  });

  final Pendaftaran pendaftaran;
  final String selectedStatus;
  final int markAllRevision;
  final ValueChanged<String> onStatusChanged;

  @override
  State<_AnggotaPresensiTile> createState() => _AnggotaPresensiTileState();
}

class _AnggotaPresensiTileState extends State<_AnggotaPresensiTile> {
  late String _selectedStatus = widget.selectedStatus;

  @override
  void didUpdateWidget(covariant _AnggotaPresensiTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.markAllRevision != widget.markAllRevision) {
      _selectedStatus = 'hadir';
    }
  }

  @override
  Widget build(BuildContext context) {
    final nama = widget.pendaftaran.siswaNama ?? 'Anggota';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              nama,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.ink,
                fontSize: 13,
                height: 1.3,
                letterSpacing: 0.05,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _StatusSelector(
            selected: _selectedStatus,
            onChanged: (status) {
              setState(() => _selectedStatus = status);
              widget.onStatusChanged(status);
            },
          ),
        ],
      ),
    );
  }
}

class _StatusSelector extends StatelessWidget {
  const _StatusSelector({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = [
      ('hadir', 'Hadir', Color(0xFF16803C)),
      ('izin', 'Izin', Color(0xFF1E5AA8)),
      ('sakit', 'Sakit', Color(0xFFC77700)),
      ('alpha', 'Alpha', Color(0xFFE11D48)),
    ];
    final selectedOption = selected.trim().isEmpty
        ? null
        : options.where((option) => option.$1 == selected).toList();
    final badgeColorPart = selectedOption == null || selectedOption.isEmpty
        ? null
        : selectedOption.first.$3;
    final badgeColor = badgeColorPart ?? AppTheme.sub;
    final badgeLabel = badgeColorPart == null ? 'Pilih' : selectedOption!.first.$2;

    return PopupMenuButton<String>(
      tooltip: 'Ubah status kehadiran',
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final option in options)
          PopupMenuItem<String>(
            value: option.$1,
            child: Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: option.$3,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(option.$2),
                if (option.$1 == selected) ...[
                  const Spacer(),
                  Icon(Icons.check_rounded, size: 18, color: option.$3),
                ],
              ],
            ),
          ),
      ],
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: badgeColor.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              badgeLabel,
              style: GoogleFonts.plusJakartaSans(
                color: badgeColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down, size: 18, color: badgeColor),
          ],
        ),
      ),
    );
  }
}
