import 'dart:convert';
import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:taprium_upscale_runner/env/env_service.dart';
import 'package:http/http.dart' as http;
import 'package:taprium_upscale_runner/log.dart';

const tapriumCollectionImage = "generated_images";
const tapriumCollectionUpscaleRunners = 'upscale_runners';
const tapriumCollectionSetttings = 'settings';

Future trySignIn() async {
  if (EnvironmentService.tapriumAddr == '') {
    throw Exception("[TAPRIUIM_ADDR] was not set");
  }
  final pocketbase = PocketBase(EnvironmentService.tapriumAddr);
  GetIt.instance.registerSingleton(pocketbase);

  final collection = await BoxCollection.open('taprium', {'taprium'});

  final box = await collection.openBox('taprium');
  var token = await box.get('token');
  if (token != null) {
    try {
      pocketbase.authStore.save(token, null);
      await pocketbase
          .collection(tapriumCollectionUpscaleRunners)
          .authRefresh();

      await box.put('token', pocketbase.authStore.token);
      logger.i("Signed in using stored token");
      return;
    } catch (_) {
      await box.delete('token');
      logger.i(
        "Sign in failed from stored token, try using credentials from environment variables",
      );
    }
  }

  var tapriumUser = '';
  var tapriumPasssword = '';

  if (EnvironmentService.hcVaultAddr != '' &&
      EnvironmentService.hcVaultToken != '' &&
      EnvironmentService.hcVaultKVMountPoint != '' &&
      EnvironmentService.hcVaultKVPathPrefix != '') {
    var slotId = '1';
    if (bool.fromEnvironment('dart.vm.product')) {
      slotId = Platform.localHostname.split('.').last;
    }
    final urlString =
        "${EnvironmentService.hcVaultAddr}/v1/${EnvironmentService.hcVaultKVMountPoint}/data/${EnvironmentService.hcVaultKVPathPrefix}$slotId";

    final url = Uri.parse(urlString);
    var responses = await http.get(
      url,
      headers: {"X-Vault-Token": EnvironmentService.hcVaultToken},
    );

    if (responses.statusCode != 200) {
      switch (responses.statusCode) {
        case 403:
          throw Exception(
            "Error getting credentials from HC Vault: Permission Denied",
          );
        case 404:
          throw Exception("Error getting credentials from HC Vault: Not found");
        case 503:
          throw Exception(
            "Error getting credentials from HC Vault: Server is SEALED",
          );
        default:
          throw Exception(
            "Error getting credentials from HC Vault: status code ${responses.statusCode}",
          );
      }
    } //

    final result = jsonDecode(responses.body);
    final secrets = result['data']['data'];
    tapriumUser = secrets['username'];
    tapriumPasssword = secrets['password'];
  } else if (EnvironmentService.tapriumPassword != '' &&
      EnvironmentService.tapriumUser != '') {
    tapriumUser = EnvironmentService.tapriumUser;
    tapriumPasssword = EnvironmentService.tapriumPassword;
  } else {
    throw Exception(
      "Please provide either taprium credentials or HashiCorp Vault related variables",
    );
  }

  await pocketbase
      .collection('upscale_runners')
      .authWithPassword(tapriumUser, tapriumPasssword);
  await box.put('token', pocketbase.authStore.token);
}
