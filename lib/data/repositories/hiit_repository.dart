import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../local/hive_boxes.dart';
import '../models/hiit_protocol.dart';

final hiitRepositoryProvider = Provider<HiitRepository>((ref) {
  return HiitRepository(Hive.box<String>(HiveBoxes.preferences));
});

class HiitRepository {
  HiitRepository(this._box);

  final Box<String> _box;
  static const _key = 'hiit_completion';

  HiitCompletionState get() {
    final raw = _box.get(_key);
    if (raw == null) return const HiitCompletionState();
    try {
      return HiitCompletionState.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return const HiitCompletionState();
    }
  }

  Future<void> save(HiitCompletionState state) async {
    await _box.put(_key, jsonEncode(state.toJson()));
  }

  Future<HiitCompletionState> markCompleted(String protocolId) async {
    final next = HiitCompletionState(
      lastCompletedDate: HiitCompletionState.dateKey(DateTime.now()),
      lastProtocolId: protocolId,
    );
    await save(next);
    return next;
  }
}
