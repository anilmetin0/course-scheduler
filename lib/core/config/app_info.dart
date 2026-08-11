import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppInfo {
  AppInfo._();

  static const String _gitSha =
      String.fromEnvironment('GIT_SHA', defaultValue: '');
  static Future<String>? _cachedVersion;

  static Future<String> get version =>
      _cachedVersion ??= _loadVersion();

  static Future<String> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final baseVersion = info.version.trim();
      final buildNumber = info.buildNumber.trim();
      final versionWithBuild =
          buildNumber.isEmpty ? baseVersion : '$baseVersion+$buildNumber';
      final gitSuffix = _formatGitSha(_gitSha);

      if (gitSuffix.isEmpty) {
        return versionWithBuild;
      }

      return '$baseVersion-$gitSuffix';
    } catch (_) {
      final gitSuffix = _formatGitSha(_gitSha);
      return gitSuffix.isEmpty ? 'unknown' : 'unknown-$gitSuffix';
    }
  }

  static String _formatGitSha(String sha) {
    final trimmed = sha.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.length > 8 ? trimmed.substring(0, 8) : trimmed;
  }
}

final appVersionProvider = FutureProvider<String>((ref) => AppInfo.version);
