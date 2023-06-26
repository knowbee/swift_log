# swift_log

A comprehensive logging solution designed specifically for flutter apps.

## Description

The `swift_log` package is a logging solution developed to facilitate comprehensive logging functionalities in flutter applications. It provides the ability to capture and upload logs to a remote server for analysis and debugging purposes.


## Features

- Capturing exceptions with customizable tags, subtags, and log messages
- Capturing events with event names, log messages, and log levels
- Saving events to device storage (They are cleared out as soon as they get pushed to your logs API)

## Getting Started

To get started with the `swift_log` package, follow these steps:

1. Add the `swift_log` dependency to your project's `pubspec.yaml` file:

   ```yaml
   dependencies:
     swift_log:
   ```

2. Import the package and initialize the logger in your code:

```dart
import 'package:swift_log/swift_log.dart';

void main() async {

  await SwiftLog.init(
    (options) {
      options.apiPrefix = 'https://your-custom-log-server.com';
      options.token = 'yourApiToken';
    },
    appRunner: () async {
      return runApp(
        const App(),
      );
    },
  );
  // capture and upload logs, with associated events

  SwiftLog.captureException(
        logMessage: "Exception occurred",
        level: LogLevel.error,
        exception: e as Exception,
        stackTrace: stackTrace,
    );

  /// track events
  SwiftLog.captureEvent(
    eventName: "Fetching clients",
    logMessage: "Fetching clients",
    level: LogLevel.info,
  );
}
```

For more details on usage and examples, refer to the example directory.

### Contributing

Contributions to the `swift_log` package are welcome! If you encounter any issues or have suggestions for improvements, please open an issue on this repository.
