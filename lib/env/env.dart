import 'package:envied/envied.dart';

part 'env.g.dart';

/*
After .env file updated run the following commands:

dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs

*/

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'TAPRIUIM_ADDR', optional: true)
  static const String? tapriumAddr = _Env.tapriumAddr;

  @EnviedField(varName:'TAPRIUM_AUTH_SECRET',optional:true)
  static const String? tapriumSecret = _Env.tapriumSecret;

}
