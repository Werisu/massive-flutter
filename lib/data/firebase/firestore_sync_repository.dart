import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/enums.dart';
import '../models/user_preferences.dart';
import '../models/user_profile.dart';
import '../models/workout_session.dart';
import '../seed/protocol_data.dart';
import 'firebase_mappers.dart';

/// Sincroniza com o schema do app original:
/// `users/{uid}/data/{profile|workoutHistory|customWorkouts}`
///
/// A chave de service account NÃO é usada no app — apenas Auth + Firestore SDK.
class FirestoreSyncRepository {
  FirestoreSyncRepository();

  final _uuid = const Uuid();

  /// UID conhecido do histórico legado (mesmo projeto Firebase).
  /// Usado só como fallback de leitura se o login atual for outro UID.
  static const legacyOwnerUid = 'Y7zhPzShJpQGk9PDbggZnHTRp942';

  bool get isFirebaseReady => Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db {
    if (!isFirebaseReady) {
      throw StateError('Firebase não inicializado');
    }
    return FirebaseFirestore.instance;
  }

  FirebaseAuth get _auth {
    if (!isFirebaseReady) {
      throw StateError('Firebase não inicializado');
    }
    return FirebaseAuth.instance;
  }

  User? get currentUser {
    if (!isFirebaseReady) return null;
    return _auth.currentUser;
  }

  String? get _uid => currentUser?.uid;

  /// Caminho correto do outro app: users/{uid}/data
  CollectionReference<Map<String, dynamic>> _userData(String uid) =>
      _db.collection('users').doc(uid).collection('data');

  CollectionReference<Map<String, dynamic>> get _data {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Faça login com Google para sincronizar.');
    }
    return _userData(uid);
  }

  Future<User> ensureSignedIn() async {
    if (!isFirebaseReady) {
      throw StateError('Firebase não inicializado');
    }
    final existing = _auth.currentUser;
    if (existing != null) return existing;
    throw StateError(
      'Faça login com Google para sincronizar.',
    );
  }

  Future<UserProfile?> fetchProfile() async {
    final uid = _uid;
    if (uid == null) return null;

    // 1) dados do usuário logado
    var snap = await _userData(uid).doc('profile').get();
    if (snap.exists && snap.data() != null) {
      return UserProfile.fromFirestore(snap.data()!);
    }

    // 2) fallback: histórico legado do mesmo projeto (outro UID)
    if (uid != legacyOwnerUid) {
      snap = await _userData(legacyOwnerUid).doc('profile').get();
      if (snap.exists && snap.data() != null) {
        debugPrint(
          'Perfil legado encontrado em users/$legacyOwnerUid (login atual: $uid)',
        );
        return UserProfile.fromFirestore(snap.data()!);
      }
    }
    return null;
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _data.doc('profile').set(profile.toFirestore(), SetOptions(merge: true));
  }

  Future<void> saveProfileFromPreferences(
    UserPreferences prefs, {
    required String uid,
  }) async {
    final existing = await fetchProfile();
    final profile = UserProfile(
      id: uid,
      name: prefs.userName,
      weight: prefs.weightKg ?? existing?.weight,
      height: prefs.heightCm ?? existing?.height,
      age: prefs.age ?? existing?.age,
      gender: existing?.gender,
      goal: existing?.goal,
      experience: existing?.experience,
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _userData(uid)
        .doc('profile')
        .set(profile.toFirestore(), SetOptions(merge: true));
  }

  /// Baixa o histórico em `users/{uid}/data/workoutHistory`.
  Future<List<WorkoutSession>> fetchLegacySessions() async {
    final uid = _uid;
    if (uid == null) return [];

    Future<List<WorkoutSession>> fromUid(String targetUid) async {
      final snap = await _userData(targetUid).doc('workoutHistory').get();
      if (!snap.exists || snap.data() == null) return [];
      final raw = snap.data()!['sessions'];
      if (raw is! List) return [];

      final sessions = <WorkoutSession>[];
      for (final item in raw) {
        if (item is! Map) continue;
        final mapped = _mapLegacySession(Map<String, dynamic>.from(item));
        if (mapped != null) sessions.add(mapped);
      }
      sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return sessions;
    }

    var sessions = await fromUid(uid);
    if (sessions.isEmpty && uid != legacyOwnerUid) {
      sessions = await fromUid(legacyOwnerUid);
      if (sessions.isNotEmpty) {
        debugPrint(
          'Histórico legado importado de users/$legacyOwnerUid '
          '(${sessions.length} sessões). Login atual: $uid',
        );
      }
    }
    return sessions;
  }

  WorkoutSession? _mapLegacySession(Map<String, dynamic> json) {
    final dayId = json['dayId'] as String?;
    final planId = FirebaseMappers.planIdFromDayId(dayId);
    if (planId == null) return null;

    final startedMs = json['startedAt'];
    final completedMs = json['completedAt'];
    if (startedMs is! int) return null;

    final startedAt = DateTime.fromMillisecondsSinceEpoch(startedMs);
    final finishedAt = completedMs is int
        ? DateTime.fromMillisecondsSinceEpoch(completedMs)
        : startedAt;

    final plan = ProtocolData.planById(planId);
    final legacyExercises = json['exercises'];
    if (legacyExercises is! List) {
      return WorkoutSession(
        id: json['id'] as String? ?? 'session-$startedMs',
        workoutPlanId: planId,
        startedAt: startedAt,
        finishedAt: finishedAt,
        exercises: const [],
      );
    }

    final sessionExercises = <SessionExercise>[];
    for (var i = 0; i < legacyExercises.length; i++) {
      final ex = legacyExercises[i];
      if (ex is! Map) continue;
      final map = Map<String, dynamic>.from(ex);
      final exerciseId = FirebaseMappers.resolveExerciseId(
        map['exerciseId'] as String?,
        map['exerciseName'] as String?,
      );

      final setsRaw = map['sets'];
      final sets = <SetRecord>[];
      if (setsRaw is List) {
        for (final s in setsRaw) {
          if (s is! Map) continue;
          final setMap = Map<String, dynamic>.from(s);
          final index = setMap['setIndex'] as int? ?? sets.length;
          final ts = setMap['timestamp'];
          sets.add(
            SetRecord(
              id: _uuid.v4(),
              exerciseId: exerciseId,
              setType: _inferSetType(planId, exerciseId, index),
              setNumber: index + 1,
              weight: (setMap['weight'] as num?)?.toDouble(),
              repetitions: setMap['reps'] as int?,
              completed: true,
              completedAt: ts is int
                  ? DateTime.fromMillisecondsSinceEpoch(ts)
                  : finishedAt,
            ),
          );
        }
      }

      sessionExercises.add(
        SessionExercise(
          workoutExerciseId: '$planId-$exerciseId-$i',
          exerciseId: exerciseId,
          order: i + 1,
          sets: sets,
        ),
      );
    }

    if (plan != null && sessionExercises.isNotEmpty) {
      sessionExercises.sort((a, b) {
        final ao = plan.exercises
            .where((e) => e.exerciseId == a.exerciseId)
            .map((e) => e.order)
            .firstOrNull;
        final bo = plan.exercises
            .where((e) => e.exerciseId == b.exerciseId)
            .map((e) => e.order)
            .firstOrNull;
        return (ao ?? a.order).compareTo(bo ?? b.order);
      });
    }

    return WorkoutSession(
      id: json['id'] as String? ?? 'session-$startedMs',
      workoutPlanId: planId,
      startedAt: startedAt,
      finishedAt: finishedAt,
      exercises: sessionExercises,
    );
  }

  SetType _inferSetType(String planId, String exerciseId, int setIndex) {
    final plan = ProtocolData.planById(planId);
    if (plan == null) return SetType.working;
    final we = plan.exercises.where((e) => e.exerciseId == exerciseId);
    if (we.isEmpty) return SetType.working;
    final sets = we.first.sets;
    if (setIndex >= 0 && setIndex < sets.length) {
      return sets[setIndex].type;
    }
    return SetType.working;
  }

  Future<void> upsertSession(WorkoutSession session) async {
    if (!session.isFinished) return;
    if (!isFirebaseReady) return;
    final uid = _uid;
    if (uid == null) return;

    final legacy = _toLegacySession(session);
    final ref = _userData(uid).doc('workoutHistory');

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? <String, dynamic>{};
      final sessions = List<Map<String, dynamic>>.from(
        (data['sessions'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e as Map)) ??
            const [],
      );

      final idx = sessions.indexWhere((s) => s['id'] == legacy['id']);
      if (idx >= 0) {
        sessions[idx] = legacy;
      } else {
        sessions.add(legacy);
      }

      tx.set(
        ref,
        {
          'sessions': sessions,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        },
        SetOptions(merge: true),
      );
    });
  }

  Map<String, dynamic> _toLegacySession(WorkoutSession session) {
    final plan = ProtocolData.planById(session.workoutPlanId);
    final dayId =
        FirebaseMappers.dayIdFromPlanId(session.workoutPlanId) ?? 'segunda';
    final dayName = plan != null
        ? FirebaseMappers.dayNameFromWeekday(plan.weekday)
        : dayId;

    return {
      'id': session.id,
      'dayId': dayId,
      'dayName': dayName,
      'startedAt': session.startedAt.millisecondsSinceEpoch,
      'completedAt':
          (session.finishedAt ?? session.startedAt).millisecondsSinceEpoch,
      'totalDuration': session.duration?.inSeconds ?? 0,
      'exercises': session.exercises.map((ex) {
        final name =
            ProtocolData.exerciseById(ex.exerciseId)?.name ?? ex.exerciseId;
        return {
          'exerciseId': _legacyExerciseId(session.workoutPlanId, ex),
          'exerciseName': name,
          'completedAt': ex.sets
                  .where((s) => s.completedAt != null)
                  .map((s) => s.completedAt!.millisecondsSinceEpoch)
                  .lastOrNull ??
              (session.finishedAt ?? session.startedAt).millisecondsSinceEpoch,
          'sets': [
            for (var i = 0; i < ex.sets.length; i++)
              if (ex.sets[i].completed)
                {
                  'setIndex': i,
                  'weight': ex.sets[i].weight ?? 0,
                  'reps': ex.sets[i].repetitions ?? 0,
                  'timestamp': (ex.sets[i].completedAt ??
                          session.finishedAt ??
                          session.startedAt)
                      .millisecondsSinceEpoch,
                  if (ex.sets[i].rir != null) 'rir': ex.sets[i].rir,
                },
          ],
        };
      }).toList(),
    };
  }

  String _legacyExerciseId(String planId, SessionExercise ex) {
    for (final entry in FirebaseMappers.legacyExerciseToId.entries) {
      if (entry.value == ex.exerciseId) {
        final prefix = switch (planId) {
          'plan_monday' => 'seg',
          'plan_tuesday' => 'ter',
          'plan_wednesday' => 'qua',
          'plan_friday' => 'sex',
          'plan_saturday' => 'sab',
          'plan_sunday' => 'dom',
          _ => null,
        };
        if (prefix != null && entry.key.startsWith('$prefix-')) {
          return entry.key;
        }
      }
    }
    return ex.exerciseId;
  }

  Future<SyncResult> pullAndMerge({
    required Future<int> Function(List<WorkoutSession> remote) mergeSessions,
    required Future<void> Function(UserProfile profile) applyProfile,
  }) async {
    if (!isFirebaseReady) {
      return SyncResult.fail(
        'Firebase não inicializado nesta plataforma. '
        'No Console, registre um app Web e atualize firebase_options.dart.',
      );
    }

    try {
      await ensureSignedIn();
      final profile = await fetchProfile();
      if (profile != null) {
        await applyProfile(profile);
      }
      final sessions = await fetchLegacySessions();
      final newlyImported = await mergeSessions(sessions);
      return SyncResult.ok(
        importedSessions: sessions.length,
        newlyImported: newlyImported,
        profileName: profile?.name,
      );
    } catch (e, st) {
      debugPrint('Firestore sync error: $e\n$st');
      return SyncResult.fail(e.toString());
    }
  }
}

class SyncResult {
  const SyncResult._({
    required this.success,
    this.importedSessions = 0,
    this.newlyImported = 0,
    this.profileName,
    this.error,
  });

  factory SyncResult.ok({
    required int importedSessions,
    int newlyImported = 0,
    String? profileName,
  }) =>
      SyncResult._(
        success: true,
        importedSessions: importedSessions,
        newlyImported: newlyImported,
        profileName: profileName,
      );

  factory SyncResult.fail(String error) =>
      SyncResult._(success: false, error: error);

  final bool success;
  final int importedSessions;
  final int newlyImported;
  final String? profileName;
  final String? error;
}
