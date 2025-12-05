// @license
// Copyright (c) 2019 - 2025 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:test/test.dart';

/// Deeply checks that json contains all elements of expected json.
Matcher deepJsonContains(dynamic expected) => _DeepJsonContains(expected);

class _DeepJsonContains extends Matcher {
  final dynamic expected;

  _DeepJsonContains(this.expected);

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    return _matches(item, expected);
  }

  bool _matches(dynamic actual, dynamic expected) {
    // Map: expected ⊆ actual
    if (expected is Map) {
      if (actual is! Map) return false;
      for (final key in expected.keys) {
        if (!actual.containsKey(key)) return false;
        if (!_matches(actual[key], expected[key])) return false;
      }
      return true;
    }

    // List: vergleicht nur die ersten expected.length Elemente
    if (expected is List) {
      if (actual is! List) return false;
      if (expected.length > actual.length) return false;
      for (var i = 0; i < expected.length; i++) {
        if (!_matches(actual[i], expected[i])) return false;
      }
      return true;
    }

    // primitive Werte
    return actual == expected;
  }

  @override
  Description describe(Description description) {
    return description.add('deeply contains $expected');
  }
}
