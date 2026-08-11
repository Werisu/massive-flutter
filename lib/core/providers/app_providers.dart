import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/firebase/auth_repository.dart';
import '../../data/firebase/firestore_sync_repository.dart';
import '../../data/models/enums.dart';
import '../../data/models/user_preferences.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/workout_plan.dart';
import '../../data/models/workout_session.dart';
import '../../data/repositories/preferences_repository.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/seed/protocol_data.dart';

final preferencesProvider =
    StateNotifierProvider<PreferencesNotifier, UserPreferences>((ref) {
  return PreferencesNotifier(ref.watch(preferencesRepositoryProvider));
});

class PreferencesNotifier extends StateNotifier<UserPreferences> {
  PreferencesNotifier(this._repo) : super(_repo.get());

  final PreferencesRepository _repo;

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
    final session = await _repo.startSession(plan);
    refresh();
    return session;
  }

  Future<WorkoutSession> completeSet({
    required WorkoutSession session,
    required String exerciseId,
    required int setIndex,
    required double? weight,
    required int? repetitions,
    required int? rir,
  }) async {
    final updated = await _repo.completeSet(
      session: session,
      exerciseId: exerciseId,
      setIndex: setIndex,
      weight: weight,
      repetitions: repetitions,
      rir: rir,
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

final syncStatusProvider =
    StateNotifierProvider<SyncStatusNotifier, AsyncValue<SyncResult?>>((ref) {
  return SyncStatusNotifier(ref);
});

class SyncStatusNotifier extends StateNotifier<AsyncValue<SyncResult?>> {
  SyncStatusNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<SyncResult> syncNow({bool pushLocalFinished = true}) async {
    state = const AsyncValue.loading();
    final auth = _ref.read(authRepositoryProvider);
    if (!auth.isSignedIn) {
      final fail = SyncResult.fail('Faça login com Google para sincronizar.');
      state = AsyncValue.data(fail);
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
        await sessionsNotifier.mergeRemote(remote);
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
    return result;
  }

  bool _looksLocalUuid(String id) {
    return id.contains('-') && !id.startsWith('session-');
  }
}

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

      // Sync automático após login
      await _ref.read(syncStatusProvider.notifier).syncNow();
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

final allExercisesProvider = Provider((ref) => ProtocolData.exercises);
