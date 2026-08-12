import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/user_preferences.dart';
import '../models/user_profile.dart';
import '../models/workout_session.dart';
import 'legacy_workout_mapper.dart';

/// Sincroniza com o schema do app original:
/// `users/{uid}/data/{profile|workoutHistory|customWorkouts}`
///
/// A chave de service account NÃO é usada no app — apenas Auth + Firestore SDK.
class FirestoreSyncRepository {
  FirestoreSyncRepository();

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
      return LegacyWorkoutMapper.mapSessions(raw);
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

  Future<void> upsertSession(WorkoutSession session) async {
    if (!session.isFinished) return;
    if (!isFirebaseReady) return;
    final uid = _uid;
    if (uid == null) return;

    final legacy = LegacyWorkoutMapper.toLegacySession(session);
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
        final existing = sessions[idx];
        final existingCompleted =
            LegacyWorkoutMapper.legacyCompletedSets(existing);
        final incomingCompleted =
            LegacyWorkoutMapper.legacyCompletedSets(legacy);
        final existingAt = existing['completedAt'] as int? ?? 0;
        final incomingAt = legacy['completedAt'] as int? ?? 0;

        // Só sobrescreve se o local tiver mais progresso ou for mais recente.
        if (incomingCompleted > existingCompleted ||
            (incomingCompleted == existingCompleted &&
                incomingAt >= existingAt)) {
          sessions[idx] = legacy;
        }
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
