import 'package:flutter/material.dart';
import 'package:swift_log/enums/log_level.dart';
import 'package:swift_log/swift_log.dart';

void main() async {
  await SwiftLog.init(
    (options) {
      options.apiPrefix = 'https://myloggerapi.example.com';
      options.token = 'myloggerapitoken';
    },
    appRunner: () async {
      return runApp(
        const MyApp(),
      );
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SwiftLog Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'SwiftLog Demo'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  void _captureException() {
    try {
      throw Exception("This is an exception!");
    } catch (e, stackTrace) {
      SwiftLog.captureException(
        logMessage: "Exception occurred",
        level: LogLevel.error,
        exception: e as Exception,
        stackTrace: stackTrace,
      );
    }
  }

  void _trackEvent() {
    SwiftLog.captureEvent(
      eventName: "Button Clicked",
      logMessage: "Button clicked event",
      level: LogLevel.info,
    );
  }

  void _printEvents() async {
    await SwiftLog.showEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _captureException,
              child: const Text("Capture Exception"),
            ),
            ElevatedButton(
              onPressed: _trackEvent,
              child: const Text("Track Event"),
            ),
            ElevatedButton(
              onPressed: _printEvents,
              child: const Text("Print Events"),
            ),
          ],
        ),
      ),
    );
  }
}
