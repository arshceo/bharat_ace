// In lib/common/observers/app_route_observer.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bharat_ace/core/services/screen_time_tracker_service.dart'; // Adjust path as needed

class AppRouteObserver extends RouteObserver<ModalRoute<dynamic>> {
  final WidgetRef ref;

  AppRouteObserver(this.ref);

  void _updateScreenTime(ModalRoute<dynamic>? route) {
    final String? screenName = route?.settings.name;

    // Delay the provider modification
    Future.microtask(() {
      // We are assuming the ref and its associated container are still valid
      // because these observer callbacks typically happen while the app is active.
      // If the app is rapidly closing, this *could* still throw if the notifier
      // tries to update a disposed provider, but it's less common for this specific error.
      try {
        ref.read(screenTimeTrackerProvider.notifier).screenChanged(screenName);
      } catch (e) {
        // Optional: Log if an error still occurs, e.g., if provider was disposed
        print("Error updating screen time after delay: $e");
      }
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is ModalRoute) {
      _updateScreenTime(route);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute is ModalRoute) {
      _updateScreenTime(previousRoute);
    } else if (previousRoute == null) {
      _updateScreenTime(null);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute is ModalRoute) {
      _updateScreenTime(newRoute);
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    if (previousRoute is ModalRoute) {
      _updateScreenTime(previousRoute);
    } else if (previousRoute == null) {
      _updateScreenTime(null);
    }
  }
}
