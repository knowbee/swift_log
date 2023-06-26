// ignore_for_file: invalid_internal_annotation

import 'dart:async';
import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:meta/meta.dart';
import 'package:swift_log/models/event.dart';

import 'data/event_storage_manager.dart';
import 'enums/log_level.dart';
import 'network/logger_api.dart';

class CustomPrettyPrinter extends PrettyPrinter {}

class SwiftLogOptions {
  String? apiPrefix;
  String? token;
}

typedef RunZonedGuardedRunner = Future<void> Function();
typedef RunZonedGuardedOnError = FutureOr<void> Function(Object, StackTrace);
typedef OptionsConfiguration = FutureOr<void> Function(SwiftLogOptions);
typedef AppRunner = FutureOr<void> Function();

class SwiftLog {
  static late final LoggerApi loggerApi;
  static EventStorageManager eventStorageManager = EventStorageManager();

  static final Logger _logger = Logger(
    printer: CustomPrettyPrinter(),
  );

  static void printLogMessage(String message, LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        _logger.d(message);
        break;
      case LogLevel.fatal:
        _logger.v(message);
        break;
      case LogLevel.info:
        _logger.i(message);
        break;
      case LogLevel.warning:
        _logger.w(message);
        break;
      case LogLevel.error:
        _logger.e(message);
        break;
      default:
        _logger.d(message);
        break;
    }
  }

  static final Map<String, dynamic> _swiftLogProperties = {
    '\$lib_version': '1.0.0',
    'mp_lib': 'flutter',
  };

  static Future<void> init(
    OptionsConfiguration optionsConfiguration, {
    AppRunner? appRunner,
    @internal bool callAppRunnerInRunZonedGuarded = true,
    @internal RunZonedGuardedOnError? runZonedGuardedOnError,
    List<LogLevel>? logLevelsEnabled,
    List<String>? logTypesEnabled,
    Map<String, dynamic>? superProperties,
    SwiftLogOptions? options,
  }) async {
    final loggerOptions = options ?? SwiftLogOptions();

    try {
      final config = optionsConfiguration(loggerOptions);
      if (config is Future) {
        await config;
      }
    } catch (exception) {
      printLogMessage(
        'Error in options configuration.',
        LogLevel.error,
      );
    }

    if (loggerOptions.apiPrefix == null) {
      throw ArgumentError('Api prefix is required.');
    }

    _swiftLogProperties['token'] = loggerOptions.token;
    _swiftLogProperties['logTypesEnabled'] = logTypesEnabled;
    _swiftLogProperties['superProperties'] = superProperties;
    _swiftLogProperties['apiPrefix'] = loggerOptions.apiPrefix;
    var logLevelsEnabledList =
        logLevelsEnabled?.map((e) => _getLogLevel(e)) ?? <String>[];
    _swiftLogProperties['logLevelsEnabled'] = logLevelsEnabledList;

    SwiftLog.loggerApi = LoggerApi(
      loggerOptions.apiPrefix!,
      loggerOptions.token!,
    );
    await _init(loggerOptions, appRunner, callAppRunnerInRunZonedGuarded,
        runZonedGuardedOnError);
  }

  SwiftLog._(loggerApi);

  static Future<void> _init(
    SwiftLogOptions options,
    AppRunner? appRunner,
    bool callAppRunnerInRunZonedGuarded,
    RunZonedGuardedOnError? runZonedGuardedOnError,
  ) async {
    if (appRunner != null) {
      if (callAppRunnerInRunZonedGuarded) {
        runIntegrationsAndAppRunner() async {
          await appRunner();
        }

        runZonedGuarded(
          runIntegrationsAndAppRunner,
          (error, stackTrace) async {
            if (runZonedGuardedOnError != null) {
              await runZonedGuardedOnError(error, stackTrace);
            }
          },
        );
      } else {
        runZonedGuarded(
          appRunner,
          (error, stackTrace) async {
            if (runZonedGuardedOnError != null) {
              await runZonedGuardedOnError(error, stackTrace);
            }
          },
        );
      }
    } else {
      runZonedGuardedOnError?.call(
        ArgumentError('The `appRunner` parameter must not be null'),
        StackTrace.current,
      );
    }
  }

  static Future<void> captureException({
    String tag = "",
    String subTag = "",
    String logMessage = "",
    LogLevel level = LogLevel.info,
    Exception? exception,
    StackTrace? stackTrace,
    Error? error,
    String errorMessage = "",
  }) async {
    _initializeDio();

    var localEvents = await eventStorageManager.getEvents();
    var body = {
      'tag': tag,
      'subTag': subTag,
      'logMessage': _buildLogMessage(
        logMessage,
        error: error,
        errorMessage: errorMessage,
      ),
      'level': _getLogLevel(level),
      'deviceInfo': await _getDeviceInfo(),
      'data': {
        'events': localEvents,
        'timestamp': DateTime.now().toIso8601String(),
        'message': exception?.toString(),
        'stackTrace': stackTrace?.toString(),
      }
    };
    await loggerApi.postLogData(body);
    await eventStorageManager.clearEvents();
    printLogMessage('$exception', LogLevel.debug);
  }

  static Future<void> captureEvent({
    String eventName = "",
    String logMessage = "",
    LogLevel level = LogLevel.info,
    StackTrace? stackTrace,
  }) async {
    eventStorageManager.saveEventToDevice(
      Event(
        timestamp: DateTime.now().toIso8601String(),
        level: level.name,
        message: logMessage,
      ),
    );
  }

  static void _initializeDio() {
    loggerApi.dio ??= Dio(BaseOptions(
      baseUrl: _swiftLogProperties['apiPrefix'],
      contentType: 'application/json',
      headers: {"Authorization": _swiftLogProperties['token']},
      followRedirects: true,
    ));
  }

  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    if (Platform.isIOS) {
      final iosInfo = await deviceInfoPlugin.iosInfo;
      return _readIosDeviceInfo(iosInfo);
    } else {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      return _readAndroidBuildData(androidInfo);
    }
  }

  static String _buildLogMessage(String logMessage,
      {Error? error, String? errorMessage}) {
    if (error != null) {
      return '$logMessage , Error: ${error.toString()}';
    } else if (errorMessage != null) {
      return '$logMessage , Error: $errorMessage';
    } else {
      return logMessage;
    }
  }

  static Map<String, dynamic> _readIosDeviceInfo(IosDeviceInfo data) {
    return <String, dynamic>{
      'name': data.name,
      'systemName': data.systemName,
      'systemVersion': data.systemVersion,
      'model': data.model,
      'localizedModel': data.localizedModel,
      'identifierForVendor': data.identifierForVendor,
      'isPhysicalDevice': data.isPhysicalDevice,
      'utsname.sysname:': data.utsname.sysname,
      'utsname.nodename:': data.utsname.nodename,
      'utsname.release:': data.utsname.release,
      'utsname.version:': data.utsname.version,
      'utsname.machine:': data.utsname.machine,
    };
  }

  static Map<String, dynamic> _readAndroidBuildData(AndroidDeviceInfo build) {
    return <String, dynamic>{
      'version.release': build.version.release,
      'version.sdkInt': build.version.sdkInt,
      'brand': build.brand,
      'device': build.device,
      'manufacturer': build.manufacturer,
      'model': build.model,
      'product': build.product,
      'isPhysicalDevice': build.isPhysicalDevice,
      'displaySizeInches':
          ((build.displayMetrics.sizeInches * 10).roundToDouble() / 10),
      'displayWidthPixels': build.displayMetrics.widthPx,
      'displayHeightPixels': build.displayMetrics.heightPx,
      'displayXDpi': build.displayMetrics.xDpi,
      'displayYDpi': build.displayMetrics.yDpi,
    };
  }

  static String _getLogLevel(LogLevel type) {
    return type.name.toString().split('.').last;
  }

  static Future<List<Event>?> showEvents() async {
    List<Event>? events = await eventStorageManager.getEvents();
    if (events != null) {
      for (var element in events) {
        printLogMessage(
          'Event: ${element.message} ${element.timestamp} ${element.level}',
          LogLevel.fromName(element.level),
        );
      }
    }
    return events;
  }
}
