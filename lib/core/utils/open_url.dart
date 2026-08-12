import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Abre URL externa (vídeos do protocolo, etc.).
Future<bool> openExternalUrl(
  String url, {
  BuildContext? context,
  String failureMessage = 'Não foi possível abrir o link.',
}) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    _toast(context, failureMessage);
    return false;
  }

  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      if (context != null && context.mounted) {
        _toast(context, failureMessage);
      }
      return false;
    }
    return true;
  } catch (e) {
    debugPrint('openExternalUrl: $e');
    if (context != null && context.mounted) {
      _toast(context, failureMessage);
    }
    return false;
  }
}

void _toast(BuildContext? context, String message) {
  if (context == null || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
