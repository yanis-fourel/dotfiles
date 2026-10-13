import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import hypruse_activity as activity


class ActivityTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.addCleanup(self.tmp.cleanup)

    def state(self, pid=1, **changes):
        data = dict(pid=pid, processStart='42', started=1000, heartbeat=159000, run=str(pid))
        data.update(changes)
        (self.root / f'{pid}.json').write_text(json.dumps(data))

    def collect(self):
        return activity.collect(self.root, now=160000, identify=lambda _: '42')

    def test_idle(self):
        self.assertFalse(self.collect()['active'])

    def test_elapsed(self):
        self.state()
        self.assertEqual(self.collect()['elapsed'], 159)

    def test_stale_is_uncertain(self):
        self.state(heartbeat=1000)
        self.assertFalse(self.collect()['active'])
        self.assertTrue(self.collect()['uncertain'])

    def test_reused_pid(self):
        self.state(processStart='99')
        self.assertTrue(self.collect()['uncertain'])

    def test_concurrent_sessions(self):
        self.state()
        self.state(2, started=61000)
        self.assertEqual(self.collect()['count'], 2)
        self.assertEqual(self.collect()['elapsed'], 159)

    def test_broken_file(self):
        (self.root / '1.json').write_text('{')
        self.assertTrue(self.collect()['uncertain'])

    def test_stop_targets_run_and_invokes_native_stop(self):
        self.state()
        with patch.object(activity, 'ROOT', self.root), patch.object(activity.subprocess, 'run') as run:
            activity.stop()
        self.assertEqual(json.loads((self.root / 'stop.json').read_text())['runs'], ['1'])
        self.assertEqual(run.call_args.args[0], ['/usr/bin/hypruse', 'stop'])


if __name__ == '__main__':
    unittest.main()
