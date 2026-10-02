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
  String? _pelatihStatus;
  int? _pelatihId;
  bool _initialized = false;
  bool _saving = false;

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

    final anggotas = listOf(data, 'anggotas');
    for (final a in anggotas) {
      final id = (a['id'] as num?)?.toInt();
      if (id != null && !_statuses.containsKey(id)) {
        _statuses[id] = 'hadir'; // default hadir
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
        builder: (context, data) {
          _initData(data);
          final anggotas = listOf(data, 'anggotas');
          final pelatih = data['pelatih'] is Map
              ? data['pelatih'] as Map
              : null;

          if (anggotas.isEmpty && pelatih == null) {
            return const EmptyState(
              title: 'Belum ada anggota aktif untuk presensi',
              icon: Icons.person_off_outlined,
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              if (pelatih != null) ...[
                const SectionTitle('Presensi Pelatih'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.ink,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _StatusSelector(
                        selected: _pelatihStatus ?? 'hadir',
                        onChanged: (val) =>
                            setState(() => _pelatihStatus = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SectionTitle('Anggota (${anggotas.length})'),
                  TextButton.icon(
                    icon: const Icon(Icons.done_all, size: 16),
                    label: const Text('Semua Hadir'),
                    onPressed: () {
                      setState(() {
                        for (final a in anggotas) {
                          final id = (a['id'] as num?)?.toInt();
                          if (id != null) _statuses[id] = 'hadir';
                        }
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final a in anggotas) ...[
                _AnggotaPresensiTile(
                  pendaftaran: Pendaftaran.fromJson(a),
                  selectedStatus:
                      _statuses[(a['id'] as num).toInt()] ?? 'hadir',
                  onStatusChanged: (status) {
                    setState(() {
                      _statuses[(a['id'] as num).toInt()] = status;
                    });
                  },
                ),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ElevatedButton(
            onPressed: _saving ? null : _simpan,
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

class _AnggotaPresensiTile extends StatelessWidget {
  const _AnggotaPresensiTile({
    required this.pendaftaran,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  final Pendaftaran pendaftaran;
  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final nama = pendaftaran.siswaNama ?? 'Anggota';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nama,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.ink,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _StatusSelector(selected: selectedStatus, onChanged: onStatusChanged),
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

    return Row(
      children: [
        for (final opt in options)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onChanged(opt.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: selected == opt.$1
                        ? opt.$3.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected == opt.$1 ? opt.$3 : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      opt.$2,
                      style: GoogleFonts.plusJakartaSans(
                        color: selected == opt.$1 ? opt.$3 : AppTheme.sub,
                        fontSize: 12,
                        fontWeight: selected == opt.$1
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
