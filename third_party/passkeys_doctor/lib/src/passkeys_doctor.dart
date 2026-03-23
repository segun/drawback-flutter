import 'dart:async';

import 'package:flutter/services.dart';

import '../passkeys_doctor.dart';

class PasskeysDoctor {
  PasskeysDoctor();

  static const Checkpoint _disabledCheckpoint = Checkpoint(
    name: 'Passkeys doctor disabled',
    description:
        'Diagnostic checks are disabled in this app build. Passkey runtime flows remain available.',
    type: CheckpointType.warning,
  );

  final StreamController<Result> _streamController =
      StreamController<Result>.broadcast();

  Stream<Result> get resultStream => _streamController.stream;

  void recordException(PlatformException exception) {
    _streamController.add(
      Result(
        checkpoints: const <Checkpoint>[_disabledCheckpoint],
        exception: exception,
      ),
    );
  }

  Future<void> check(String rpId) async {
    _streamController.add(
      const Result(
        checkpoints: <Checkpoint>[_disabledCheckpoint],
      ),
    );
  }
}
