import 'package:logger/web.dart';

final logger = Logger(
  printer: PrettyPrinter(dateTimeFormat: DateTimeFormat.dateAndTime),
);
