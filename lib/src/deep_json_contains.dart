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
    final errors = <String>[];
    final ok = _matches(item, expected, <String>[], errors);
    if (!ok) {
      matchState['errors'] = errors;
    }
    return ok;
  }

  bool _matches(
    dynamic actual,
    dynamic expected,
    List<String> path,
    List<String> errors,
  ) {
    String pfx() => path.isEmpty ? '' : '${path.join('/')}: ';

    // Map: expected ⊆ actual
    if (expected is Map) {
      if (actual is! Map) {
        errors.add('${pfx()}expected Map, got ${actual.runtimeType}');
        return false;
      }
      var allOk = true;
      for (final key in expected.keys) {
        if (!actual.containsKey(key)) {
          errors.add('${pfx()}missing key "$key"');
          allOk = false;
          continue;
        }
        final nextPath = [...path, key.toString()];
        final ok = _matches(actual[key], expected[key], nextPath, errors);
        if (!ok) allOk = false;
      }
      return allOk;
    }

    // List: only checks the first expected.length elements
    if (expected is List) {
      if (actual is! List) {
        errors.add('${pfx()}expected List, got ${actual.runtimeType}');
        return false;
      }
      if (expected.length > actual.length) {
        errors.add(
          '${pfx()}list too short: expected at least '
          '${expected.length}, got ${actual.length}',
        );
        // We still attempt to compare existing elements for detailed diffs.
      }
      var allOk = true;
      final len = expected.length <= actual.length
          ? expected.length
          : actual.length;
      for (var i = 0; i < len; i++) {
        final nextPath = [...path, '[$i]'];
        final ok = _matches(actual[i], expected[i], nextPath, errors);
        if (!ok) allOk = false;
      }
      return allOk && expected.length <= actual.length;
    }

    // Primitive values
    final equal = actual == expected;
    if (!equal) {
      errors.add('${pfx()}value mismatch: expected "$expected", got "$actual"');
    }
    return equal;
  }

  @override
  Description describe(Description description) {
    return description.add('deeply contains $expected');
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    final errors = (matchState['errors'] as List<String>?) ?? const [];
    if (errors.isEmpty) {
      // coverage:ignore-start
      return mismatchDescription.add('did not contain expected structure');
      // coverage:ignore-end
    }
    mismatchDescription.add('missing or mismatched fields:\n');
    for (final e in errors) {
      mismatchDescription.add('- $e\n');
    }
    return mismatchDescription;
  }
}
