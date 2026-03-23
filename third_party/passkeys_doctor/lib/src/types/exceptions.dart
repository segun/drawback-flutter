import '../../passkeys_doctor.dart';

class DoctorException implements Exception {
  DoctorException({
    required this.blockingCheckpoint,
  });

  final Checkpoint blockingCheckpoint;

  @override
  String toString() {
    return 'DoctorException: cannot continue the next checks because the following checkpoint is failing: ${blockingCheckpoint.name}';
  }
}
