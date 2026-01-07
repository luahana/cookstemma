import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:pairing_planet2_frontend/data/models/local/queued_event.dart';
import 'package:path_provider/path_provider.dart';

final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('Isar must be initialized before use');
});

// Isar initialization function to be called at app startup
Future<Isar> initializeIsar() async {
  final dir = await getApplicationDocumentsDirectory();

  final isar = await Isar.open(
    [QueuedEventSchema],
    directory: dir.path,
    // Enable inspector ONLY in debug mode (automatically disabled in production)
    inspector: kDebugMode,
  );

  return isar;
}
