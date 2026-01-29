import 'package:logger/web.dart';

class ReleaseLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    // Only show Info, Warning, Error, and Fatal in the binary
    return event.level.index >= Level.info.index;
  }
}

final logger = Logger(
  filter: ReleaseLogFilter(),
  printer: PrettyPrinter(
    dateTimeFormat: DateTimeFormat.dateAndTime,
    methodCount: 0,
    noBoxingByDefault: true,
  ),
);
