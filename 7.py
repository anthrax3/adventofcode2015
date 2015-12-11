import fileinput
import re
import unittest

from collections import namedtuple, defaultdict

Value = namedtuple('Value', ['value', 'output'])
Equal = namedtuple('Equal', ['input', 'output'])
And_vi = namedtuple('And_vi', ['value', 'input', 'output'])
And_ii = namedtuple('And_ii', ['input_1', 'input_2', 'output'])
Or = namedtuple('Or', ['input_1', 'input_2', 'output'])
RShift = namedtuple('RShift', ['input_1', 'value', 'output'])
LShift = namedtuple('LShift', ['input_1', 'value', 'output'])
Not = namedtuple('Not', ['input', 'output'])

class ParseError(Exception):
    pass

def parse(line):
    matchers = [
        [r"(\d+) -> ([a-z]+)", lambda v, o: Value(int(v), o)],
        [r"([a-z]+) -> ([a-z]+)", lambda i, o: Equal(i, o)],
        [r"(\d+) AND ([a-z]+) -> ([a-z]+)", lambda v, i, o: And_vi(int(v), i, o)],
        [r"([a-z]+) AND ([a-z]+) -> ([a-z]+)", lambda i1, i2, o: And_ii(i1, i2, o)],
        [r"([a-z]+) OR ([a-z]+) -> ([a-z]+)", lambda i1, i2, o: Or(i1, i2, o)],
        [r"([a-z]+) LSHIFT (\d+) -> ([a-z]+)", lambda i1, v, o: LShift(i1, int(v), o)],
        [r"([a-z]+) RSHIFT (\d+) -> ([a-z]+)", lambda i1, v, o: RShift(i1, int(v), o)],
        [r"NOT ([a-z]+) -> ([a-z]+)", lambda i, o: Not(i, o)],
    ]

    for matcher, generator in matchers:
        match = re.match(matcher, line)
        if match:
            return generator(*match.groups())

    raise ParseError(line)

class TestParser(unittest.TestCase):
    def test_passing_examples(self):
        examples = [
            ["123 -> x", Value(123, 'x')],
            ["456 -> y", Value(456, 'y')],
            ["x -> y", Equal('x', 'y')],
            ["x AND y -> d", And_ii('x', 'y', 'd')],
            ["x OR y -> e", Or('x', 'y', 'e')],
            ["x LSHIFT 2 -> f", LShift('x', 2, 'f')],
            ["y RSHIFT 2 -> g", RShift('y', 2, 'g')],
            ["NOT x -> h", Not('x', 'h')],
            ["NOT y -> i", Not('y', 'i')],
        ]

        for expression, expected in examples:
            self.assertEqual(parse(expression), expected)

    def test_fail(self):
        with self.assertRaises(ParseError):
            parse("hello")

class Tangle(Exception):
    pass

need_table = {
    Value: lambda s, (v, o): [],
    Equal: lambda s, (i, o): [i],
    And_vi: lambda s, (v, i, o): [i],
    And_ii: lambda s, (i1, i2, o): [i1, i2],
    Or: lambda s, (i1, i2, o): [i1, i2],
    LShift: lambda s, (i, v, o): [i],
    RShift: lambda s, (i, v, o): [i],
    Not: lambda s, (i, o): [i],
}

eval_table = {
    Value: lambda s, (v, o): v,
    Equal: lambda s, (i, o): s[i],
    And_vi: lambda s, (v, i, o): v & s[i],
    And_ii: lambda s, (i1, i2, o): s[i1] & s[i2],
    Or: lambda s, (i1, i2, o): s[i1] | s[i2],
    LShift: lambda s, (i, v, o): s[i] << v,
    RShift: lambda s, (i, v, o): (s[i] >> v) & 0xFFFF,
    Not: lambda s, (i, o): (~s[i]) & 0xFFFF,
}

class TestEvaluations(unittest.TestCase):
    def test_16_bit_rshift(self):
        e = eval_table[RShift]
        self.assertEqual(e({'x': 0xFFFF}, ('x', 4, None)), 0x0FFF)

    def test_16_bit_not(self):
        e = eval_table[Not]
        self.assertEqual(e({'x': 0xFFFF}, ('x', None)), 0x0000)

State = namedtuple('State', ['signals', 'waiting'])

def evaluate(state, gate):
    signals, waiting = state.signals, state.waiting

    if signals.has_key(gate.output):
        return state

    needs = [i for i in need_table[type(gate)](signals, gate)
                if not signals.has_key(i)]

    if needs:
        for i in needs:
            waiting[i] = waiting.get(i, set()).union({gate})
    else:
        signals[gate.output] = eval_table[type(gate)](signals, gate)

        for maybe_ready_gate in waiting.pop(gate.output, []):
            evaluate(state, maybe_ready_gate)

    return state

class TestEvaluate(unittest.TestCase):
    def test_unsatisfied(self):
        gate = And_ii('x', 'y', 'z')

        signals, waiting = evaluate(State({}, {}), gate)

        self.assertEqual(signals, {})
        self.assertEqual(waiting, {'x': {gate}, 'y': {gate}})

    def test_simple_delay(self):
        state = State({}, {'y': { Not('y', 'x') }})

        signals, waiting = evaluate(state, Value(0, 'y'))

        self.assertEqual(signals, {'x': 65535, 'y': 0})
        self.assertEqual(waiting, {})

    def test_double_delay(self):
        state = State({}, {'x': {And_ii('x', 'y', 'z')}, 'y': {And_ii('x', 'y', 'z')}})
        gates = [Value(0, 'x'), Value(123, 'y')]

        signals, waiting = reduce(evaluate, gates, state)

        self.assertEqual(signals, {'x': 0, 'y': 123, 'z': 0})
        self.assertEqual(waiting, {})

    def test_deep_delay(self):
        pass

    def test_ignore_override(self):
        state = State({'x': 123}, {})

        signals, waiting = evaluate(state, Value(0, 'x'))

        self.assertEqual(signals, {'x': 123})
        self.assertEqual(waiting, {})

    def test_passing_example(self):
        gates = [
            Value(123, 'x'),
            Value(456, 'y'),
            And_ii('x', 'y', 'd'),
            Or('x', 'y', 'e'),
            LShift('x', 2, 'f'),
            RShift('y', 2, 'g'),
            Not('x', 'h'),
            Not('y', 'i'),
        ]

        expected_signals = {
            'd': 72,
            'e': 507,
            'f': 492,
            'g': 114,
            'h': 65412,
            'i': 65079,
            'x': 123,
            'y': 456,
        }

        signals, waiting = reduce(evaluate, gates, State({}, {}))

        self.assertEqual(signals, expected_signals)
        self.assertEqual(waiting, {})

if __name__ == '__main__':
    circuits = [parse(line) for line in fileinput.input()]
    signals, waiting = reduce(evaluate, circuits, State({}, {}))

    print "a: %s" % (signals['a'], )

    signals, waiting = reduce(evaluate, circuits, State({'b': signals['a']}, {}))

    print "a: %s" % (signals['a'], )
