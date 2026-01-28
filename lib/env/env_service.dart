import 'dart:io';

import 'package:taprium_upscale_runner/env/env.dart';

class EnvironmentService {
  static String get tapriumAddr {
    return Platform.environment['TAPRIUM_ADDR'] ?? Env.tapriumAddr ?? '';
  }

  static String get tapriumSecret {
    return Platform.environment['TAPRIUM_AUTH_SECRET'] ??
        Env.tapriumSecret ??
        '';
  }
}
