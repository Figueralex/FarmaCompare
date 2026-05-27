import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../widgets/update_dialog.dart';

class UpdateInfo {
  final bool hasUpdate;
  final String latestVersionName;
  final int latestBuildNumber;
  final String apkUrl;
  final bool forceUpdate;
  final String releaseNotes;

  UpdateInfo({
    required this.hasUpdate,
    required this.latestVersionName,
    required this.latestBuildNumber,
    required this.apkUrl,
    required this.forceUpdate,
    required this.releaseNotes,
  });

  factory UpdateInfo.noUpdate() {
    return UpdateInfo(
      hasUpdate: false,
      latestVersionName: '',
      latestBuildNumber: 0,
      apkUrl: '',
      forceUpdate: false,
      releaseNotes: '',
    );
  }
}

class UpdateService {
  static final _supabase = Supabase.instance.client;

  /// Verifica si hay una nueva versión en Supabase comparándola con la instalada localmente.
  static Future<UpdateInfo> checkForUpdate() async {
    try {
      // 1. Obtener la información de la versión actual del dispositivo
      final packageInfo = await PackageInfo.fromPlatform();
      var localBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;
      
      // Normalizar el build number si se compiló con --split-per-abi (ej: 2039 -> 39)
      if (localBuildNumber >= 1000) {
        localBuildNumber = localBuildNumber % 1000;
      }
      
      print("📱 Versión Local: ${packageInfo.version} (Build $localBuildNumber)");

      // 2. Obtener el registro de versión más reciente desde Supabase
      final response = await _supabase
          .from('app_version')
          .select()
          .order('version_code', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        final remoteBuildNumber = response['version_code'] as int;
        final remoteVersionName = response['version_name'] as String;
        final apkUrl = response['apk_url'] as String;
        final forceUpdate = response['force_update'] as bool? ?? false;
        final releaseNotes = response['release_notes'] as String? ?? 'Novedades de la versión';

        print("☁️ Versión Remota: $remoteVersionName (Build $remoteBuildNumber)");

        if (remoteBuildNumber > localBuildNumber) {
          return UpdateInfo(
            hasUpdate: true,
            latestVersionName: remoteVersionName,
            latestBuildNumber: remoteBuildNumber,
            apkUrl: apkUrl,
            forceUpdate: forceUpdate,
            releaseNotes: releaseNotes,
          );
        }
      }
    } catch (e) {
      print("❌ Error al verificar actualizaciones: $e");
    }
    return UpdateInfo.noUpdate();
  }

  /// Ejecuta el proceso de verificación y muestra el modal si hay una nueva versión disponible.
  static Future<void> checkAndShowUpdateDialog(BuildContext context) async {
    final updateInfo = await checkForUpdate();
    if (updateInfo.hasUpdate && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: !updateInfo.forceUpdate, // No se puede cerrar si es obligatoria
        builder: (context) => PopScope(
          canPop: !updateInfo.forceUpdate, // No permite salir usando botón atrás de Android
          child: UpdateDialog(updateInfo: updateInfo),
        ),
      );
    }
  }
}
