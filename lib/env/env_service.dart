import 'dart:io';

import 'package:taprium_upscale_runner/env/env.dart';

class EnvironmentService {
  static String get tapriumAddr {
    return Platform.environment['TAPRIUIM_ADDR'] ?? Env.tapriumAddr ?? '';
  }

  static String get tapriumUser {
    return Platform.environment['TAPRIUM_USER'] ?? Env.tapriumUser ?? '';
  }

  static String get tapriumPassword {
    return Platform.environment['TAPRIUM_PASSWORD'] ??
        Env.tapriumPassword ??
        '';
  }

  static String get hcVaultAddr {
    return Platform.environment['HC_VAULT_ADDR'] ?? Env.hcVaultAddr ?? '';
  }

  static String get hcVaultToken {
    return Platform.environment['HC_VAULT_TOKEN'] ?? Env.hcVaultToken ?? '';
  }

  static String get hcVaultKVMountPoint {
    return Platform.environment['HC_VAULT_KV_MP'] ??
        Env.hcVaultKVMountPoint ??
        '';
  }

  static String get hcVaultKVPathPrefix {
    return Platform.environment['HC_VAULT_KV_PATH_PREFIX'] ??
        Env.hcVaultKVPathPrefix ??
        '';
  }
}
