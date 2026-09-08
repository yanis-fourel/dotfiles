import tempfile
import unittest
from pathlib import Path

from desktop_status import last_upgrade


class UpgradeHistoryTests(unittest.TestCase):
    def parse(self, events):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'pacman.log'
            path.write_text('\n'.join(f'[2026-08-25T20:55:32+0700] {event}' for event in events))
            return last_upgrade(path)

    def test_full_upgrade_completed(self):
        self.assertIsNotNone(self.parse([
            "[PACMAN] Running 'pacman -Syu'",
            '[PACMAN] starting full system upgrade',
            '[ALPM] transaction started',
            '[ALPM] transaction completed',
        ]))

    def test_aborted_upgrade_then_unrelated_install(self):
        self.assertIsNone(self.parse([
            '[PACMAN] starting full system upgrade',
            "[PACMAN] Running 'pacman -S quickshell'",
            '[ALPM] transaction started',
            '[ALPM] transaction completed',
        ]))

    def test_incomplete_or_no_change_upgrade(self):
        self.assertIsNone(self.parse([
            '[PACMAN] starting full system upgrade',
            '[ALPM] transaction started',
        ]))

    def test_plain_install(self):
        self.assertIsNone(self.parse([
            "[PACMAN] Running 'pacman -S quickshell'",
            '[ALPM] transaction started',
            '[ALPM] transaction completed',
        ]))


if __name__ == '__main__':
    unittest.main()
