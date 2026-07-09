// 📡 Service GPS réutilisable
// Capture de position avec gestion des permissions et Google Maps

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class GpsService {
  /// Demande la permission de localisation (simple, comme le micro).
  /// Retourne `true` si accordée.
  static Future<bool> demanderPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Vérifie si le GPS est activé.
  static Future<bool> estActive() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Capture la position GPS avec haute précision.
  /// Retourne `null` en cas d'échec.
  static Future<Position?> capturer({
    required BuildContext context,
    required VoidCallback onStateChanged,
  }) async {
    // Permission
    final granted = await demanderPermission();
    if (!granted) {
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Permission de localisation refusée'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return null;
    }

    // GPS activé ?
    final enabled = await estActive();
    if (!enabled) {
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez activer le GPS'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      );

      if (!context.mounted) return null;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Position capturée : ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF00875A),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      return position;
    } catch (e) {
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur GPS : ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return null;
    }
  }

  /// Vérifie la connexion Internet.
  static Future<bool> aConnexion() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Ouvre Google Maps avec les coordonnées données.
  /// Vérifie la connexion Internet avant.
  static Future<void> ouvrirGoogleMaps({
    required BuildContext context,
    required double latitude,
    required double longitude,
  }) async {
    final connected = await aConnexion();
    if (!connected) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Veuillez vous connecter à Internet pour voir la carte',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final uri = Uri.parse('https://www.google.com/maps?q=$latitude,$longitude');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Widget bouton GPS réutilisable.
  /// Affiche un bouton pour capturer la position, et un bouton Maps si déjà capturée.
  static Widget boutonGps({
    required double? latitude,
    required double? longitude,
    required bool loading,
    required VoidCallback onCapturer,
    required VoidCallback onOuvrirMaps,
  }) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: loading ? null : onCapturer,
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF00875A),
                      ),
                    )
                  : Icon(
                      latitude != null
                          ? Icons.gps_fixed_rounded
                          : Icons.gps_not_fixed_rounded,
                      color: latitude != null
                          ? const Color(0xFF00875A)
                          : Colors.grey,
                    ),
              label: Text(
                latitude != null
                    ? '${latitude.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}'
                    : 'Capturer la position GPS',
                style: TextStyle(
                  color: latitude != null
                      ? const Color(0xFF00875A)
                      : const Color(0xFF00875A),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: latitude != null
                      ? const Color(0xFF00875A)
                      : Colors.grey.shade400,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        if (latitude != null) ...[
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: onOuvrirMaps,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF00875A)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Icon(Icons.map_rounded, color: Color(0xFF00875A)),
            ),
          ),
        ],
      ],
    );
  }
}
