import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:swift_log/constants/constants.dart';
import 'package:synchronized/synchronized.dart';

import '../models/event.dart';

class EventStorageManager {
  final _lock = Lock();

  Future<void> clearEvents() async {
    final eventFile = await _getEventFile();
    if (await eventFile.exists()) {
      await eventFile.delete();
    }
  }

  Future<void> saveEventToDevice(Event event) async {
    await _lock.synchronized(() async {
      final eventsDirectory =
          await _getEventsDirectory(Constants.commonLogsDirectory);
      if (eventsDirectory != null) {
        final eventFilePath = '${eventsDirectory.path}/events.txt';

        try {
          final eventFile = File(eventFilePath);
          final eventJson = jsonEncode(event.toJson());

          await eventFile.writeAsString('$eventJson\n',
              mode: FileMode.append, flush: true);

          developer.log('SwiftLog: Event has been saved');
        } catch (e) {
          developer.log('SwiftLog: Error saving events to file: $e');
        }
      }
    });
  }

  static Future<Directory?> _getEventsDirectory(String eventFolderName) async {
    if (Platform.isIOS) {
      final appDir = await getTemporaryDirectory();
      final eventsDir = Directory('${appDir.path}/$eventFolderName');
      return await eventsDir.create(recursive: true);
    } else if (Platform.isAndroid) {
      final externalDir = await getApplicationDocumentsDirectory();
      final appDir = '${externalDir.path}/$eventFolderName';
      final appDocDir = await Directory(appDir).create(recursive: true);
      return appDocDir;
    }
    throw UnsupportedError('Platform not supported');
  }

  Future<List<Event>?> getEvents() async {
    final eventFile = await _getEventFile();
    final events = <Event>[];

    if (await eventFile.exists()) {
      final lines = await eventFile.readAsLines();
      for (final line in lines) {
        final event = Event.fromJson(line);
        events.add(event);
      }
    }
    return events;
  }

  static Future<File> _getEventFile() async {
    final eventsDirectory =
        await _getEventsDirectory(Constants.commonLogsDirectory);
    final eventFilePath = '${eventsDirectory?.path}/events.txt';
    return File(eventFilePath);
  }
}
