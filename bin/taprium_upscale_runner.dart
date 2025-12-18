import 'dart:io';

import 'package:taprium_upscale_runner/log.dart';
import 'package:taprium_upscale_runner/taprium_pb.dart';
import 'package:taprium_upscale_runner/upscale.dart';

void main(List<String> arguments) async {
  final file = File('/var/lock/run.lock');
  RandomAccessFile raf = await file.open(mode: FileMode.write);

  try {
    await raf.lock();
    await raf.writeString('Locked content written at ${DateTime.now()}');
    logger.i('File locked successfully.');
  } catch (e) {
    logger.f('Failed to lock file: $e');
    return;
  }

  try {
    await trySignIn();
  } catch (e) {
    logger.f("Failed to Sign In: $e");
    return;
  }

  var doUpscale = true;
  while (doUpscale) {
    try {
      await upscale();
    } catch (e) {
      logger.w(e);
      doUpscale = false;
    }
  }

  await raf.unlock();
  await raf.close();
  logger.i('File unlocked and closed.');
}
