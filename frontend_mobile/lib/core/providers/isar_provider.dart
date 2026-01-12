import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:pairing_planet2_frontend/data/models/local/cached_home_feed.dart';
import 'package:pairing_planet2_frontend/data/models/local/cached_log_post.dart';
import 'package:pairing_planet2_frontend/data/models/local/cached_profile.dart';
import 'package:pairing_planet2_frontend/data/models/local/cached_recipe.dart';
import 'package:pairing_planet2_frontend/data/models/local/local_log_draft.dart';
import 'package:pairing_planet2_frontend/data/models/local/progress_stats_entry.dart';
import 'package:pairing_planet2_frontend/data/models/local/queued_event.dart';
import 'package:pairing_planet2_frontend/data/models/local/recently_viewed_entry.dart';
import 'package:pairing_planet2_frontend/data/models/local/recipe_draft_entry.dart';
import 'package:pairing_planet2_frontend/data/models/local/search_history_entry.dart';
import 'package:pairing_planet2_frontend/data/models/local/sync_queue_entry.dart';
import 'package:path_provider/path_provider.dart';

final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('Isar must be initialized before use');
});

// Isar initialization function to be called at app startup
Future<Isar> initializeIsar() async {
  final dir = await getApplicationDocumentsDirectory();

  final isar = await Isar.open(
    [
      QueuedEventSchema,
      CachedRecipeSchema,
      CachedProfileSchema,
      SearchHistoryEntrySchema,
      RecipeDraftEntrySchema,
      RecentlyViewedEntrySchema,
      CachedLogPostSchema,
      CachedHomeFeedSchema,
      SyncQueueEntrySchema,
      LocalLogDraftSchema,
      ProgressStatsEntrySchema,
    ],
    directory: dir.path,
    // Enable inspector ONLY in debug mode (automatically disabled in production)
    inspector: kDebugMode,
  );

  return isar;
}
