import 'package:flutter/services.dart';

import '../../passkeys_doctor.dart';

class Result {
  const Result({
    required this.checkpoints,
    this.exception,
  });

  final List<Checkpoint> checkpoints;
  final PlatformException? exception;
}
