import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Notificações locais para o cronômetro de descanso.
class RestNotificationService {
  RestNotificationService._();
  static final instance = RestNotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  static const _channelId = 'rest_timer';
  static const _notifId = 4201;

  Future<void> init() async {
    if (kIsWeb) return;
    if (_ready) return;

    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
    } catch (_) {
      // Mantém o local padrão do pacote timezone.
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(settings: settings);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        'Descanso do treino',
        description: 'Avisa quando o intervalo de descanso termina',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    _ready = true;
  }

  Future<void> scheduleRestFinished({
    required Duration after,
    String title = 'Descanso concluído',
    String body = 'Hora da próxima série.',
  }) async {
    if (kIsWeb) return;
    await init();
    await cancelRest();

    final when = tz.TZDateTime.now(tz.local).add(after);
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Descanso do treino',
        channelDescription: 'Avisa quando o intervalo de descanso termina',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.alarm,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      ),
    );

    try {
      await _plugin.zonedSchedule(
        id: _notifId,
        title: title,
        body: body,
        scheduledDate: when,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('zonedSchedule exact falhou, tentando inexact: $e');
      try {
        await _plugin.zonedSchedule(
          id: _notifId,
          title: title,
          body: body,
          scheduledDate: when,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (e2) {
        debugPrint('Notificação de descanso indisponível: $e2');
      }
    }
  }

  Future<void> cancelRest() async {
    if (kIsWeb) return;
    if (!_ready) return;
    await _plugin.cancel(id: _notifId);
  }
}
