import 'dart:convert';
import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:retry/retry.dart';
import 'package:taprium_upscale_runner/env/env_service.dart';
import 'package:http/http.dart' as http;
import 'package:taprium_upscale_runner/log.dart';

const tapriumCollectionImage = "generated_images";
const tapriumCollectionUpscaleRunners = 'upscale_runners';
const tapriumCollectionSetttings = 'settings';

/// Reads the unique hardware ID from the Linux host
Future<String> _getMachineId() async {
  try {
    // Assumes you bind-mounted /etc/machine-id into the container
    final file = File('/etc/machine-id');
    return (await file.readAsString()).trim();
  } catch (e) {
    // Fallback to hostname if machine-id is inaccessible
    return Platform.localHostname;
  }
}

Future trySignIn() async {
  if (EnvironmentService.tapriumAddr == '') {
    throw Exception("[TAPRIUIM_ADDR] was not set");
  }
  final pocketbase = PocketBase(EnvironmentService.tapriumAddr);
  GetIt.instance.registerSingleton(pocketbase);

  final machineId = await _getMachineId();
  final hostname = Platform.localHostname;

  // Use the 'retry' package to handle the "Waiting for Admin" loop
  final token = await retry(
    () async {
      final response = await http
          .post(
            Uri.parse(
              '${pocketbase.baseURL.replaceAll(RegExp(r'/$'), '')}/api/cluster/auth',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'secret': EnvironmentService.tapriumSecret,
              'machine_id': machineId,
              'hostname': hostname,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Success: Admin granted access
        final data = jsonDecode(response.body);
        logger.i('✅ Access Granted for $hostname');
        return data['token'] as String;
      }

      if (response.statusCode == 202 || response.statusCode == 403) {
        // Pending: Device registered but not verified
        logger.i('⏳ Waiting for admin to verify $hostname ($machineId)...');
        throw Exception('Pending verification');
      }

      // Fatal Error: Invalid secret or server down
      throw Exception('Auth failed: ${response.statusCode}');
    },
    // Retry configuration
    retryIf: (e) => e.toString().contains('Pending verification'),
    delayFactor: const Duration(seconds: 10), // Wait 10s between checks
    maxAttempts: 100, // Effectively "blocks" until admin acts
  );

  pocketbase.authStore.save(token, null);
  await pocketbase.collection(tapriumCollectionUpscaleRunners).authRefresh();

  if (pocketbase.authStore.isValid) {
    final deviceRecord = pocketbase
        .authStore
        .record; // Access fields using the generic .get() method or specific helpers
    logger.i('Upscale worker id: ${deviceRecord?.id}');
    // logger.i('Machine ID: ${deviceRecord?.getStringValue("machine_id")}');
    // logger.i('Verified: ${deviceRecord?.getBoolValue("verified")}');
  }
}
