import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';
import '../services/update_service.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String? _errorMessage;

  void _startUpdate() {
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _errorMessage = null;
    });

    try {
      OtaUpdate()
          .execute(
        widget.updateInfo.apkUrl,
        destinationFilename: 'farmacompare_update.apk',
      )
          .listen(
        (OtaEvent event) {
          setState(() {
            switch (event.status) {
              case OtaStatus.DOWNLOADING:
                _progress = double.tryParse(event.value ?? '0') ?? 0.0;
                break;
              case OtaStatus.INSTALLING:
              case OtaStatus.INSTALLATION_DONE:
                _isDownloading = false;
                break;
              case OtaStatus.ALREADY_RUNNING_ERROR:
                _isDownloading = false;
                _errorMessage = "Ya hay una descarga de actualización en curso.";
                break;
              case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
                _isDownloading = false;
                _errorMessage = "Permisos de instalación no otorgados por el sistema.";
                break;
              case OtaStatus.DOWNLOAD_ERROR:
                _isDownloading = false;
                _errorMessage = "Error al descargar el archivo APK de actualización.";
                break;
              case OtaStatus.INTERNAL_ERROR:
                _isDownloading = false;
                _errorMessage = "Error interno del instalador.";
                break;
              default:
                _isDownloading = false;
                _errorMessage = "Error inesperado durante la actualización.";
                break;
            }
          });
        },
        onError: (error) {
          setState(() {
            _isDownloading = false;
            _errorMessage = "Error de conexión: $error";
          });
        },
      );
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _errorMessage = "No se pudo iniciar el proceso de instalación: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isForceUpdate = widget.updateInfo.forceUpdate;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E88E5).withValues(alpha: 0.08),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.system_update_alt_rounded,
              size: 48,
              color: Color(0xFF1E88E5),
            ),
            const SizedBox(height: 12),
            const Text(
              '¡Actualización Disponible!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E88E5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'v${widget.updateInfo.latestVersionName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Notas de lanzamiento
            const Text(
              'Novedades:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: SingleChildScrollView(
                child: Text(
                  widget.updateInfo.releaseNotes,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Mostrar el estado de descarga
            if (_isDownloading) ...[
              Column(
                children: [
                  LinearProgressIndicator(
                    value: _progress / 100.0,
                    backgroundColor: Colors.grey[200],
                    color: const Color(0xFF1E88E5),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Descargando actualización: ${_progress.toInt()}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Por favor, no cierres la aplicación.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ] else if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _startUpdate,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reintentar Descarga'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ] else ...[
              // Acciones si no se está descargando
              Row(
                children: [
                  if (!isForceUpdate) ...[
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Más tarde'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _startUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Actualizar ahora',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
