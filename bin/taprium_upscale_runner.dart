import 'dart:async';

import 'package:cron/cron.dart';
import 'package:get_it/get_it.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:taprium_upscale_runner/log.dart';
import 'package:taprium_upscale_runner/taprium_pb.dart';
import 'package:taprium_upscale_runner/upscale.dart';

void main(List<String> arguments) async {
  try {
    await trySignIn();
  } catch (e) {
    logger.f("Failed to Sign In: $e");
    return;
  }

  final pocketbase = GetIt.instance.get<PocketBase>();
  final cron = Cron();
  cron.schedule(Schedule.parse("0 0 * * *"), () async {
    await pocketbase.collection(tapriumCollectionUpscaleRunners).authRefresh();
  });
  logger.i("Cron job scheduled");

  Future<void>? activeUpscale;

  await pocketbase.collection(tapriumCollectionImage).subscribe("*", (e) async {
    if (e.action != 'update') return;
    final r = e.record!;

    // Validation logic
    if (r.getBoolValue('selected') &&
        !r.getBoolValue('upscaled') &&
        r.getStringValue('runner').isEmpty) {
      // Capture the "current" tail of the queue
      final previousTask = activeUpscale;

      // Create a new future that represents this task being finished
      // We assign it immediately so the NEXT event has to wait for US
      final Completer<void> completer = Completer<void>();
      activeUpscale = completer.future;

      try {
        // If there was a previous task, wait for it to finish first
        if (previousTask != null) {
          await previousTask;
        }

        // Now it's our turn!
        await upscaleSingle(r);
      } catch (err) {
        logger.e("Upscale failed", error: err);
      } finally {
        // Signal that we are done so the next person in line can start
        completer.complete();
      }
    }
  });
  logger.i("Subscribed to image collection");

  await upscaleLeftOverCheck();
  logger.i("Upscale left over check complete");

  bool isSyncing = false;
  pocketbase.realtime.subscribe("PB_CONNECT", (e) async {
    logger.i("Server reconnected, checking left over works");

    // 1. THE LOCK: If we are already syncing, ignore this event.
    if (isSyncing) {
      print('⏳ Sync already in progress... ignoring duplicate PB_CONNECT.');
      return;
    }

    isSyncing = true;

    try {
      print('🔄 Reconnected! Running left-over check...');
      await upscaleLeftOverCheck();
    } catch (err) {
      print('❌ Sync failed: $err');
    } finally {
      // 2. THE RELEASE: Always reset the flag, even if the check fails.
      isSyncing = false;
      print('✅ Sync lock released.');
    }
  });

  final keepAlive = Completer<void>();
  await keepAlive.future;
}
