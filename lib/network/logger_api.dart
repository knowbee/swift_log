import 'dart:developer' as developer;

import 'package:dio/dio.dart';

/// The LoggerApi class represents an API client for logging data to a specified endpoint.
/// It provides a method to send log data to the server using HTTP POST request.

class LoggerApi {
  final String apiPrefix;
  final String token;
  Dio? dio;

  /// Constructs a LoggerApi instance with the specified [apiPrefix] and [token].
  /// [apiPrefix] - The base URL prefix for the logging API.
  /// [token] - The authentication token used for API requests.

  LoggerApi(this.apiPrefix, this.token);

  /// Sends log data to the server using an HTTP POST request.
  /// [body] - The log data to be sent in the request body.
  /// Returns a Future<Response> representing the response from the server.

  Future<Response?> postLogData(Map<String, dynamic> body) async {
    try {
      return await dio!.post(apiPrefix, data: body);
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          developer.log(
              'Your API token is invalid. Please check your token and try again.');
        } else {
          developer
              .log('An error occurred while sending log data to the server.');
        }
      }
    }
    return null;
  }
}
