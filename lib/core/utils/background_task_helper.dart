import 'dart:isolate';
import 'dart:async';

/// Helper class for running heavy operations in background
class BackgroundTaskHelper {
  /// Runs a heavy computation in a background isolate
  static Future<T> runInBackground<T, P>(
      Future<T> Function(P param) heavyFunction, P param) async {
    final completer = Completer<T>();

    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn<_IsolateMessage<P>>(
      _isolateRunner<T, P>,
      _IsolateMessage(
        port: receivePort.sendPort,
        function: heavyFunction,
        param: param,
      ),
    );

    receivePort.listen((message) {
      if (message is _IsolateResponse<T>) {
        if (message.error != null) {
          completer.completeError(message.error!, message.stackTrace);
        } else {
          completer.complete(message.result);
        }
        // Clean up resources
        receivePort.close();
        isolate.kill();
      }
    });

    return completer.future;
  }

  // Helper function that runs in the isolate
  static void _isolateRunner<T, P>(_IsolateMessage<P> message) async {
    try {
      final result = await message.function(message.param);
      message.port.send(_IsolateResponse<T>(result: result as T));
    } catch (e, st) {
      message.port.send(_IsolateResponse<T>(error: e, stackTrace: st));
    }
  }
}

// Helper class to pass messages to isolate
class _IsolateMessage<P> {
  final SendPort port;
  final Function(P param) function;
  final P param;

  _IsolateMessage({
    required this.port,
    required this.function,
    required this.param,
  });
}

// Helper class to return response from isolate
class _IsolateResponse<T> {
  final T? result;
  final Object? error;
  final StackTrace? stackTrace;

  _IsolateResponse({
    this.result,
    this.error,
    this.stackTrace,
  });
}
