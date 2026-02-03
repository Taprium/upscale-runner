import 'dart:convert';
import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';
import 'package:taprium_upscale_runner/log.dart';
import 'package:taprium_upscale_runner/taprium_pb.dart';

Future upscaleLeftOverCheck() async {
  final tapriumPb = GetIt.instance.get<PocketBase>();

  final toUpscaleRecords = await tapriumPb
      .collection(tapriumCollectionImage)
      .getFullList(
        filter:
            'selected=true && upscaled=false && (runner="" || runner="${tapriumPb.authStore.record!.id}")',
        expand: 'queue',
      );

  for (var i in toUpscaleRecords) {
    try {
      await upscaleSingle(i);
    } catch (_) {}
  }
}

Future upscaleSingle(RecordModel toUpscaleRecord) async {
  final tapriumPb = GetIt.instance.get<PocketBase>();

  // lock the runner
  try {
    await tapriumPb
        .collection(tapriumCollectionImage)
        .update(
          toUpscaleRecord.id,
          body: {"runner": tapriumPb.authStore.record!.id},
          query: {"filter": 'selected=true && upscaled=false && runner=""'},
        );
  } catch (e) {
    throw Exception("Lock upscale job failed, getting new upscale job: $e");
  }

  final settingsRecord = await tapriumPb
      .collection(tapriumCollectionSetttings)
      .getFirstListItem('');

  final queueRecord = toUpscaleRecord.get<RecordModel>('expand.queue');

  int upscaleTimes = queueRecord.getIntValue('upscale_times');
  if (upscaleTimes == 0) {
    upscaleTimes = settingsRecord.getIntValue('upscale_times');
  }

  final originFileName = toUpscaleRecord.getStringValue('image');
  final fileUrl = tapriumPb.files.getUrl(
    toUpscaleRecord,
    originFileName,
    token: await tapriumPb.files.getToken(),
    download: true,
  );

  final response = await http.get(fileUrl);

  if (response.statusCode != 200) {
    await tapriumPb
        .collection(tapriumCollectionImage)
        .update(toUpscaleRecord.id, body: {"runner": ""});
    throw Exception("Failed to download image from taprium to upscale");
  }

  final originFile = File(originFileName);
  await originFile.writeAsBytes(response.bodyBytes);

  final upscaledFileName = 'upscaled-$originFileName';

  final args = [
    //
    '-s', upscaleTimes.toString(),
    //
    '-n', settingsRecord.getStringValue('upscale_model'),
    //
    '-i', originFileName,
    //
    '-o', upscaledFileName,
    //
  ];

  try {
    var process = await Process.start(
      './realesrgan-ncnn-vulkan',
      args,
      runInShell: true,
    );

    logger.i("Executing command: \n./realesrgan-ncnn-vulkan ${args.join(' ')}");

    // 2. Stream stdout (Standard Output)
    process.stdout
        .transform(utf8.decoder) // Convert bytes to UTF-8 strings
        .listen((data) {
          stdout.write(data); // Print to console in real-time
        });

    // 3. Stream stderr (Standard Error)
    process.stderr.transform(utf8.decoder).listen((data) {
      stderr.write(data); // Print errors in real-time
    });

    throwIf(
      await process.exitCode != 0,
      Exception('Failed to execute upscale'),
    );
    throwIf(
      originFile.lengthSync() == File(upscaledFileName).lengthSync(),
      Exception("Failed to upscale image"),
    );
  } catch (e) {
    await tapriumPb
        .collection(tapriumCollectionImage)
        .update(toUpscaleRecord.id, body: {"runner": ""});
    rethrow;
  }

  await tapriumPb
      .collection(tapriumCollectionImage)
      .update(
        toUpscaleRecord.id,
        body: {"upscaled": true},
        files: [await http.MultipartFile.fromPath('upscaled_image', upscaledFileName)],
      );

  await File(upscaledFileName).delete();
  await originFile.delete();

  logger.i("Upscale [${toUpscaleRecord.id}] finished");
}
