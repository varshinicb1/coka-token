import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';

final _log = Logger('UpdateService');

class PlatformUpdate {
  final String downloadUrl;
  final String version;
  PlatformUpdate({required this.downloadUrl, required this.version});

  factory PlatformUpdate.fromMap(Map<String, dynamic> map) => PlatformUpdate(
        downloadUrl: map['downloadUrl'] as String? ?? '',
        version: map['version'] as String? ?? '',
      );
}

class UpdateInfo {
  final String latestVersion;
  final int latestBuild;
  final String minVersion;
  final String releaseNotes;
  final PlatformUpdate? windows;
  final PlatformUpdate? android;

  UpdateInfo({
    required this.latestVersion,
    required this.latestBuild,
    required this.minVersion,
    required this.releaseNotes,
    this.windows,
    this.android,
  });

  factory UpdateInfo.fromMap(Map<String, dynamic> map) {
    final platforms = map['platforms'] as Map<String, dynamic>? ?? {};
    return UpdateInfo(
      latestVersion: map['latestVersion'] as String? ?? '1.0.0',
      latestBuild: map['latestBuild'] as int? ?? 1,
      minVersion: map['minVersion'] as String? ?? '1.0.0',
      releaseNotes: map['releaseNotes'] as String? ?? '',
      windows: platforms['windows'] != null
          ? PlatformUpdate.fromMap(platforms['windows'] as Map<String, dynamic>)
          : null,
      android: platforms['android'] != null
          ? PlatformUpdate.fromMap(platforms['android'] as Map<String, dynamic>)
          : null,
    );
  }
}

class UpdateService {
  static final UpdateService _instance = UpdateService._();
  factory UpdateService() => _instance;
  UpdateService._();

  static const String _versionUrl = 'https://coka-token.web.app/version.json';
  static const Duration _timeout = Duration(seconds: 10);

  UpdateInfo? _cached;
  bool _checked = false;

  bool get hasChecked => _checked;
  UpdateInfo? get cached => _cached;

  Future<UpdateInfo?> fetchLatest() async {
    try {
      final response = await http
          .get(Uri.parse(_versionUrl))
          .timeout(_timeout);
      if (response.statusCode != 200) {
        _log.warning('Version check returned ${response.statusCode}');
        return null;
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      _cached = UpdateInfo.fromMap(json);
      _checked = true;
      return _cached;
    } catch (e, st) {
      _log.fine('Version check failed', e, st);
      return null;
    }
  }

  Future<UpdateInfo?> check() async {
    final remote = await fetchLatest();
    if (remote == null) return null;

    final local = await PackageInfo.fromPlatform();
    final localBuild = int.tryParse(local.buildNumber) ?? 0;
    final localVersion = local.version;

    if (remote.latestBuild > localBuild && remote.latestVersion != localVersion) {
      _log.info('Update available: ${remote.latestVersion} (build ${remote.latestBuild})');
      return remote;
    }

    return null;
  }
}
