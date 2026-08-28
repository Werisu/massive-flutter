import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/firebase/auth_repository.dart';
import '../../data/firebase/firestore_sync_repository.dart';
import '../../data/models/enums.dart';
import '../../data/models/exercise.dart';
import '../../data/models/hiit_protocol.dart';
import '../../data/models/user_preferences.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/workout_plan.dart';
import '../../data/models/workout_session.dart';
import '../../data/repositories/hiit_repository.dart';
import '../../data/repositories/preferences_repository.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/seed/hiit_data.dart';
import '../../data/seed/protocol_data.dart';
import '../../data/services/exercise_catalog.dart';

final preferencesProvider =
    StateNotifierProvider<PreferencesNotifier, UserPreferences>((ref) {
  return PreferencesNotifier(ref.watch(preferencesRepositoryProvider));
});

class PreferencesNotifier extends StateNotifier<UserPreferences> {
  PreferencesNotifier(this._repo) : super(_repo.get());

  final PreferencesRepository _repo;
  final _uuid = const Uuid();

  Future<void> updateName(String name) async {
    final next =
        state.copyWith(userName: name.trim().isEmpty ? 'Atleta' : name.trim());
    await _repo.save(next);
    state = next;
  }

  Future<void> updateRest({int? working, int? prep}) async {
    final next = state.copyWith(
      restMinutesWorking: working,
      restMinutesPrep: prep,
    );
    await _repo.save(next);
    state = next;
  }

  Future<void> updateKeepAlive(bool enabled) async {
    final next = state.copyWith(keepAliveEnabled: enabled);
    await _repo.save(next);
    state = next;
  }

  Future<void> setExerciseSubstitution({
    required String workoutExerciseId,
    String? replacementExerciseId,
  }) async {
    final nextMap = Map<String, String>.from(state.exerciseSubstitutions);
    if (replacementExerciseId == null || replacementExerciseId.isEmpty) {
      nextMap.remove(workoutExerciseId);
    } else {
      nextMap[workoutExerciseId] = replacementExerciseId;
    }
    final next = state.copyWith(exerciseSubstitutions: nextMap);
    await _repo.save(next);
    state = next;
  }

  Future<Exercise> addCustomExercise({
    required String name,
    required MuscleGroup muscleGroup,
  }) async {
    final trimmed = name.trim();
    ExerciseCatalog.setCustom(state.customExercises);
    final existing = ExerciseCatalog.findByName(trimmed);
    if (existing != null) return existing;

    final created = Exercise(
      id: '${ExerciseCatalog.customPrefix}${_uuid.v4()}',
      name: trimmed,
      muscleGroup: muscleGroup,
    );
    final next = state.copyWith(
      customExercises: [...state.customExercises, created],
    );
    await _repo.save(next);
    state = next;
    return created;
  }

  Future<void> applyProfile(UserProfile profile) async {
    final next = profile.toPreferences(state).copyWith(
          lastSyncedAt: DateTime.now(),
        );
    await _repo.save(next);
    state = next;
  }

  Future<void> applyAuthUser(User user) async {
    final name = user.displayName?.trim();
    final next = state.copyWith(
      userName: (name != null && name.isNotEmpty) ? name : state.userName,
      firebaseUid: user.uid,
    );
    await _repo.save(next);
    state = next;
  }

  Future<void> markSynced() async {
    final next = state.copyWith(lastSyncedAt: DateTime.now());
    await _repo.save(next);
    state = next;
  }

  Future<void> clearFirebaseUid() async {
    final cleared = UserPreferences(
      userName: state.userName,
      restMinutesWorking: state.restMinutesWorking,
      restMinutesPrep: state.restMinutesPrep,
      weightKg: state.weightKg,
      heightCm: state.heightCm,
      age: state.age,
      firebaseUid: null,
      cloudSyncEnabled: state.cloudSyncEnabled,
      lastSyncedAt: null,
      keepAliveEnabled: state.keepAliveEnabled,
      exerciseSubstitutions: state.exerciseSubstitutions,
      customExercises: state.customExercises,
    );
    await _repo.save(cleared);
    state = cleared;
  }
}

final sessionsProvider =
    StateNotifierProvider<SessionsNotifier, List<WorkoutSession>>((ref) {
  return SessionsNotifier(ref);
});

class SessionsNotifier extends StateNotifier<List<WorkoutSession>> {
  SessionsNotifier(this._ref)
      : _repo = _ref.read(sessionRepositoryProvider),
        super(_ref.read(sessionRepositoryProvider).getAllSessions());

  final Ref _ref;
  final SessionRepository _repo;

  void refresh() {
    state = _repo.getAllSessions();
  }

  WorkoutSession? get active => _repo.getActiveSession();
  WorkoutSession? get lastFinished => _repo.getLastFinishedSession();

  Future<WorkoutSession> start(WorkoutPlan plan) async {
    final prefs = _ref.read(preferencesProvider);
    final session = await _repo.startSession(
      plan,
      substitutions: prefs.exerciseSubstitutions,
      customExercises: prefs.customExercises,
    );
    refresh();
    return session;
  }

  Future<WorkoutSession> completeSet({
    required WorkoutSession session,
    required String workoutExerciseId,
    required int setIndex,
    required double? weight,
    required int? repetitions,
    required int? rir,
  }) async {
    final updated = await _repo.completeSet(
      session: session,
      workoutExerciseId: workoutExerciseId,
      setIndex: setIndex,
      weight: weight,
      repetitions: repetitions,
      rir: rir,
    );
    refresh();
    return updated;
  }

  Future<WorkoutSession> uncompleteSet({
    required WorkoutSession session,
    required String workoutExerciseId,
    required int setIndex,
  }) async {
    final updated = await _repo.uncompleteSet(
      session: session,
      workoutExerciseId: workoutExerciseId,
      setIndex: setIndex,
    );
    refresh();
    return updated;
  }

  Future<WorkoutSession> editSet({
    required WorkoutSession session,
    required String workoutExerciseId,
    required int setIndex,
    required double? weight,
    required int? repetitions,
    required int? rir,
  }) async {
    final updated = await _repo.editSet(
      session: session,
      workoutExerciseId: workoutExerciseId,
      setIndex: setIndex,
      weight: weight,
      repetitions: repetitions,
      rir: rir,
    );
    refresh();
    return updated;
  }

  Future<WorkoutSession> replaceExercise({
    required WorkoutSession session,
    required String workoutExerciseId,
    required String newExerciseId,
    required String protocolExerciseId,
  }) async {
    final updated = await _repo.replaceExercise(
      session: session,
      workoutExerciseId: workoutExerciseId,
      newExerciseId: newExerciseId,
      protocolExerciseId: protocolExerciseId,
    );
    refresh();
    return updated;
  }

  Future<WorkoutSession> save(WorkoutSession session) async {
    await _repo.updateSession(session);
    refresh();
    return session;
  }

  Future<WorkoutSession> finish(WorkoutSession session) async {
    final updated = await _repo.finishSession(session);
    refresh();
    try {
      final auth = _ref.read(authRepositoryProvider);
      if (auth.isSignedIn) {
        await _ref.read(firestoreSyncProvider).upsertSession(updated);
      }
    } catch (_) {}
    return updated;
  }

  Future<int> mergeRemote(List<WorkoutSession> remote) async {
    final count = await _repo.mergeRemoteSessions(remote);
    refresh();
    return count;
  }

  Future<void> discardActive() async {
    await _repo.discardActiveSession();
    refresh();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  if (!auth.isFirebaseReady) {
    return Stream.value(null);
  }
  return auth.authStateChanges();
});

final firestoreSyncProvider = Provider<FirestoreSyncRepository>((ref) {
  return FirestoreSyncRepository();
});

/// Intervalo mínimo entre syncs automáticos.
const autoSyncInterval = Duration(minutes: 15);

class SyncUiState {
  const SyncUiState({
    this.isSyncing = false,
    this.lastResult,
    this.lastAttemptAt,
    this.autoSyncDoneForUid,
  });

  final bool isSyncing;
  final SyncResult? lastResult;
  final DateTime? lastAttemptAt;
  final String? autoSyncDoneForUid;

  SyncUiState copyWith({
    bool? isSyncing,
    SyncResult? lastResult,
    DateTime? lastAttemptAt,
    String? autoSyncDoneForUid,
  }) {
    return SyncUiState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastResult: lastResult ?? this.lastResult,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      autoSyncDoneForUid: autoSyncDoneForUid ?? this.autoSyncDoneForUid,
    );
  }
}

final syncUiProvider =
    StateNotifierProvider<SyncUiNotifier, SyncUiState>((ref) {
  return SyncUiNotifier();
});

class SyncUiNotifier extends StateNotifier<SyncUiState> {
  SyncUiNotifier() : super(const SyncUiState());

  void setSyncing(bool value) {
    state = state.copyWith(isSyncing: value);
  }

  void setResult(SyncResult result) {
    state = state.copyWith(
      isSyncing: false,
      lastResult: result,
      lastAttemptAt: DateTime.now(),
    );
  }

  void markAutoSynced(String uid) {
    state = state.copyWith(autoSyncDoneForUid: uid);
  }
}

final syncStatusProvider =
    StateNotifierProvider<SyncStatusNotifier, AsyncValue<SyncResult?>>((ref) {
  return SyncStatusNotifier(ref);
});

class SyncStatusNotifier extends StateNotifier<AsyncValue<SyncResult?>> {
  SyncStatusNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;
  bool _running = false;

  Future<SyncResult> syncNow({bool pushLocalFinished = true}) async {
    if (_running) {
      return state.valueOrNull ??
          SyncResult.fail('Sincronização já em andamento.');
    }
    _running = true;
    state = const AsyncValue.loading();
    _ref.read(syncUiProvider.notifier).setSyncing(true);

    final auth = _ref.read(authRepositoryProvider);
    if (!auth.isSignedIn) {
      final fail = SyncResult.fail('Faça login com Google para sincronizar.');
      state = AsyncValue.data(fail);
      _ref.read(syncUiProvider.notifier).setResult(fail);
      _running = false;
      return fail;
    }

    final sync = _ref.read(firestoreSyncProvider);
    final sessionsNotifier = _ref.read(sessionsProvider.notifier);
    final prefsNotifier = _ref.read(preferencesProvider.notifier);

    final result = await sync.pullAndMerge(
      applyProfile: (profile) async {
        await prefsNotifier.applyProfile(profile);
      },
      mergeSessions: (remote) async {
        return sessionsNotifier.mergeRemote(remote);
      },
    );

    if (result.success && pushLocalFinished) {
      try {
        final local =
            _ref.read(sessionRepositoryProvider).getFinishedSessions();
        for (final session in local.take(20)) {
          if (_looksLocalUuid(session.id) ||
              session.finishedAt?.isAfter(
                    DateTime.now().subtract(const Duration(days: 2)),
                  ) ==
                  true) {
            await sync.upsertSession(session);
          }
        }
        final user = sync.currentUser;
        if (user != null) {
          await sync.saveProfileFromPreferences(
            _ref.read(preferencesProvider),
            uid: user.uid,
          );
        }
        await prefsNotifier.markSynced();
      } catch (_) {}
    }

    state = AsyncValue.data(result);
    _ref.read(syncUiProvider.notifier).setResult(result);
    _running = false;
    return result;
  }

  /// Sync automático se logado e dados stale / nunca sincronizados.
  Future<SyncResult?> autoSyncIfNeeded() async {
    final auth = _ref.read(authRepositoryProvider);
    final prefs = _ref.read(preferencesProvider);
    final ui = _ref.read(syncUiProvider);

    if (!prefs.cloudSyncEnabled) return null;
    if (!auth.isFirebaseReady || !auth.isSignedIn) return null;

    final uid = auth.currentUser?.uid;
    if (uid == null) return null;

    final last = prefs.lastSyncedAt;
    final stale = last == null ||
        DateTime.now().difference(last) >= autoSyncInterval;

    // Evita spam na mesma sessão se já sincronizou há pouco para este UID
    if (!stale && ui.autoSyncDoneForUid == uid) return null;
    if (_running) return null;

    final result = await syncNow();
    if (result.success) {
      _ref.read(syncUiProvider.notifier).markAutoSynced(uid);
    }
    return result;
  }

  bool _looksLocalUuid(String id) {
    return id.contains('-') && !id.startsWith('session-');
  }
}

/// Dispara sync automático quando o usuário autenticar / app abrir.
final autoSyncBootstrapProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<User?>>(authStateProvider, (prev, next) {
    final user = next.valueOrNull;
    if (user == null) return;
    // Debounce leve após auth
    scheduleMicrotask(() {
      ref.read(syncStatusProvider.notifier).autoSyncIfNeeded();
    });
  });
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<User?>>((ref) {
  return AuthController(ref);
});

class AuthController extends StateNotifier<AsyncValue<User?>> {
  AuthController(this._ref)
      : super(AsyncValue.data(_ref.read(authRepositoryProvider).currentUser));

  final Ref _ref;

  Future<User?> signInWithGoogleAndSync() async {
    state = const AsyncValue.loading();
    try {
      final auth = _ref.read(authRepositoryProvider);
      final user = await auth.signInWithGoogle();
      await _ref.read(preferencesProvider.notifier).applyAuthUser(user);
      state = AsyncValue.data(user);

      await _ref.read(syncStatusProvider.notifier).syncNow();
      _ref.read(syncUiProvider.notifier).markAutoSynced(user.uid);
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(authRepositoryProvider).signOut();
      await _ref.read(preferencesProvider.notifier).clearFirebaseUid();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final todayPlanProvider = Provider<WorkoutPlan>((ref) {
  return ProtocolData.planForWeekday(Weekday.fromDateTime(DateTime.now()));
});

final allPlansProvider = Provider<List<WorkoutPlan>>((ref) {
  return ProtocolData.plans;
});

final allExercisesProvider = Provider((ref) {
  ref.watch(preferencesProvider);
  return ExerciseCatalog.all;
});

final todayHiitProvider = Provider<HiitProtocol?>((ref) {
  return HiitData.forWeekday(Weekday.fromDateTime(DateTime.now()));
});

final hiitCompletionProvider =
    StateNotifierProvider<HiitCompletionNotifier, HiitCompletionState>((ref) {
  return HiitCompletionNotifier(ref.watch(hiitRepositoryProvider));
});

class HiitCompletionNotifier extends StateNotifier<HiitCompletionState> {
  HiitCompletionNotifier(this._repo) : super(_repo.get());

  final HiitRepository _repo;

  Future<void> markCompleted(String protocolId) async {
    state = await _repo.markCompleted(protocolId);
  }
}
