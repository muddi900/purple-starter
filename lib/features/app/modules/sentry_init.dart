import 'dart:async';

import 'package:l/l.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:stream_transform/stream_transform.dart';

mixin SentryInit {
  static bool _isWarningOrError(LogMessage message) => message.level.maybeWhen(
        warning: () => true,
        error: () => true,
        orElse: () => false,
      );

  static Stream<LogMessageWithStackTrace> get _warningsAndErrors =>
      l.where(_isWarningOrError).whereType<LogMessageWithStackTrace>();

  static StreamSubscription<void> _subscribeToErrorReporting() =>
      _warningsAndErrors
          .asyncMap(
            (msg) => Sentry.captureException(
              msg.message,
              stackTrace: msg.stackTrace,
            ),
          )
          .listen((_) {});

  static Future<StreamSubscription<void>> init(bool shouldSend) async {
    const dsn = String.fromEnvironment("SENTRY_DSN");
    if (dsn != "" && shouldSend) {
      await SentryFlutter.init(
        (options) => options
          ..dsn = dsn
          ..tracesSampleRate = 1,
      );
      return _subscribeToErrorReporting();
    }
    return const Stream<void>.empty().listen((_) {});
  }
}
