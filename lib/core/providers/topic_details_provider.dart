import 'package:flutter_riverpod/flutter_riverpod.dart';

final topicProvider = Provider<Map<String, String>>((ref) {
  return {
    'title': "Designing for minimal physical strain",
    'subtitle':
        "The design can be used efficiently and comfortably and with a minimum of fatigue.",
    'body':
        """While on first glance this principle seems most relevant to architecture where Universal design's roots lie, it can be useful for designing for digital technology as well. Using a computer all day is fatiguing, so designs should minimize effort by making sure users don't have to constantly move their cursor around a page to complete a task or make a task overly complicated.

    For example, relevant navigation should be anchored at the top of a webpage so the user doesn't have to repeatedly scroll up the page to access it.While on first glance this principle seems most relevant to architecture where Universal design's roots lie, it can be useful for designing for digital technology as well. Using a computer all day is fatiguing, so designs should minimize effort by making sure users don't have to constantly move their cursor around a page to complete a task or make a task overly complicated.

    For example, relevant navigation should be anchored at the top of a webpage so the user doesn't have to repeatedly scroll up the page to access it.""",
  };
});
