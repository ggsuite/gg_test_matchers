// @license
// Copyright (c) 2025 ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_test_matchers/src/deep_json_contains.dart';
import 'package:test/test.dart';

void main() {
  group('deepJsonContains', () {
    test('matches primitive equality', () {
      expect(42, deepJsonContains(42));
      expect('a', deepJsonContains('a'));
      expect(true, deepJsonContains(true));
      expect(null, deepJsonContains(null));
    });

    test('fails for primitive inequality', () {
      expect(42, isNot(deepJsonContains(41)));
      expect('a', isNot(deepJsonContains('b')));
      expect(true, isNot(deepJsonContains(false)));
      expect(null, isNot(deepJsonContains('null')));
      expect('null', isNot(deepJsonContains(null)));
    });

    test('matches map subset (expected ⊆ actual)', () {
      final actual = {
        'a': 1,
        'b': 2,
        'nested': {'x': 10, 'y': 20},
        'extra': 'ok',
      };
      expect(actual, deepJsonContains({'a': 1}));
      expect(
        actual,
        deepJsonContains({
          'nested': {'x': 10},
        }),
      );
      expect(
        actual,
        deepJsonContains({
          'b': 2,
          'nested': {'y': 20},
        }),
      );
    });

    test('fails when expected map key is missing or value mismatches', () {
      final actual = {
        'a': 1,
        'nested': {'x': 10, 'y': 20},
      };
      expect(actual, isNot(deepJsonContains({'missing': 0})));
      expect(actual, isNot(deepJsonContains({'a': 2})));
      expect(
        actual,
        isNot(
          deepJsonContains({
            'nested': {'x': 11},
          }),
        ),
      );
    });

    test('fails when actual is not a map but expected is a map', () {
      expect('not a map', isNot(deepJsonContains({'a': 1})));
      expect(123, isNot(deepJsonContains({'a': 1})));
      expect(null, isNot(deepJsonContains({'a': 1})));
    });

    test('matches list prefix (first expected.length elements)', () {
      final actual = [1, 2, 3, 4];
      expect(actual, deepJsonContains([1]));
      expect(actual, deepJsonContains([1, 2]));
      expect(actual, deepJsonContains([1, 2, 3]));
    });

    test('fails when expected list longer than actual', () {
      expect([1, 2], isNot(deepJsonContains([1, 2, 3])));
    });

    test('matches not when list prefix values mismatch', () {
      final actual = [1, 2, 3, 4];
      expect(actual, deepJsonContains([2]));
      expect(actual, deepJsonContains([1, 3]));
    });

    test('fails when actual has extra elements', () {
      expect([1, 2, 3, 4], isNot(deepJsonContains([1, 2, 3, 4, 5])));
    });

    test('matches when actual has extra elements', () {
      expect([1, 2, 3, 4], deepJsonContains([2, 4]));
    });

    test('fails when actual has same elements in different order', () {
      expect([1, 2, 3, 4], isNot(deepJsonContains([4, 3, 2, 1])));
    });

    test('fails when an element is repeated in expected but not in actual', () {
      expect([1, 2, 3, 4], isNot(deepJsonContains([1, 1])));
    });

    test('handles nested lists and maps', () {
      final actual = {
        'items': [
          {
            'id': 1,
            'name': 'A',
            'meta': [true, false],
          },
          {
            'id': 2,
            'name': 'B',
            'meta': [false, true],
          },
        ],
        'count': 2,
      };

      expect(
        actual,
        deepJsonContains({
          'items': [
            {
              'id': 1,
              'meta': [true],
            },
          ],
        }),
      );

      expect(
        actual,
        isNot(
          deepJsonContains({
            'items': [
              {
                'id': 1,
                'meta': [false, false],
              },
            ],
          }),
        ),
      );
    });

    test('extra keys in actual maps are allowed', () {
      final actual = {'a': 1, 'b': 2, 'c': 3};
      expect(actual, deepJsonContains({'a': 1}));
      expect(actual, deepJsonContains({'b': 2}));
      expect(actual, deepJsonContains({'a': 1, 'b': 2}));
    });

    test('empty expected structures always fail', () {
      expect(
        <String, dynamic>{},
        isNot(deepJsonContains(<dynamic, dynamic>{})),
      );
      expect({'a': 1}, isNot(deepJsonContains(<dynamic, dynamic>{})));
      expect(<dynamic>[], isNot(deepJsonContains(<dynamic>[])));
      expect([1, 2, 3], isNot(deepJsonContains(<dynamic>[])));
    });

    test('type mismatch scenarios', () {
      expect({'a': 1}, isNot(deepJsonContains(['a'])));
      expect([1, 2], isNot(deepJsonContains({'0': 1})));
      expect(1, isNot(deepJsonContains([1])));
      expect([1], isNot(deepJsonContains(1)));
    });

    test('complex example combining maps and list prefixes', () {
      final actual = {
        'user': {
          'id': 123,
          'name': 'Alice',
          'roles': ['admin', 'editor', 'viewer'],
          'settings': {
            'theme': 'dark',
            'flags': [true, true, false],
          },
        },
        'version': 1,
      };

      expect(
        actual,
        deepJsonContains({
          'user': {
            'id': 123,
            'roles': ['admin', 'editor'],
            'settings': {
              'flags': [true, true],
            },
          },
        }),
      );

      expect(
        actual,
        isNot(
          deepJsonContains({
            'user': {
              'roles': ['editor', 'admin'], // wrong order
            },
          }),
        ),
      );
    });

    test('describe', () {
      final matcher = deepJsonContains({
        'a': 1,
        'b': [2, 3],
      });
      final description = StringDescription();
      matcher.describe(description);
      expect(description.toString(), 'deeply contains {a: 1, b: [2, 3]}');
    });

    group('describeMismatch', () {
      test('unnested json', () {
        late final List<String> message;

        try {
          expect({'a': 10, 'b': 11}, deepJsonContains({'a': 10, 'b': 12}));
        } catch (e) {
          message = ((e as dynamic).message!.split('\n') as List<String>);
        }

        expect(message, [
          'Expected: deeply contains {a: 10, b: 12}',
          '  Actual: {\'a\': 10, \'b\': 11}',
          '   Which: missing or mismatched fields:',
          '          - b: value mismatch: expected "12", got "11"',
          '          ',
          '',
        ]);
      });

      test('nested json', () {
        late final List<String> message;

        try {
          expect(
            {
              'a': 10,
              'b': 11,
              'x': {'y': 20, 'z': 30},
            },
            deepJsonContains({
              'a': 10,
              'b': 10,
              'x': {'y': 21},
            }),
          );
        } catch (e) {
          message = ((e as dynamic).message!.split('\n') as List<String>);
        }

        expect(message, [
          'Expected: deeply contains {a: 10, b: 10, x: {y: 21}}',
          '  Actual: {\'a\': 10, \'b\': 11, \'x\': {\'y\': 20, \'z\': 30}}',
          '   Which: missing or mismatched fields:',
          '          - b: value mismatch: expected "10", got "11"',
          '          - x/y: value mismatch: expected "21", got "20"',
          '          ',
          '',
        ]);
      });
    });
  });
}
