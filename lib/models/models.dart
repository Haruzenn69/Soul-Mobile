class Kelas {
  final int id;
  final String nama;
  final String tingkat;
  final String jurusan;
  final String jurusanLabel;
  final String rombel;

  const Kelas({
    required this.id,
    required this.nama,
    required this.tingkat,
    required this.jurusan,
    required this.jurusanLabel,
    required this.rombel,
  });

  factory Kelas.fromJson(Map<String, dynamic> j) => Kelas(
    id: (j['id'] as num).toInt(),
    nama: j['nama'] as String? ?? '',
    tingkat: j['tingkat'] as String? ?? '',
    jurusan: j['jurusan'] as String? ?? '',
    jurusanLabel: j['jurusan_label'] as String? ?? '',
    rombel: j['rombel'] as String? ?? '',
  );
}

class Siswa {
  final int id;
  final String nama;
  final String nis;
  final String jenisKelamin;
  final String jabatan;
  final bool isKetua;
  final bool isProfileComplete;
  final Kelas? kelas;

  const Siswa({
    required this.id,
    required this.nama,
    required this.nis,
    required this.jenisKelamin,
    required this.jabatan,
    required this.isKetua,
    required this.isProfileComplete,
    this.kelas,
  });

  factory Siswa.fromJson(Map<String, dynamic>? j) => Siswa(
    id: (j?['id'] as num?)?.toInt() ?? 0,
    nama: j?['nama'] as String? ?? '',
    nis: j?['nis'] as String? ?? '',
    jenisKelamin: j?['jenis_kelamin'] as String? ?? '',
    jabatan: j?['jabatan'] as String? ?? 'siswa',
    isKetua: j?['is_ketua'] as bool? ?? false,
    isProfileComplete: j?['is_profile_complete'] as bool? ?? false,
    kelas: j?['kelas'] is Map
        ? Kelas.fromJson(j!['kelas'] as Map<String, dynamic>)
        : null,
  );
}

class Pembina {
  final int id;
  final String nama;

  const Pembina({required this.id, required this.nama});

  factory Pembina.fromJson(Map<String, dynamic>? j) => Pembina(
    id: (j?['id'] as num?)?.toInt() ?? 0,
    nama: j?['nama'] as String? ?? '',
  );
}

class Ekskul {
  final int id;
  final String namaEkskul;
  final String? tagline;
  final String? deskripsi;
  final String? tujuan;
  final String? jadwal;
  final String? logo;
  final String? cover;
  final bool isOpenRecruitment;
  final bool status;
  final int anggotaCount;
  final Pembina? pembina;
  final String? pembinaLabel;

  const Ekskul({
    required this.id,
    required this.namaEkskul,
    this.tagline,
    this.deskripsi,
    this.tujuan,
    this.jadwal,
    this.logo,
    this.cover,
    required this.isOpenRecruitment,
    required this.status,
    required this.anggotaCount,
    this.pembina,
    this.pembinaLabel,
  });

  factory Ekskul.fromJson(Map<String, dynamic>? j) {
    return Ekskul(
      id: (j?['id'] as num?)?.toInt() ?? 0,
      namaEkskul: j?['nama_ekskul'] as String? ?? '',
      tagline: j?['tagline'] as String?,
      deskripsi: j?['deskripsi'] as String?,
      tujuan: j?['tujuan'] as String?,
      jadwal: j?['jadwal'] as String?,
      logo: j?['logo'] as String?,
      cover: j?['cover'] as String?,
      isOpenRecruitment: j?['is_open_recruitment'] as bool? ?? false,
      status: j?['status'] as bool? ?? false,
      anggotaCount: (j?['anggota_count'] as num?)?.toInt() ?? 0,
      pembina: j?['pembina'] is Map
          ? Pembina.fromJson(j!['pembina'] as Map<String, dynamic>)
          : null,
      pembinaLabel: j?['pembina'] is String ? (j?['pembina'] as String) : null,
    );
  }

  String get statusLabel =>
      isOpenRecruitment && status ? 'Buka Pendaftaran' : 'Tutup';
}

class Pendaftaran {
  final int id;
  final String status;
  final String statusLabel;
  final bool isActive;
  final String? tanggalDaftar;
  final String? alasan;
  final Ekskul? ekskul;
  final Map<String, dynamic>? siswaRaw;

  const Pendaftaran({
    required this.id,
    required this.status,
    required this.statusLabel,
    required this.isActive,
    this.tanggalDaftar,
    this.alasan,
    this.ekskul,
    this.siswaRaw,
  });

  factory Pendaftaran.fromJson(Map<String, dynamic>? j) => Pendaftaran(
    id: (j?['id'] as num?)?.toInt() ?? 0,
    status: j?['status'] as String? ?? 'pending',
    statusLabel: j?['status_label'] as String? ?? 'Pending',
    isActive: j?['is_active'] as bool? ?? false,
    tanggalDaftar: j?['tanggal_daftar'] as String?,
    alasan: j?['alasan'] as String?,
    ekskul: j?['ekskul'] is Map
        ? Ekskul.fromJson(j!['ekskul'] as Map<String, dynamic>)
        : null,
    siswaRaw: j?['siswa'] is Map
        ? Map<String, dynamic>.from(j!['siswa'] as Map)
        : null,
  );

  String? get siswaNama => siswaRaw?['nama'] as String?;
}

class Kegiatan {
  final int id;
  final String materi;
  final String? jenisKegiatan;
  final bool isEvent;
  final String? deskripsi;
  final String? dokumentasi;
  final String? tanggalKegiatan;
  final String? tanggalBerakhir;
  final String tanggalText;
  final int? presensisCount;
  final int? hadirCount;

  const Kegiatan({
    required this.id,
    required this.materi,
    this.jenisKegiatan,
    required this.isEvent,
    this.deskripsi,
    this.dokumentasi,
    this.tanggalKegiatan,
    this.tanggalBerakhir,
    required this.tanggalText,
    this.presensisCount,
    this.hadirCount,
  });

  factory Kegiatan.fromJson(Map<String, dynamic>? j) => Kegiatan(
    id: (j?['id'] as num?)?.toInt() ?? 0,
    materi: j?['materi'] as String? ?? '',
    jenisKegiatan: j?['jenis_kegiatan'] as String?,
    isEvent: j?['is_event'] as bool? ?? false,
    deskripsi: j?['deskripsi'] as String?,
    dokumentasi: j?['dokumentasi'] as String?,
    tanggalKegiatan: j?['tanggal_kegiatan'] as String?,
    tanggalBerakhir: j?['tanggal_berakhir'] as String?,
    tanggalText: j?['tanggal_text'] as String? ?? '',
    presensisCount: (j?['presensis_count'] as num?)?.toInt(),
    hadirCount: (j?['hadir_count'] as num?)?.toInt(),
  );
}

class Notifikasi {
  final int id;
  final String judul;
  final String pesan;
  final String? tipe;
  final bool isRead;
  final String? createdAt;
  final String createdLabel;

  const Notifikasi({
    required this.id,
    required this.judul,
    required this.pesan,
    this.tipe,
    required this.isRead,
    this.createdAt,
    required this.createdLabel,
  });

  factory Notifikasi.fromJson(Map<String, dynamic>? j) => Notifikasi(
    id: (j?['id'] as num?)?.toInt() ?? 0,
    judul: j?['judul'] as String? ?? '',
    pesan: j?['pesan'] as String? ?? '',
    tipe: j?['tipe'] as String?,
    isRead: j?['is_read'] as bool? ?? false,
    createdAt: j?['created_at'] as String?,
    createdLabel: j?['created_label'] as String? ?? '',
  );
}

class AuthUser {
  final int id;
  final String username;
  final String email;
  final String role;
  final bool needsOnboarding;
  final bool needsProfileCompletion;
  final Siswa? siswa;
  final Ekskul? aktivEkskul;
  final String? jabatan;

  const AuthUser({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.needsOnboarding,
    required this.needsProfileCompletion,
    this.siswa,
    this.aktivEkskul,
    this.jabatan,
  });

  factory AuthUser.fromJson(Map<String, dynamic>? j) {
    final jabatanRaw = j?['jabatan'] as String?;
    return AuthUser(
      id: (j?['id'] as num?)?.toInt() ?? 0,
      username: j?['username'] as String? ?? '',
      email: j?['email'] as String? ?? '',
      role: j?['role'] as String? ?? 'siswa',
      needsOnboarding: j?['needs_onboarding'] as bool? ?? false,
      needsProfileCompletion: j?['needs_profile_completion'] as bool? ?? false,
      siswa: j?['siswa'] is Map
          ? Siswa.fromJson(j!['siswa'] as Map<String, dynamic>)
          : null,
      aktivEkskul: j?['aktiv_ekskul'] is Map
          ? Ekskul.fromJson(j!['aktiv_ekskul'] as Map<String, dynamic>)
          : null,
      jabatan:
          jabatanRaw ??
          (j?['siswa'] is Map
              ? (j!['siswa'] as Map)['jabatan'] as String?
              : null),
    );
  }

  bool get isKetua => siswa?.isKetua ?? false;

  String get namaTampilan => siswa?.nama ?? username;
}
