import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'TAPRIUIM_ADDR', optional: true)
  static const String? tapriumAddr = _Env.tapriumAddr;

  @EnviedField(varName: 'TAPRIUM_USER', optional: true)
  static const String? tapriumUser = _Env.tapriumUser;

  @EnviedField(varName: 'TAPRIUM_PASSWORD', optional: true)
  static const String? tapriumPassword = _Env.tapriumPassword;

  @EnviedField(varName: 'HC_VAULT_ADDR', optional: true)
  static const String? hcVaultAddr = _Env.hcVaultAddr;

  @EnviedField(varName: 'HC_VAULT_TOKEN', optional: true)
  static const String? hcVaultToken = _Env.hcVaultToken;

  @EnviedField(varName: 'HC_VAULT_KV_MP', optional: true)
  static const String? hcVaultKVMountPoint = _Env.hcVaultKVMountPoint;

  @EnviedField(varName: 'HC_VAULT_KV_PATH_PREFIX', optional: true)
  static const String? hcVaultKVPathPrefix = _Env.hcVaultKVPathPrefix;
}
